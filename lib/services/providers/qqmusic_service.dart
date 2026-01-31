import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/string_similarity.dart';

class QQMusicService {
  static const Map<String, String> _headers = {
    'Referer': 'https://c.y.qq.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  };

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool trimMetadata = false,
  }) async {
    try {
      onStatusUpdate?.call('Searching lyrics on QQ Music...');

      final keyword = '$title - $artist';

      // 1. Search for the song
      final searchUrl = Uri.parse('https://u.y.qq.com/cgi-bin/musicu.fcg');
      final searchBody = {
        'req_1': {
          'method': 'DoSearchForQQMusicDesktop',
          'module': 'music.search.SearchCgiService',
          'param': {
            'num_per_page': 20,
            'page_num': 1,
            'query': keyword,
            'search_type': 0, // 0 for song
          },
        },
      };

      final searchResponse = await http
          .post(searchUrl, headers: _headers, body: jsonEncode(searchBody))
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint('QQMusic search failed: ${searchResponse.statusCode}');
        return LyricsResult.empty();
      }

      // use utf8.decode because there's a bug in the http response header
      // which Content-Type header ends with a trailing semicolon
      // which does not follow RFC 7231
      // which triggers MediaType.parse to fail
      final searchData = jsonDecode(utf8.decode(searchResponse.bodyBytes));
      final req1 = searchData['req_1'];
      if (req1['code'] != 0) {
        debugPrint('QQMusic search API error: ${req1['code']}');
        return LyricsResult.empty();
      }

      final songList = req1['data']['body']['song']['list'] as List? ?? [];
      if (songList.isEmpty) {
        debugPrint('QQMusic search returned no songs');
        return LyricsResult.empty();
      }

      // 2. Filter songs
      final filteredSongs = songList.where((song) {
        final songName = song['name'] as String?;
        if (songName == null) return false;

        final similarity = StringSimilarity.getJaroWinklerScore(
          title.toLowerCase(),
          songName.toLowerCase(),
        );

        return similarity >= 0.7;
      }).toList();

      if (filteredSongs.isEmpty) {
        debugPrint(
          'QQMusic search returned songs but none matched the title similarity threshold.',
        );
        return LyricsResult.empty();
      }

      // Find the best match based on duration
      dynamic bestMatch = filteredSongs[0];
      double minDiff = 1000000;

      for (var song in filteredSongs) {
        final songDuration = song['interval']; // Duration in seconds
        if (songDuration != null && songDuration is int) {
          final diff = (songDuration - durationSeconds).abs().toDouble();
          if (diff < 1) {
            bestMatch = song;
            minDiff = 0;
            break;
          } else if (diff < minDiff) {
            minDiff = diff;
            bestMatch = song;
          }
        }
      }

      if (minDiff > 10 && durationSeconds > 0 && minDiff != 1000000) {
        debugPrint('QQMusic best match duration diff too large: ${minDiff}s');
      }

      // 3. Fetch Lyrics
      final songMid = bestMatch['mid'] as String;
      // Extract album mid for artwork if available
      final albumMid = bestMatch['album']?['mid'] as String?;
      String? artworkUrl;
      if (albumMid != null && albumMid.isNotEmpty) {
        artworkUrl =
            'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
      }

      onStatusUpdate?.call('Fetching lyrics from QQ Music...');

      final lyricsResponse = await _getLyrics(songMid);
      if (lyricsResponse == null) {
        debugPrint('QQMusic lyrics response for best match is null');
        return LyricsResult.empty();
      }

      String? lrc = lyricsResponse['lyric'];
      String? trans = lyricsResponse['trans'];

      if (lrc != null && lrc.isNotEmpty) {
        lrc = utf8.decode(base64.decode(lrc));
      }
      if (trans != null && trans.isNotEmpty) {
        try {
          trans = utf8.decode(base64.decode(trans));
        } catch (e) {
          // Sometimes trans might be empty or invalid
          trans = null;
        }
      }

      if (lrc != null && lrc.isNotEmpty) {
        onStatusUpdate?.call('Processing lyrics...');

        final parseResult = LrcParser.parse(lrc, trimMetadata: trimMetadata);

        return LyricsResult(
          lyrics: parseResult.lyrics,
          source: 'QQ Music',
          artworkUrl: artworkUrl,
          writtenBy:
              parseResult.trimmedMetadata['作词'] ??
              parseResult.trimmedMetadata['作詞'],
          isPureMusic: false,
          metadata: {
            ...parseResult.lrcMetadata,
            ...parseResult.trimmedMetadata,
          },
        );
      }

      return LyricsResult.empty();
    } catch (e, s) {
      debugPrint('Error fetching lyrics from QQ Music: $e');
      debugPrint('Stack trace: $s');
      return LyricsResult.empty();
    }
  }

  Future<Map<String, dynamic>?> _getLyrics(String songMid) async {
    try {
      final uri = Uri.parse(
        'https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      );
      final headers = Map<String, String>.from(_headers);
      headers['Referer'] = 'https://c.y.qq.com/';

      final body = {
        'songmid': songMid,
        'g_tk': '5381',
        'format': 'json', // Try json first instead of jsonp
        'inCharset': 'utf8',
        'outCharset': 'utf8',
        'notice': '0',
        'platform': 'yqq',
        'needNewCode': '0',
      };

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // If format=json works, great.
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // If it returns JSONP even with format=json, stripping is needed.
          // Or if format=json is ignored.
          String body = response.body;
          if (body.startsWith('MusicJsonCallback_lrc(')) {
            body = body.substring(
              'MusicJsonCallback_lrc('.length,
              body.length - 1,
            );
            return jsonDecode(body);
          }
        }
      }
    } catch (e) {
      debugPrint('QQMusic _getLyrics error: $e');
    }
    return null;
  }
}
