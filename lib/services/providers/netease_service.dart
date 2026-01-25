import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';

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
      onStatusUpdate?.call("Searching lyrics on Netease...");
      final keyword = "$title - $artist";
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
        'limit': '30',
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
        print('Netease search failed: ${searchResponse.statusCode}');
        return LyricsResult.empty();
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['code'] != 200) {
        print('Netease search returned code: ${searchData['code']}');
        return LyricsResult.empty();
      }

      final result = searchData['result'];
      if (result == null ||
          (result['songs'] == null && result['songCount'] == 0)) {
        print('Netease search returned no results');
        return LyricsResult.empty();
      }

      final songs = result['songs'] as List? ?? [];
      if (songs.isEmpty) {
        print('Netease search returned empty songs list');
        return LyricsResult.empty();
      }

      // Find the best match based on duration
      dynamic bestMatch = songs[0];
      double minDiff = 1000000;

      for (var song in songs) {
        final songDurationMs = song['duration'] ?? song['dt'];
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

      final artworkUrl =
          bestMatch['al']?['picUrl'] ?? bestMatch['album']?['picUrl'];

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

      final lyricResponse = await http
          .get(lyricUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
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

      if ((lrc != null && lrc.isNotEmpty) || artworkUrl != null) {
        onStatusUpdate?.call("Processing lyrics...");
        final parseResult = lrc != null 
          ? LrcParser.parse(lrc, trimMetadata: trimMetadata) 
          : LrcParseResult(lyrics: [], trimmedMetadata: {});
        debugPrint('Netease trimmed metadata: ${parseResult.trimmedMetadata}');
        return LyricsResult(
          lyrics: parseResult.lyrics,
          source: 'Netease Music',
          contributor: contributor,
          artworkUrl: artworkUrl,
          writtenBy: parseResult.trimmedMetadata['作词'],
        );
      } else {
        print('Netease returned no lyrics or artwork for songId: $songId');
      }
    } catch (e) {
      print('Error fetching lyrics from Netease: $e');
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
