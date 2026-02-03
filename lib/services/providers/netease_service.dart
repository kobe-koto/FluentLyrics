import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/string_similarity.dart';

class NeteaseService {
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
    bool trimMetadata = false,
  }) async {
    try {
      onStatusUpdate?.call('Searching lyrics on Netease...');
      final keyword = '$title - $artist';
      const eapiSearchUrl =
          'https://interface.music.163.com/eapi/cloudsearch/pc';

      final now = DateTime.now().toUtc();
      final buildver = (now.millisecondsSinceEpoch ~/ 1000).toString();
      final requestId =
          '${now.millisecondsSinceEpoch}_${Random().nextInt(1000).toString().padLeft(4, '0')}';

      final eapiHeader = {
        '__csrf': '',
        'appver': '8.0.0',
        'buildver': buildver,
        'channel': '',
        'deviceId': '',
        'mobilename': '',
        'resolution': '1920x1080',
        'os': 'android',
        'osver': '',
        'requestId': requestId,
        'versioncode': '140',
        'MUSIC_U': '',
      };

      final eapiData = {
        's': keyword,
        'type': '1', // Single song
        'limit': '20',
        'offset': '0',
        'total': 'true',
        'header': jsonEncode(eapiHeader),
      };

      final encrypted = _NeteaseEapiHelper.encrypt(eapiSearchUrl, eapiData);
      final headers = _NeteaseEapiHelper.buildHeaders(eapiHeader);

      final searchResponse = await http
          .post(Uri.parse(eapiSearchUrl), headers: headers, body: encrypted)
          .timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint('Netease search failed: ${searchResponse.statusCode}');
        return LyricsResult.empty();
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['code'] != 200) {
        debugPrint(
          'Netease search returned unexpected code: ${searchData['code']}',
        );
        return LyricsResult.empty();
      }

      final result = searchData['result'];
      if (result == null ||
          (result['songs'] == null && result['songCount'] == 0)) {
        // Netease search returned no results
        return LyricsResult.empty();
      }

      final songs = result['songs'] as List? ?? [];
      if (songs.isEmpty) {
        // Netease search returned empty songs list
        return LyricsResult.empty();
      }

      // Filter songs based on title similarity using Jaro-Winkler algorithm
      final filteredSongs = songs.where((song) {
        final songName = song['name'] as String?;
        if (songName == null) return false;

        final similarity = StringSimilarity.getJaroWinklerScore(
          title.toLowerCase(),
          songName.toLowerCase(),
        );

        // Threshold can be adjusted. 0.8 is a reasonable starting point.
        return similarity >= 0.7;
      }).toList();

      if (filteredSongs.isEmpty) {
        debugPrint(
          'Netease search returned songs but none matched the title similarity threshold.',
        );
        return LyricsResult.empty();
      }

      // Find the best match based on duration
      dynamic bestMatch = filteredSongs[0];
      double minDiff = 1000000;

      for (var song in filteredSongs) {
        final songDurationMs = song['duration'] ?? song['dt'];
        if (songDurationMs != null) {
          final diff = (songDurationMs / 1000 - durationSeconds)
              .abs()
              .toDouble();
          if (diff < 1) {
            // if the duration diff < 1s, we use the first result
            bestMatch = song;
            // set the minDiff to 0 to skip the duration check
            minDiff = 0;
            break;
          } else if (diff < minDiff) {
            minDiff = diff;
            bestMatch = song;
          }
        }
      }

      final artworkUrl =
          bestMatch['al']?['picUrl'] ?? bestMatch['album']?['picUrl'];

      // If the best match duration is too different, it might not be the same song
      // (Netease duration is in ms)
      if (minDiff > 10 && durationSeconds > 0 && minDiff != 1000000) {
        debugPrint('Netease best match duration diff too large: ${minDiff}s');
      }

      final songId = bestMatch['id'].toString();
      onStatusUpdate?.call('Fetching lyrics from Netease...');

      final lyricUri = Uri.parse(_lyricUrl).replace(
        queryParameters: {
          'id': songId,
          'lv': '1', // native lyrics
          'kv': '1',
          'tv': '-1', // translated lyrics
          'rv': '-1', // transliteration lyrics
          'yv': '-1', // word lyrics
          'ytv': '-1', // word lyrics
          'yrv': '-1', // word lyrics
          'csrf_token': '',
        },
      );

      final lyricResponse = await http
          .get(lyricUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (lyricResponse.statusCode != 200) {
        debugPrint('Netease lyric fetch failed: ${lyricResponse.statusCode}');
        return LyricsResult.empty();
      }

      final lyricData = jsonDecode(lyricResponse.body);
      final String? lrc = lyricData['lrc']?['lyric'];
      final String? yrc = lyricData['yrc']?['lyric'];
      final bool isPureMusic = lyricData['pureMusic'] == true;

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

      if ((lrc != null && lrc.isNotEmpty) ||
          (yrc != null && yrc.isNotEmpty) ||
          artworkUrl != null ||
          isPureMusic) {
        onStatusUpdate?.call('Processing lyrics...');

        List<Lyric> lyrics = [];
        Map<String, String> trimmedMetadata = {};

        if (yrc != null && yrc.isNotEmpty) {
          lyrics = NeteaseYrcParser.parse(yrc);
          if (trimMetadata) {
            final trimResult = LrcParser.trimMetadataLines(lyrics);
            lyrics = trimResult.lyrics;
            trimmedMetadata = trimResult.trimmedMetadata;
          }
        }

        if (lyrics.isEmpty && lrc != null && lrc.isNotEmpty) {
          final parseResult = LrcParser.parse(lrc, trimMetadata: trimMetadata);
          lyrics = parseResult.lyrics;
          trimmedMetadata = parseResult.trimmedMetadata;
        }

        return LyricsResult(
          lyrics: lyrics,
          source: 'Netease Music',
          contributor: contributor,
          artworkUrl: artworkUrl,
          writtenBy: trimmedMetadata['作词'] ?? trimmedMetadata['作詞'],
          composer: trimmedMetadata['作曲'],
          isPureMusic: isPureMusic,
        );
      } else {
        debugPrint('Netease returned no lyrics or artwork for songId: $songId');
      }
    } catch (e) {
      debugPrint('Error fetching lyrics from Netease: $e');
    }
    return LyricsResult.empty();
  }
}

class _NeteaseEapiHelper {
  static const String _eapiKey = 'e82ckenh8dichen8';
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 9; PCT-AL10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.64 HuaweiBrowser/10.0.3.311 Mobile Safari/537.36';

  static Map<String, String> buildHeaders(Map<String, String> cookieData) {
    final cookie = cookieData.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    return {
      'User-Agent': _userAgent,
      'Referer': 'https://music.163.com/',
      'Cookie': cookie,
    };
  }

  static Map<String, String> encrypt(String url, Map<String, dynamic> data) {
    final path = url
        .replaceAll('https://interface3.music.163.com/e', '/')
        .replaceAll('https://interface.music.163.com/e', '/');

    final text = jsonEncode(data);
    final message = 'nobody${path}use${text}md5forencrypt';
    final digest = md5.convert(utf8.encode(message)).toString();

    final payload = '$path-36cd479b6b5-$text-36cd479b6b5-$digest';

    final key = encrypt_pkg.Key.fromUtf8(_eapiKey);
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.ecb, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(payload);

    return {
      'params': encrypted.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(),
    };
  }
}
