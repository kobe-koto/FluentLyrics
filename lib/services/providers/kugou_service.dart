import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';

import '../../models/lyric_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/krc_parser.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/string_similarity.dart';
import '../lyrics_request_scope.dart';

class KugouService {
  static const _songSearchUrl =
      'https://mobileservice.kugou.com/api/v3/search/song';
  static const _lyricsSearchUrl = 'https://lyrics.kugou.com/search';
  static const _lyricsDownloadUrl = 'https://lyrics.kugou.com/download';

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(String)? onArtworkUrl,
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      onStatusUpdate?.call('[Kugou] Searching songs...');

      final song = await _findSong(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
        scope: scope,
      );
      if (song == null) return LyricsResult.empty();

      final candidates = await _findLyricCandidates(
        song,
        title,
        artist,
        durationSeconds,
        scope,
      );
      for (final candidate in candidates) {
        if (scope?.isCancelled == true) return LyricsResult.empty();
        onStatusUpdate?.call('[Kugou] Downloading lyrics...');

        final result = await _downloadCandidate(candidate, scope);
        if (result.lyrics.isNotEmpty) return result;
      }
      return LyricsResult.empty();
    } catch (error) {
      AppLogger.debug('[Kugou] Error fetching lyrics: $error');
      return failureUnlessCancelled(error, scope: scope, source: 'Kugou Music');
    }
  }

  Future<Map<String, dynamic>?> _findSong({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    required LyricsRequestScope? scope,
  }) async {
    final uri = Uri.parse(_songSearchUrl).replace(
      queryParameters: {
        'version': '9108',
        'plat': '0',
        'pagesize': '8',
        'showtype': '0',
        'keyword': '$title ${artist.join(' ')}',
      },
    );
    final response = await scopedGet(
      uri,
      scope: scope,
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final info = data is Map
        ? (data['data'] is Map ? (data['data'] as Map)['info'] : null)
        : null;
    if (info is! List) return null;

    Map<String, dynamic>? best;
    var bestScore = 0.0;
    for (final item in info) {
      if (item is! Map) continue;
      final songTitle = item['songname']?.toString() ?? '';
      final songArtist = item['singername']?.toString() ?? '';
      final duration = int.tryParse(item['duration']?.toString() ?? '') ?? 0;
      if (durationSeconds > 0 &&
          duration > 0 &&
          (duration - durationSeconds).abs() > 12) {
        continue;
      }
      final titleScore = JaroWinklerSimilarity.getJaroWinklerScore(
        title.toLowerCase(),
        songTitle.toLowerCase(),
      );
      final artistScore = JaroWinklerSimilarity.getJaroWinklerScore(
        artist.join(', ').toLowerCase(),
        songArtist.toLowerCase(),
      );
      final score = titleScore * 0.6 + artistScore * 0.4;
      if (titleScore >= 0.7 && artistScore >= 0.5 && score > bestScore) {
        best = Map<String, dynamic>.from(item);
        bestScore = score;
      }
    }
    return best;
  }

  Future<List<Map<String, dynamic>>> _findLyricCandidates(
    Map<String, dynamic> song,
    String title,
    List<String> artist,
    int durationSeconds,
    LyricsRequestScope? scope,
  ) async {
    final queries = <Map<String, String>>[
      {'hash': song['hash']?.toString() ?? ''},
      {
        'keyword': '$title ${artist.join(' ')}',
        if (durationSeconds > 0) 'duration': '${durationSeconds * 1000}',
      },
    ];

    for (final query in queries) {
      query.addAll({'ver': '1', 'man': 'yes', 'client': 'pc'});
      final uri = Uri.parse(_lyricsSearchUrl).replace(queryParameters: query);
      final response = await scopedGet(
        uri,
        scope: scope,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) continue;
      final data = jsonDecode(response.body);
      final candidates = data is Map ? data['candidates'] : null;
      if (candidates is List) {
        final parsed = candidates
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .where(
              (candidate) =>
                  _candidateMatches(candidate, title, artist, durationSeconds),
            )
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return const [];
  }

  bool _candidateMatches(
    Map<String, dynamic> candidate,
    String title,
    List<String> artist,
    int durationSeconds,
  ) {
    final candidateTitle = candidate['song']?.toString() ?? '';
    final candidateArtist = candidate['singer']?.toString() ?? '';
    final candidateDuration =
        int.tryParse(candidate['duration']?.toString() ?? '') ?? 0;
    return JaroWinklerSimilarity.getJaroWinklerScore(
              title.toLowerCase(),
              candidateTitle.toLowerCase(),
            ) >=
            0.7 &&
        JaroWinklerSimilarity.getJaroWinklerScore(
              artist.join(', ').toLowerCase(),
              candidateArtist.toLowerCase(),
            ) >=
            0.5 &&
        (durationSeconds <= 0 ||
            candidateDuration <= 0 ||
            ((candidateDuration / 1000).round() - durationSeconds).abs() <= 12);
  }

  Future<LyricsResult> _downloadCandidate(
    Map<String, dynamic> candidate,
    LyricsRequestScope? scope,
  ) async {
    for (final format in ['krc', 'lrc']) {
      final uri = Uri.parse(_lyricsDownloadUrl).replace(
        queryParameters: {
          'ver': '1',
          'client': 'pc',
          'charset': 'utf8',
          'fmt': format,
          'id': candidate['id']?.toString() ?? '',
          'accesskey': candidate['accesskey']?.toString() ?? '',
        },
      );
      final response = await scopedGet(
        uri,
        scope: scope,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) continue;
      final data = jsonDecode(response.body);
      final encoded = data is Map ? data['content']?.toString() : null;
      if (encoded == null || encoded.isEmpty) continue;

      final lyrics = format == 'krc'
          ? KrcParser.parse(encoded)
          : _parseLrc(encoded);
      if (lyrics.isNotEmpty) {
        return LyricsResult(
          lyrics: lyrics,
          source: 'Kugou Music',
          isSynced: true,
          isRichSync: lyrics.any(
            (line) => line.inlineParts?.isNotEmpty ?? false,
          ),
        );
      }
    }
    return LyricsResult.empty();
  }

  List<Lyric> _parseLrc(String encoded) {
    try {
      final content = utf8.decode(base64.decode(encoded));
      final unescaped = HtmlUnescape().convert(content);
      return LrcParser.parse(unescaped).lyrics;
    } catch (error) {
      AppLogger.debug('[Kugou] Error parsing LRC: $error');
      return [];
    }
  }
}
