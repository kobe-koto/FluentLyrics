import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';

class NeteaseService {
  static const String _searchUrl = 'https://music.163.com/api/search/get/web';
  static const String _lyricUrl = 'https://music.163.com/api/song/lyric';
  static const Map<String, String> _headers = {
    'Referer': 'https://music.163.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  };

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call("Searching lyrics on Netease...");
      final keyword = "$title $artist";
      final searchUri = Uri.parse(_searchUrl).replace(
        queryParameters: {
          's': keyword,
          'type': '1', // Single song
          'offset': '0',
          'total': 'true',
          'limit': '10',
        },
      );

      final searchResponse = await http.get(searchUri, headers: _headers);
      if (searchResponse.statusCode != 200) {
        print('Netease search failed: ${searchResponse.statusCode}');
        return LyricsResult.empty();
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['code'] != 200) {
        print('Netease search returned code: ${searchData['code']}');
        return LyricsResult.empty();
      }

      final result = searchData['result'];
      if (result == null || result['songs'] == null) {
        print('Netease search returned no results');
        return LyricsResult.empty();
      }

      final songs = result['songs'] as List;
      if (songs.isEmpty) {
        print('Netease search returned empty songs list');
        return LyricsResult.empty();
      }

      // Find the best match based on duration
      dynamic bestMatch = songs[0];
      double minDiff = 1000000;

      for (var song in songs) {
        final songDurationMs = song['duration'];
        if (songDurationMs != null) {
          final diff = (songDurationMs / 1000 - durationSeconds)
              .abs()
              .toDouble();
          if (diff < minDiff) {
            minDiff = diff;
            bestMatch = song;
          }
        }
      }

      // If the best match duration is too different, it might not be the same song
      // (Netease duration is in ms)
      if (minDiff > 10 && durationSeconds > 0) {
        print('Netease best match duration diff too large: ${minDiff}s');
      }

      final songId = bestMatch['id'].toString();
      onStatusUpdate?.call("Fetching lyrics from Netease...");

      final lyricUri = Uri.parse(_lyricUrl).replace(
        queryParameters: {'id': songId, 'lv': '1', 'kv': '1', 'tv': '-1'},
      );

      final lyricResponse = await http.get(lyricUri, headers: _headers);
      if (lyricResponse.statusCode != 200) {
        print('Netease lyric fetch failed: ${lyricResponse.statusCode}');
        return LyricsResult.empty();
      }

      final lyricData = jsonDecode(lyricResponse.body);
      final String? lrc = lyricData['lrc']?['lyric'];

      String? contributor;
      final lyricUser = lyricData['lyricUser'];
      if (lyricUser != null && lyricUser['nickname'] != null) {
        contributor = lyricUser['nickname'];
      }

      final transUser = lyricData['transUser'];
      if (transUser != null && transUser['nickname'] != null) {
        if (contributor != null) {
          contributor += " & ${transUser['nickname']}";
        } else {
          contributor = transUser['nickname'];
        }
      }

      if (lrc != null && lrc.isNotEmpty) {
        onStatusUpdate?.call("Processing lyrics...");
        return LyricsResult(
          lyrics: LrcParser.parse(lrc),
          source: 'Netease Music',
          contributor: contributor,
        );
      } else {
        print('Netease returned no lyrics for songId: $songId');
      }
    } catch (e) {
      print('Error fetching lyrics from Netease: $e');
    }
    return LyricsResult.empty();
  }
}
