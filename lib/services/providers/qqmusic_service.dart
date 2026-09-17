import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../models/general_translation_request_data.dart';
import '../../models/lyric_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/lyrics_reading_helper.dart';
import '../../utils/qqmusic_lyric_decoder.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/song_result_helper.dart';
import '../../utils/translation_helper.dart';

class QQMusicService {
  static const int lyricEmptyRetryCount = 3;

  static const Map<String, String> _headers = {
    'Referer': 'https://c.y.qq.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  };

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
      onStatusUpdate?.call('[QQMusic] Searching songs...');

      final bestMatch = await _searchSongs(
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
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
      return LyricsResult.empty();
    }
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
      AppLogger.debug('[QQMusic] Error fetching translation: $e');
      return LyricsResult.empty();
    }
  }

  Future<List<ProcessedSong>> _searchSongs({
    required String title,
    required List<String> artist,
    int durationSeconds = 0,
  }) async {
    try {
      final keywordList = ['$title - ${artist.join(', ')}', title];
      for (final keyword in keywordList) {
        final searchUrl = Uri.parse('https://u.y.qq.com/cgi-bin/musicu.fcg');
        final searchBody = {
          'req_1': {
            'method': 'DoSearchForQQMusicDesktop',
            'module': 'music.search.SearchCgiService',
            'param': {
              'num_per_page': 20,
              'page_num': 1,
              'query': keyword,
              'search_type': 0,
            },
          },
        };

        final searchResponse = await http
            .post(searchUrl, headers: _headers, body: jsonEncode(searchBody))
            .timeout(const Duration(seconds: 10));

        if (searchResponse.statusCode != 200) {
          AppLogger.debug(
            '[QQMusic] Search failed: ${searchResponse.statusCode}',
          );
          continue;
        }

        final searchData = jsonDecode(utf8.decode(searchResponse.bodyBytes));
        final req1 = searchData['req_1'];
        if (req1['code'] != 0) {
          AppLogger.debug('[QQMusic] Search API error: ${req1['code']}');
          continue;
        }

        final songList = req1['data']['body']['song']['list'] as List? ?? [];
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
      return [];
    }
  }

  Future<QQMusicDecodedLyrics?> _getLyrics({
    required String? songId,
    required String songMid,
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

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      return QQMusicLyricDecoder.parseLyricDownloadResponse(
        _decodeQqResponseBody(response.bodyBytes),
      );
    } catch (e) {
      AppLogger.debug('[QQMusic] Cannot fetch lyrics: $e');
      return null;
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
