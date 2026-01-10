import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyric_model.dart';
import '../utils/lrc_parser.dart';

class LyricsService {
  static const String _baseCachedUrl = 'https://lrclib.net/api/get-cached';
  static const String _baseRawUrl = 'https://lrclib.net/api/get';

  Future<List<Lyric>> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    required bool cached,
  }) async {
    try {
      final queryParams = {
        'artist_name': artist,
        'track_name': title,
        'album_name': album,
        'duration': durationSeconds.toString(),
      };

      final uri = Uri.parse(
        cached ? _baseCachedUrl : _baseRawUrl,
      ).replace(queryParameters: queryParams);

      print("fetching lyrics for $title by $artist (cached: $cached)");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String? syncedLyrics = data['syncedLyrics'];
        final String? plainLyrics = data['plainLyrics'];

        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          return LrcParser.parse(syncedLyrics);
        } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
          // Fallback to plain lyrics as a single line or split by newline
          return plainLyrics
              .split('\n')
              .map((line) => Lyric(startTime: Duration.zero, text: line.trim()))
              .toList();
        }
      } else if (response.statusCode == 404 && cached) {
        print('no cached lyrics found, trying raw URL');
        return fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          cached: false,
        );
      } else {
        throw Exception(
          'status code: ${response.statusCode}, URL: ${uri.toString()}, body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching lyrics: $e');
    }
    return [];
  }
}
