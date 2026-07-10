import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/translation_helper.dart';
import '../../utils/song_result_helper.dart';
import '../../utils/app_logger.dart';

class NeteaseService {
  static const int lyricEmptyRetryCount = 3;
  bool checkTranslationSupport(String language) {
    return language == 'zh_CN';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool trimMetadata = false,
    int translationBias = 0,
    Function(String)? onArtworkUrl,
    Function(LyricsResult)? onTranslation,
  }) async {
    try {
      onStatusUpdate?.call('[NeteaseMusic] Searching songs...');
      final matchingSongs = await _searchSongs(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
      );

      if (matchingSongs.isEmpty) {
        return LyricsResult.empty();
      }

      final maxRetryCount = min(lyricEmptyRetryCount, matchingSongs.length);

      for (int i = 0; i < maxRetryCount; i++) {
        final songId = matchingSongs[i].data['id'].toString();
        final artworkUrl =
            matchingSongs[i].data['al']?['picUrl'] ??
            matchingSongs[i].data['album']?['picUrl'];

        if (artworkUrl != null) {
          onArtworkUrl?.call(artworkUrl);
        }

        onStatusUpdate?.call('[NeteaseMusic] Fetching lyrics...');
        final lyricData = await _getLyrics(
          songId,
          trimMetadata,
          translationBias,
          onTranslation,
          title,
          artist,
        );

        if (lyricData == null) {
          onStatusUpdate?.call(
            '[NeteaseMusic] No lyrics found for songId $songId, trying next song (${i + 1}/$maxRetryCount)...',
          );
          AppLogger.debug(
            '[NeteaseMusic] No lyrics found for songId $songId, trying next song (${i + 1}/$maxRetryCount)...',
          );
          continue;
        }

        return lyricData;
      }
    } catch (e) {
      AppLogger.debug('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return LyricsResult.empty();
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data, {
    int translationBias = 0,
  }) async {
    try {
      LyricsResult? translationResult;
      await fetchLyrics(
        title: data.title,
        artist: data.artist,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
        onTranslation: (trans) {
          translationResult = trans;
        },
      );

      return translationResult ?? LyricsResult.empty();
    } catch (e) {
      AppLogger.debug('[NeteaseMusic] Error fetching translation: $e');
    }
    return LyricsResult.empty();
  }

  static const Map<String, String> _headers = {
    'Referer': 'https://music.163.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  };

  Future<List<ProcessedSong>> _searchSongs({
    required String title,
    required List<String> artist,
    int durationSeconds = 0,
  }) async {
    try {
      final keywordList = ['$title - ${artist.join(', ')}', title];
      for (var keyword in keywordList) {
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
          AppLogger.debug(
            '[NeteaseMusic] Search failed: ${searchResponse.statusCode}',
          );
          continue;
        }

        final searchData = jsonDecode(searchResponse.body);
        if (searchData['code'] != 200) {
          AppLogger.debug(
            '[NeteaseMusic] Search returned unexpected code: ${searchData['code']}',
          );
          continue;
        }

        final result = searchData['result'];
        if (result == null ||
            (result['songs'] == null && result['songCount'] == 0)) {
          continue;
        }

        final songs = result['songs'] as List? ?? [];
        if (songs.isEmpty) {
          continue;
        }

        // convert songs to GenericSongs
        List<GenericSong> genericSongs = [];
        for (var song in songs) {
          final songName = song['name'] as String?;
          if (songName == null) continue;

          final artistNames = (song['ar'] as List? ?? [])
              .map((ar) => (ar as Map?)?['name']?.toString() ?? '')
              .toList();

          final durationMs = song['dt'] as int? ?? 0;

          genericSongs.add(
            GenericSong(
              title: songName,
              artist: artistNames,
              data: song,
              durationMs: durationMs,
            ),
          );
        }

        final processedSongs = SongResultHelper.orderBySimilarity(
          genericSongs,
          title,
          artist,
          durationSeconds * 1000,
          5000,
        );

        if (processedSongs.isEmpty) {
          AppLogger.debug(
            '[NeteaseMusic] search returned songs but none matched the similarity threshold or length differ too large',
          );
          continue;
        }

        return processedSongs;
      }
      return [];
    } catch (e) {
      AppLogger.debug('[NeteaseMusic] Error searching song: $e');
      return [];
    }
  }

  Future<LyricsResult?> _getLyrics(
    String songId,
    bool trimMetadata,
    int translationBias,
    Function(LyricsResult)? onTranslation,
    String title,
    List<String> artist,
  ) async {
    try {
      final lyricUri = Uri.parse('https://music.163.com/api/song/lyric')
          .replace(
            queryParameters: {
              'id': songId,
              'lv': '1',
              'kv': '1',
              'tv': '-1',
              'rv': '-1',
              'yv': '-1',
              'ytv': '-1',
              'yrv': '-1',
              'csrf_token': '',
            },
          );

      final lyricResponse = await http
          .get(lyricUri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (lyricResponse.statusCode != 200) {
        return null;
      }

      final lyricData = jsonDecode(lyricResponse.body);

      final String? syncedLRC = lyricData['lrc']?['lyric'];
      final String? syncedTransLRC = lyricData['tlyric']?['lyric'];
      final String? richSyncedYRC = lyricData['yrc']?['lyric'];
      final String? richSyncedTransLRC = lyricData['ytlrc']?['lyric'];
      final bool isPureMusic = lyricData['pureMusic'] == true;

      final String? lyricContributor = lyricData['lyricUser']?['nickname'];
      final String? translationContributor =
          lyricData['transUser']?['nickname'];

      if ((syncedLRC != null && syncedLRC.isNotEmpty) ||
          (richSyncedYRC != null && richSyncedYRC.isNotEmpty) ||
          (syncedTransLRC != null && syncedTransLRC.isNotEmpty) ||
          isPureMusic) {
        List<Lyric> richLyrics = [];
        List<Lyric> lyrics = [];
        Map<String, String> trimmedMetadata = {};

        if (richSyncedYRC != null && richSyncedYRC.isNotEmpty) {
          richLyrics = _NeteaseYrcParser.parse(richSyncedYRC);
          if (trimMetadata) {
            final trimResult = LrcParser.trimMetadataLines(
              richLyrics,
              lrcMetadata: {'title': title, 'artist': artist.join(', ')},
            );
            richLyrics = trimResult.lyrics;
            trimmedMetadata = trimResult.trimmedMetadata;
          }
        }

        if (syncedLRC != null && syncedLRC.isNotEmpty) {
          final parseResult = LrcParser.parse(
            syncedLRC,
            trimMetadata: trimMetadata,
          );
          lyrics = parseResult.lyrics;
          trimmedMetadata = parseResult.trimmedMetadata;
        }

        if (syncedTransLRC != null && syncedTransLRC.isNotEmpty) {
          final List<Lyric> richSyncedTransLRCParse =
              (richSyncedTransLRC != null && richSyncedTransLRC.isNotEmpty)
              ? LrcParser.parse(richSyncedTransLRC).lyrics
              : [];
          final List<Lyric> transParse = richSyncedTransLRCParse.isNotEmpty
              ? richSyncedTransLRCParse
              : LrcParser.parse(syncedTransLRC).lyrics;
          final List<Lyric> pairSourceLyrics = richLyrics.isNotEmpty
              ? richLyrics
              : lyrics;

          if (transParse.isNotEmpty && pairSourceLyrics.isNotEmpty) {
            final rawTranslation = TranslationHelper.pair(
              originalLyrics: pairSourceLyrics,
              translatedLyrics: transParse,
              translationBias: translationBias,
            );

            onTranslation?.call(
              LyricsResult(
                lyrics: [],
                rawTranslation: rawTranslation,
                source: 'Netease Music',
                isSynced: true,
                language: 'zh_CN',
                translation: true,
                translationProvider: 'Netease Music',
                translationContributor: translationContributor,
              ),
            );
          }
        }

        return LyricsResult(
          lyrics: richLyrics.isNotEmpty ? richLyrics : lyrics,
          source: 'Netease Music',
          isPureMusic: isPureMusic,
          contributor: lyricContributor,
          metadata: trimmedMetadata,
        );
      }
    } catch (e) {
      AppLogger.debug('[NeteaseMusic] Error fetching lyrics: $e');
    }
    return null;
  }
}

class _NeteaseYrcParser {
  static List<Lyric> parse(String yrcContent) {
    final List<Lyric> lyrics = [];
    // Pattern for line: [lineStartTime,lineDuration](wordStartTime,wordDuration,0)Word...
    final lineRegex = RegExp(r'\[(\d+),(\d+)\](.*)');
    final wordRegex = RegExp(r'\((\d+),(\d+),\d+\)([^\(\[]*)');

    final lines = yrcContent.split('\n');
    for (var lineStr in lines) {
      final lineMatch = lineRegex.firstMatch(lineStr);
      if (lineMatch != null) {
        final int lineStart = int.parse(lineMatch.group(1)!);
        final int lineDuration = int.parse(lineMatch.group(2)!);
        final String wordsContent = lineMatch.group(3)!;

        final List<LyricInlinePart> inlineParts = [];
        final Iterable<Match> wordMatches = wordRegex.allMatches(wordsContent);

        String fullText = '';
        for (final wordMatch in wordMatches) {
          final int wordStart = int.parse(wordMatch.group(1)!);
          final int wordDuration = int.parse(wordMatch.group(2)!);
          final String wordText = wordMatch.group(3)!;

          fullText += wordText;
          inlineParts.add(
            LyricInlinePart(
              startTime: Duration(milliseconds: wordStart),
              endTime: Duration(milliseconds: wordStart + wordDuration),
              text: wordText,
            ),
          );
        }

        // If no word matches were found, it might be a metadata line or empty line
        if (inlineParts.isEmpty) {
          // Check if it's metadata like [0,730](0,730,0) 作词 : ...
          // The wordRegex should have caught it if it follows the pattern.
          // In the example: [0,730](0,730,0) 作词 : Ryosuke \"Dr. R\" Sakai/milet
          // wordStart=0, wordDuration=730, wordText=" 作词 : Ryosuke \"Dr. R\" Sakai/milet"
          // So it should be caught.
        }

        lyrics.add(
          Lyric(
            startTime: Duration(milliseconds: lineStart),
            endTime: Duration(milliseconds: lineStart + lineDuration),
            text: fullText.isEmpty ? wordsContent : fullText,
            inlineParts: inlineParts.isNotEmpty ? inlineParts : null,
          ),
        );
      }
    }

    return lyrics;
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
