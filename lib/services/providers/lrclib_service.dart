import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';

class LrclibService {
  static const String _baseSearchUrl = 'https://lrclib.net/api/search';

  Future<List<Lyric>> fetchLyrics({
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

      onStatusUpdate?.call("Searching lyrics on LRCLIB...");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        if (results.isEmpty) {
          return [];
        }

        // Use the first result
        final data = results.first;

        final String? syncedLyrics = data['syncedLyrics'];
        final String? plainLyrics = data['plainLyrics'];

        onStatusUpdate?.call("Processing lyrics...");
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          return LrcParser.parse(syncedLyrics);
        } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
          return plainLyrics
              .split('\n')
              .map((line) => Lyric(startTime: Duration.zero, text: line.trim()))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching lyrics from LRCLIB: $e');
    }
    return [];
  }
}
