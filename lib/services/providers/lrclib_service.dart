import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';

class LrclibService {
  static const String _baseSearchUrl = 'https://lrclib.net/api/search';

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      final queryParams = {
        'artist_name': artist,
        'track_name': title,
        'album_name': album,
        'duration': durationSeconds.toString(),
      };

      final uri = Uri.parse(
        _baseSearchUrl,
      ).replace(queryParameters: queryParams);

      onStatusUpdate?.call('Searching lyrics on LRCLIB...');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        if (results.isEmpty) {
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

        onStatusUpdate?.call('Processing lyrics...');
        List<Lyric> lyrics = [];

        if (enhancedLyrics != null && enhancedLyrics.isNotEmpty) {
          lyrics = EnhancedLrcParser.parse(enhancedLyrics);
        }

        if (lyrics.isEmpty && syncedLyrics != null && syncedLyrics.isNotEmpty) {
          lyrics = LrcParser.parse(syncedLyrics).lyrics;
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
            isSynced:
                (enhancedLyrics != null && enhancedLyrics.isNotEmpty) ||
                (syncedLyrics != null && syncedLyrics.isNotEmpty),
            artworkUrl: null, // lrclib doesn't provide artwork
            isPureMusic: isInstrumental,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from LRCLIB: $e');
    }
    return LyricsResult.empty();
  }
}
