import 'dart:convert';

import '../../models/lyric_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/string_similarity.dart';
import '../lyrics_request_scope.dart';

class YoutubeMusicService {
  static const _apiBase = 'https://music.youtube.com/youtubei/v1';
  static const _songsOnly = 'EgWKAQIIAWoMEA4QChADEAQQCRAF';
  static const _lyricsPageType = 'MUSIC_PAGE_TYPE_TRACK_LYRICS';
  static const _webClientName = 'WEB_REMIX';
  static const _mobileClientName = 'ANDROID_MUSIC';
  static const _mobileClientVersion = '7.21.50';

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      final language = _languageFor(title, artist);
      final webContext = _context(
        clientName: _webClientName,
        clientVersion: '1.${_dateVersion()}.01.00',
        language: language,
      );

      onStatusUpdate?.call('[YouTube Music] Searching songs...');
      final search = await _youtube(
        'search',
        _searchFieldMask,
        _request(
          context: webContext,
          query: '$title ${artist.join(' ')}',
          params: _songsOnly,
        ),
        scope,
      );
      final match = _findVideo(search, title, artist, durationSeconds);
      if (match == null) return LyricsResult.empty();

      onStatusUpdate?.call('[YouTube Music] Finding lyrics...');
      final next = await _youtube(
        'next',
        _nextFieldMask,
        _request(context: webContext, videoId: match.videoId),
        scope,
      );
      final lyricsId = _findLyricsId(next);
      if (lyricsId == null) return LyricsResult.empty();

      onStatusUpdate?.call('[YouTube Music] Fetching lyrics...');
      final page = await _youtube(
        'browse',
        _lyricsFieldMask,
        _request(
          context: _context(
            clientName: _mobileClientName,
            clientVersion: _mobileClientVersion,
            language: language,
          ),
          browseId: lyricsId,
        ),
        scope,
      );
      final rows = _findTimedRows(page);
      if (rows == null || rows.isEmpty) return LyricsResult.empty();

      final lyrics = _decodeRows(rows);
      if (lyrics.isEmpty) return LyricsResult.empty();
      return LyricsResult(
        lyrics: lyrics,
        source: 'YouTube Music',
        isSynced: lyrics.any((line) => line.startTime != Duration.zero),
      );
    } catch (error) {
      AppLogger.debug('[YouTube Music] Error fetching lyrics: $error');
      return failureUnlessCancelled(
        error,
        scope: scope,
        source: 'YouTube Music',
      );
    }
  }

  Future<Map<String, dynamic>> _youtube(
    String endpoint,
    String fieldMask,
    Map<String, dynamic> body,
    LyricsRequestScope? scope,
  ) async {
    final response = await scopedPost(
      Uri.parse('$_apiBase/$endpoint?prettyPrint=false'),
      scope: scope,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': fieldMask,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'YouTube Music $endpoint failed: HTTP ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('YouTube Music response is not an object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _request({
    required Map<String, dynamic> context,
    String? query,
    String? params,
    String? videoId,
    String? browseId,
  }) {
    final request = <String, dynamic>{'context': context};
    if (query != null) request['query'] = query;
    if (params != null) request['params'] = params;
    if (videoId != null) request['videoId'] = videoId;
    if (browseId != null) request['browseId'] = browseId;
    return request;
  }

  Map<String, dynamic> _context({
    required String clientName,
    required String clientVersion,
    required String language,
  }) => {
    'client': {
      'clientName': clientName,
      'clientVersion': clientVersion,
      'hl': language,
    },
  };

  _YoutubeMatch? _findVideo(
    Map<String, dynamic> search,
    String title,
    List<String> artist,
    int durationSeconds,
  ) {
    _YoutubeMatch? best;
    for (final item in _dig(search, [
      'contents',
      'tabbedSearchResultsRenderer',
      'tabs',
      'tabRenderer',
      'content',
      'sectionListRenderer',
      'contents',
      'musicShelfRenderer',
      'contents',
      'musicResponsiveListItemRenderer',
    ])) {
      if (item is! Map) continue;
      final columns = _dig(item, [
        'flexColumns',
        'musicResponsiveListItemFlexColumnRenderer',
      ]);
      if (columns.length < 2) continue;
      final songTitle = _joinRuns(columns.first, 'text');
      final details = _runs(columns[1], 'text');
      final videoId = _firstString(_dig(item, ['playlistItemData', 'videoId']));
      final seconds = _durationSeconds(details);
      final artists = _youtubeArtists(details);
      if (videoId == null || !_matches(title, artist, songTitle, artists)) {
        continue;
      }
      if (durationSeconds > 0 &&
          seconds > 0 &&
          (seconds - durationSeconds).abs() > 12) {
        continue;
      }
      final gap = durationSeconds > 0 && seconds > 0
          ? (seconds - durationSeconds).abs()
          : 0;
      if (best == null || gap < best.durationGap) {
        best = _YoutubeMatch(videoId, seconds, gap);
      }
    }
    return best;
  }

  String? _findLyricsId(Map<String, dynamic> next) {
    for (final tab in _dig(next, [
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
      'tabs',
      'tabRenderer',
    ])) {
      if (tab is! Map) continue;
      final pageType = _firstString(
        _dig(tab, [
          'endpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType',
        ]),
      );
      final browseId = _firstString(
        _dig(tab, ['endpoint', 'browseEndpoint', 'browseId']),
      );
      if (pageType == _lyricsPageType && browseId != null) return browseId;
    }
    return null;
  }

  List<dynamic>? _findTimedRows(Map<String, dynamic> page) {
    final values = _dig(page, [
      'contents',
      'elementRenderer',
      'newElement',
      'type',
      'componentType',
      'model',
      'timedLyricsModel',
      'lyricsData',
      'timedLyricsData',
    ]);
    if (values.isEmpty) return null;
    if (values.length == 1 && values.first is List) {
      return values.first as List<dynamic>;
    }
    return values;
  }

  List<Lyric> _decodeRows(List<dynamic> rows) {
    final plain = <Lyric>[];
    final synced = <Lyric>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final rawText = row['lyricLine']?.toString() ?? '';
      final text = _isInterludeMarker(rawText) ? '' : rawText;
      if (text.trim().isEmpty && !_isInterludeMarker(rawText)) continue;
      plain.add(Lyric(startTime: Duration.zero, text: text));
      final cue = row['cueRange'];
      if (cue is Map) {
        final start = int.tryParse(
          cue['startTimeMilliseconds']?.toString() ?? '',
        );
        final end = int.tryParse(cue['endTimeMilliseconds']?.toString() ?? '');
        if (start != null && end != null) {
          synced.add(
            Lyric(
              startTime: Duration(milliseconds: start),
              endTime: Duration(milliseconds: end),
              text: text,
            ),
          );
        }
      }
    }
    if (plain.isEmpty) return [];
    return synced.length == plain.length ? synced : plain;
  }

  bool _isInterludeMarker(String text) {
    final trimmed = text.trim();
    return trimmed.isNotEmpty && trimmed.split('').every('♪♫♩♬'.contains);
  }

  bool _matches(
    String title,
    List<String> artists,
    String resultTitle,
    List<String> resultArtists,
  ) {
    final titleScore = JaroWinklerSimilarity.getJaroWinklerScore(
      title.toLowerCase(),
      resultTitle.toLowerCase(),
    );
    final artistScore = JaroWinklerSimilarity.getJaroWinklerScore(
      artists.join(', ').toLowerCase(),
      resultArtists.join(', ').toLowerCase(),
    );
    return titleScore >= 0.7 && artistScore >= 0.5;
  }

  List<String> _youtubeArtists(List<String> details) {
    final index = details.indexOf(' • ');
    return index >= 0 ? details.sublist(0, index) : details;
  }

  int _durationSeconds(List<String> details) {
    if (details.isEmpty) return 0;
    final parts = details.last.split(':');
    if (parts.length < 2 || parts.length > 3) return 0;
    var value = 0;
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null || number < 0) return 0;
      value = value * 60 + number;
    }
    return value;
  }

  List<String> _runs(dynamic value, String key) =>
      _dig(value, [key, 'runs', 'text']).whereType<String>().toList();

  String _joinRuns(dynamic value, String key) => _runs(value, key).join();

  String? _firstString(Iterable<dynamic> values) {
    for (final value in values) {
      if (value is String) return value;
    }
    return null;
  }

  List<dynamic> _dig(dynamic value, List<String> path) {
    var values = <dynamic>[value];
    for (final key in path) {
      final next = <dynamic>[];
      for (final current in values) {
        if (current is List) {
          for (final item in current) {
            if (item is Map && item[key] != null) next.add(item[key]);
          }
        } else if (current is Map && current[key] != null) {
          final value = current[key];
          if (value is List) {
            next.addAll(value);
          } else {
            next.add(value);
          }
        }
      }
      values = next;
    }
    return values;
  }

  String _languageFor(String title, List<String> artist) {
    for (final rune in '${artist.join()}$title'.runes) {
      if ((rune >= 0xAC00 && rune <= 0xD7AF)) return 'ko';
      if ((rune >= 0x3400 && rune <= 0x9FFF) ||
          (rune >= 0x3040 && rune <= 0x30FF)) {
        return 'ja';
      }
    }
    return 'en';
  }

  String _dateVersion() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  static const _searchFieldMask =
      'contents.tabbedSearchResultsRenderer.tabs.tabRenderer.content.sectionListRenderer.contents.musicShelfRenderer.contents.musicResponsiveListItemRenderer(playlistItemData.videoId,flexColumns.musicResponsiveListItemFlexColumnRenderer.text.runs.text)';
  static const _nextFieldMask =
      'contents.singleColumnMusicWatchNextResultsRenderer.tabbedRenderer.watchNextTabbedResultsRenderer.tabs.tabRenderer(unselectable,endpoint.browseEndpoint(browseId,browseEndpointContextSupportedConfigs.browseEndpointContextMusicConfig.pageType))';
  static const _lyricsFieldMask =
      'contents.elementRenderer.newElement.type.componentType.model.timedLyricsModel.lyricsData.timedLyricsData';
}

class _YoutubeMatch {
  const _YoutubeMatch(this.videoId, this.seconds, this.durationGap);

  final String videoId;
  final int seconds;
  final int durationGap;
}
