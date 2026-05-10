import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/string_similarity.dart';

class LrclibService {
  static const String _baseSearchUrl = 'https://lrclib.net/api/search';

  LrclibService({Future<http.Response> Function(Uri uri)? httpGet})
    : _httpGet = httpGet ?? http.get;

  final Future<http.Response> Function(Uri uri) _httpGet;

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(String)? onArtworkUrl,
  }) async {
    try {
      final queryParams = {
        'artist_name': artist.join(', '),
        'track_name': title,
        'album_name': album,
        'duration': durationSeconds.toString(),
      };

      final uri = Uri.parse(
        _baseSearchUrl,
      ).replace(queryParameters: queryParams);

      onStatusUpdate?.call('[LRCLIB] Searching lyrics...');

      final response = await _httpGet(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> rawResults = jsonDecode(response.body);

        if (rawResults.isEmpty) {
          return LyricsResult.empty();
        }

        // Filter results based on title similarity using Jaro-Winkler algorithm
        final results = rawResults.where((result) {
          final trackName =
              result['trackName'] as String? ?? result['name'] as String?;
          if (trackName == null) return false;

          final similarity = JaroWinklerSimilarity.getJaroWinklerScore(
            title.toLowerCase(),
            trackName.toLowerCase(),
          );

          // Threshold can be adjusted. 0.7 is a reasonable starting point.
          return similarity >= 0.7;
        }).toList();

        if (results.isEmpty) {
          AppLogger.debug(
            '[LRCLIB] Search returned songs but none matched the title similarity threshold.',
          );
          return LyricsResult.empty();
        }

        // Look for the first result that has enhanced (rich sync), then synced, then plain
        dynamic selectedResult;

        // Try enhanced first
        for (final result in results) {
          final enhanced = result['enhancedLyrics'];
          if (enhanced != null && enhanced.toString().isNotEmpty) {
            selectedResult = result;
            break;
          }
        }

        // Fallback to synced
        if (selectedResult == null) {
          for (final result in results) {
            final synced = result['syncedLyrics'];
            if (synced != null && synced.toString().isNotEmpty) {
              selectedResult = result;
              break;
            }
          }
        }

        // Fallback to plain
        if (selectedResult == null) {
          for (final result in results) {
            final plain = result['plainLyrics'];
            if (plain != null && plain.toString().isNotEmpty) {
              selectedResult = result;
              break;
            }
          }
        }

        // Final fallback to the first result
        selectedResult ??= results.first;

        final String? enhancedLyrics = selectedResult['enhancedLyrics'];
        final String? syncedLyrics = selectedResult['syncedLyrics'];
        final String? plainLyrics = selectedResult['plainLyrics'];
        final bool isInstrumental = selectedResult['instrumental'] == true;

        onStatusUpdate?.call('[LRCLIB] Processing lyrics...');
        List<Lyric> lyrics = [];
        bool hasSyncedTiming = false;

        if (enhancedLyrics != null && enhancedLyrics.isNotEmpty) {
          lyrics = EnhancedLrcParser.parse(enhancedLyrics);
          hasSyncedTiming = lyrics.isNotEmpty;
        }

        if (lyrics.isEmpty && syncedLyrics != null && syncedLyrics.isNotEmpty) {
          lyrics = LrcParser.parse(syncedLyrics).lyrics;
          hasSyncedTiming = lyrics.isNotEmpty;
        } else if (lyrics.isEmpty &&
            plainLyrics != null &&
            plainLyrics.isNotEmpty) {
          lyrics = plainLyrics
              .split('\n')
              .map((line) => Lyric(startTime: Duration.zero, text: line.trim()))
              .toList();
        }

        if (lyrics.isNotEmpty || isInstrumental) {
          return LyricsResult(
            lyrics: lyrics,
            source: 'LRCLIB',
            isSynced: hasSyncedTiming,
            isPureMusic: isInstrumental,
          );
        }
      }
    } catch (e) {
      AppLogger.debug('[LRCLIB] Error fetching lyrics: $e');
    }
    return LyricsResult.empty();
  }
}
