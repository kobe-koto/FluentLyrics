import 'dart:convert';
import 'dart:math';

import '../lyrics_request_scope.dart';

import '../../models/general_translation_request_data.dart';
import '../../models/lyric_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/lyrics_reading_helper.dart';
import '../../utils/qqmusic_lyric_decoder.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/song_result_helper.dart';
import '../../utils/translation_helper.dart';

final Random random = Random();

class QQMusicService {
  static const int lyricEmptyRetryCount = 3;

  static const List<String> _platforms = [
    'Macintosh; Intel Mac OS X 10_15_7',
    'Windows NT 10.0; Win64; x64',
    'X11; Linux x86_64',
    'Linux x86_64',
    'X11; CrOS x86_64 14541.0.0',
    'Linux; Android 10; K',
    'iPhone; CPU iPhone OS 14_8 like Mac OS X',
    'iPad; CPU OS 14_8 like Mac OS X',
    'iPhone; CPU iPhone OS 15_8 like Mac OS X',
    'iPad; CPU OS 15_8 like Mac OS X',
    'iPhone; CPU iPhone OS 16_7 like Mac OS X',
    'iPad; CPU OS 16_7 like Mac OS X',
    'iPhone; CPU iPhone OS 17_7 like Mac OS X',
    'iPad; CPU OS 17_7 like Mac OS X',
    'iPhone; CPU iPhone OS 18_7 like Mac OS X',
    'iPad; CPU OS 18_7 like Mac OS X',
    'iPhone; CPU iPhone OS 26_7 like Mac OS X',
    'iPad; CPU OS 26_7 like Mac OS X',
  ];

  String get _userAgent =>
      'Mozilla/5.0 (${_platforms[random.nextInt(_platforms.length)]}; Nonce ${DateTime.now().millisecondsSinceEpoch.toString()}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${random.nextInt(55) + 100}.${random.nextInt(10)}.${random.nextInt(10)}.${random.nextInt(10)} Safari/537.36';

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
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      onStatusUpdate?.call('[QQMusic] Searching songs...');

      final bestMatch = await _searchSongs(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
        scope: scope,
      );

      if (bestMatch.isEmpty) {
        return LyricsResult.empty();
      }

      final maxRetryCount = min(lyricEmptyRetryCount, bestMatch.length);

      for (int i = 0; i < maxRetryCount; i++) {
        final songMid = bestMatch[i].data['mid'] as String;
        final songId = bestMatch[i].data['id']?.toString();
        final albumMid = bestMatch[i].data['album']?['mid'] as String?;
        if (albumMid != null && albumMid.isNotEmpty) {
          onArtworkUrl?.call(
            'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg',
          );
        }

        onStatusUpdate?.call('[QQMusic] Fetching lyrics...');

        final lyricsResponse = await _getLyrics(
          songId: songId,
          songMid: songMid,
          scope: scope,
        );
        if (lyricsResponse == null) {
          AppLogger.debug('[QQMusic] Lyrics response for best match is null');
          continue;
        }

        final lyric = lyricsResponse.lyric;
        final translation = lyricsResponse.trans;
        if (lyric == null || lyric.isEmpty) {
          onStatusUpdate?.call(
            '[QQMusic] No lyrics found for songMid $songMid, trying next song (${i + 1}/$maxRetryCount)...',
          );
          AppLogger.debug(
            '[QQMusic] No lyrics found for songMid $songMid, trying next song (${i + 1}/$maxRetryCount)...',
          );
          continue;
        }

        onStatusUpdate?.call('[QQMusic] Processing lyrics...');
        final parseResult = _parseLyrics(
          lyric,
          trimMetadata: trimMetadata,
          title: title,
          artist: artist.join(', '),
        );

        if (translation != null && translation.isNotEmpty) {
          final transParsedLyrics = LrcParser.parse(translation).lyrics
              .map(
                (i) => Lyric(
                  startTime: i.startTime,
                  text: i.text == '//' ? '' : i.text,
                  endTime: i.endTime,
                ),
              )
              .where(
                (i) =>
                    !(i.text.isEmpty ||
                        i.text.contains('享有本翻译作品的著作权') ||
                        i.text.contains('以下歌词翻译由文曲大模型提供')),
              )
              .toList();
          if (transParsedLyrics.isNotEmpty) {
            final rawTranslation = TranslationHelper.pair(
              originalLyrics: parseResult.lyrics,
              translatedLyrics: transParsedLyrics,
              translationBias: translationBias,
            );

            onTranslation?.call(
              LyricsResult(
                lyrics: [],
                rawTranslation: rawTranslation,
                source: 'QQ Music',
                isSynced: true,
                translation: true,
                language: 'zh_CN',
                translationProvider: 'QQ Music',
              ),
            );
          }
        }

        return LyricsResult(
          lyrics: parseResult.lyrics,
          source: 'QQ Music',
          reading: LyricsReadingHelper.fromQqPayload(
            lyric: lyricsResponse.lyric,
            roma: lyricsResponse.roma,
          ),
          writtenBy:
              parseResult.trimmedMetadata['词'] ??
              parseResult.trimmedMetadata['作词'] ??
              parseResult.trimmedMetadata['作詞'] ??
              parseResult.trimmedMetadata['Lyrics by'],
          composer:
              parseResult.trimmedMetadata['曲'] ??
              parseResult.trimmedMetadata['作曲'] ??
              parseResult.trimmedMetadata['Composer'] ??
              parseResult.trimmedMetadata['Composed by'],
          isPureMusic: false,
          metadata: {
            ...parseResult.lrcMetadata,
            ...parseResult.trimmedMetadata,
          },
        );
      }

      return LyricsResult.empty();
    } catch (e) {
      AppLogger.debug('[QQMusic] Error fetching lyrics: $e');
      return failureUnlessCancelled(e, scope: scope, source: 'QQ Music');
    }
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data, {
    int translationBias = 0,
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      LyricsResult? translationResult;
      await fetchLyrics(
        title: data.title,
        artist: data.artist,
        durationSeconds: data.durationSeconds,
        translationBias: translationBias,
        scope: scope,
        onTranslation: (trans) {
          translationResult = trans;
        },
      );

      return translationResult ?? LyricsResult.empty();
    } catch (e) {
      AppLogger.debug('[QQMusic] Error fetching translation: $e');
      return failureUnlessCancelled(
        e,
        scope: scope,
        source: 'QQ Music',
        translation: true,
        translationProvider: 'QQ Music',
      );
    }
  }

  Future<List<ProcessedSong>> _searchSongs({
    required String title,
    required List<String> artist,
    int durationSeconds = 0,
    LyricsRequestScope? scope,
  }) async {
    try {
      final keywordList = ['$title - ${artist.join(', ')}', title];
      for (final keyword in keywordList) {
        final searchUrl = Uri.parse('https://u.y.qq.com/cgi-bin/musicu.fcg');
        final searchBody = {
          'music.search.SearchCgiService': {
            'method': 'DoSearchForQQMusicDesktop',
            'module': 'music.search.SearchCgiService',
            'param': {
              'num_per_page': 10,
              'page_num': 1,
              'query': keyword,
              'search_type': 0,
            },
          },
        };

        final searchResponse = await scopedPost(
          searchUrl,
          scope: scope,
          headers: {
            'Host': 'u.y.qq.com',
            'Origin': 'https://y.qq.com',
            'Referer': 'https://y.qq.com/',
            'User-Agent': _userAgent,
          },
          body: jsonEncode(searchBody),
        ).timeout(const Duration(seconds: 10));

        if (searchResponse.statusCode != 200) {
          throw Exception(
            'QQ Music search failed: HTTP ${searchResponse.statusCode}',
          );
        }

        final searchData = jsonDecode(utf8.decode(searchResponse.bodyBytes));
        final songList = QQMusicSearchParser.songList(searchData);
        if (songList.isEmpty) {
          AppLogger.debug('[QQMusic] Search returned no songs');
          continue;
        }

        final genericSongs = <GenericSong>[];
        for (final song in songList) {
          final songName = song['name'] as String?;
          if (songName == null) continue;

          final artistNames = (song['singer'] as List? ?? [])
              .map((ar) => (ar as Map?)?['name']?.toString() ?? '')
              .toList();

          final durationMs = (song['interval'] as int? ?? 0) * 1000;

          genericSongs.add(
            GenericSong(
              data: song,
              title: songName,
              artist: artistNames,
              durationMs: durationMs,
            ),
          );
        }

        final orderedSongs = SongResultHelper.orderBySimilarity(
          genericSongs,
          title,
          artist,
          durationSeconds * 1000,
          5000,
        );

        if (orderedSongs.isEmpty) {
          AppLogger.debug(
            '[QQMusic] Search returned songs but none matched the similarity threshold or length differ too large',
          );
          continue;
        }

        return orderedSongs;
      }

      return [];
    } catch (e) {
      AppLogger.debug('[QQMusic] Error searching song: $e');
      rethrow;
    }
  }

  Future<QQMusicDecodedLyrics?> _getLyrics({
    required String? songId,
    required String songMid,
    LyricsRequestScope? scope,
  }) async {
    try {
      if (songId == null || songId.isEmpty) {
        AppLogger.debug(
          '[QQMusic] Missing song id for lyric_download.fcg, songMid=$songMid',
        );
        return null;
      }

      final uri = Uri.parse(
        'https://c.y.qq.com/qqmusic/fcgi-bin/lyric_download.fcg',
      );
      final body = {
        'version': '15',
        'miniversion': '82',
        'lrctype': '4',
        'musicid': songId,
      };

      final response = await scopedPost(
        uri,
        scope: scope,
        headers: {
          'Host': 'c.y.qq.com',
          'Origin': 'https://y.qq.com',
          'Referer': 'https://y.qq.com/',
          'User-Agent': _userAgent,
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('QQ Music lyrics failed: HTTP ${response.statusCode}');
      }

      return QQMusicLyricDecoder.parseLyricDownloadResponse(
        _decodeQqResponseBody(response.bodyBytes),
      );
    } catch (e) {
      AppLogger.debug('[QQMusic] Cannot fetch lyrics: $e');
      rethrow;
    }
  }

  LrcParseResult _parseLyrics(
    String content, {
    required bool trimMetadata,
    required String title,
    required String artist,
  }) {
    final qqRichLyrics = QQRichParser.parse(content);
    if (qqRichLyrics.isNotEmpty) {
      if (trimMetadata) {
        return LrcParser.trimMetadataLines(
          qqRichLyrics,
          lrcMetadata: {'title': title, 'artist': artist},
        );
      } else {
        return LrcParseResult(lyrics: qqRichLyrics);
      }
    }

    return LrcParser.parse(content, trimMetadata: trimMetadata);
  }

  String _decodeQqResponseBody(List<int> bodyBytes) {
    try {
      return utf8.decode(bodyBytes);
    } catch (_) {
      return latin1.decode(bodyBytes);
    }
  }
}

/// Reads the song list from a `musicu.fcg` search response.
///
/// The request is keyed by the module name, and the response echoes that key.
/// The old `req_1` envelope is the one that starts returning code 2001.
class QQMusicSearchParser {
  static const String resultKey = 'music.search.SearchCgiService';

  static List<dynamic> songList(Object? response) {
    if (response is! Map) {
      throw Exception('QQ Music search failed: unexpected response');
    }

    final result = response[resultKey];
    if (result is! Map) {
      final topCode = response['code'];
      if (topCode != null && topCode != 0) {
        throw Exception('QQ Music search failed: code $topCode');
      }
      throw Exception('QQ Music search failed: missing $resultKey');
    }

    final code = result['code'];
    if (code != 0) {
      throw Exception('QQ Music search failed: code $code');
    }

    final data = result['data'];
    if (data is! Map) return const [];
    final dataCode = data['code'];
    if (dataCode != null && dataCode != 0) {
      throw Exception('QQ Music search failed: code $dataCode');
    }

    final list = data['body']?['song']?['list'];
    if (list is List) return list;
    return const [];
  }
}
