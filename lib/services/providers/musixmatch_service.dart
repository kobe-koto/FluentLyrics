import 'dart:convert';
import 'dart:math';
import '../lyrics_request_scope.dart';
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/app_logger.dart';
import '../musixmatch_token.dart';
import '../settings_service.dart';

class MusixmatchService {
  MusixmatchService({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  bool checkTranslationSupport(String language) {
    // musixmatch only accept lowercase input
    String lowercaseLanguage = language.toLowerCase();
    if (lowercaseLanguage != language) {
      return false;
    }
    // musixmatch's Chinese Traditional is 'zht'
    if (lowercaseLanguage == 'zht') {
      return true;
    }
    // according to ISO 639-1, max length is 2
    if (lowercaseLanguage.length > 2) {
      return false;
    }
    return true;
  }

  static const String _apiBase = 'https://apic.musixmatch.com/ws/1.1';
  static const String _appId = 'android-player-v1.0';
  static const Map<String, String> _headers = {
    'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 13)',
    'Accept': 'application/json',
    'Cookie': 'AWSELB=0; AWSELBCORS=0',
  };

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(String)? onArtworkUrl,
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      String? token = await _usableToken();
      if (token == null) {
        onStatusUpdate?.call('[Musixmatch] Getting token...');
        token = await fetchNewToken(scope: scope);
        if (token != null) {
          await _settingsService.setMusixmatchToken(token);
        } else {
          throw Exception('Failed to get Musixmatch token');
        }
      }

      onStatusUpdate?.call('[Musixmatch] Searching lyrics...');
      final result = await _getLyricsResult(
        title,
        artist,
        durationSeconds,
        token,
        onArtworkUrl,
        scope: scope,
      );

      if (result != null) {
        return result;
      }
    } catch (e) {
      AppLogger.debug('[Musixmatch] Error fetching lyrics: $e');
      return failureUnlessCancelled(e, scope: scope, source: 'Musixmatch');
    }
    return LyricsResult.empty();
  }

  Future<String?> fetchNewToken({LyricsRequestScope? scope}) async {
    final url = Uri.parse(
      '$_apiBase/token.get?user_language=en&app_id=$_appId&t=${_requestId()}',
    );
    try {
      final response = await scopedGet(
        url,
        scope: scope,
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map) return null;
      final message = data['message'];
      if (message is! Map) return null;
      final header = message['header'];
      if (header is! Map || header['status_code'] != 200) return null;
      final body = message['body'];
      if (body is! Map) return null;
      final token = body['user_token'];
      if (token is! String || !isUsableMusixmatchToken(token)) return null;
      return token.trim();
    } catch (e) {
      AppLogger.debug('[Musixmatch] Error fetching token: $e');
    }
    return null;
  }

  Future<LyricsResult?> _getLyricsResult(
    String track,
    List<String> artist,
    int duration,
    String token,
    Function(String)? onArtworkUrl, {
    LyricsRequestScope? scope,
    bool allowRefresh = true,
  }) async {
    final url = _apiUri('macro.subtitles.get', {
      'namespace': 'lyrics_richsynched',
      'optional_calls': 'track.richsync,matcher.track.get',
      'subtitle_format': 'lrc',
      'q_track': track,
      'q_artist': artist.join(', '),
      'f_subtitle_length': duration.toString(),
      'q_duration': duration.toString(),
      'f_subtitle_length_max_deviation': '40',
      'usertoken': token,
    });

    final response = await scopedGet(
      url,
      scope: scope,
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final statusCode = data['message']['header']['status_code'];

      if (statusCode == 200) {
        final body = data['message']['body'];
        final macroCalls = body['macro_calls'];
        final trackSubtitles = macroCalls['track.subtitles.get'];
        final trackRichsync = macroCalls['track.richsync.get'];
        final matcherTrack = macroCalls['matcher.track.get'];

        String? artworkUrl;
        if (matcherTrack != null &&
            matcherTrack['message'] != null &&
            matcherTrack['message']['header'] != null &&
            matcherTrack['message']['header']['status_code'] == 200 &&
            matcherTrack['message']['body'] != null &&
            matcherTrack['message']['body']['track'] != null) {
          final trackBody = matcherTrack['message']['body']['track'];
          artworkUrl =
              [
                trackBody['album_coverart_800x800'],
                trackBody['album_coverart_500x500'],
                trackBody['album_coverart_350x350'],
                trackBody['album_coverart_100x100'],
              ].firstWhere(
                (url) =>
                    url != null &&
                    url is String &&
                    url.isNotEmpty &&
                    !url.contains('nocover.png'),
                orElse: () => null,
              );
          if (artworkUrl != null) {
            onArtworkUrl?.call(artworkUrl);
          }
        }

        bool isInstrumental = false;
        if (trackSubtitles != null &&
            trackSubtitles['message'] != null &&
            trackSubtitles['message']['header'] != null &&
            trackSubtitles['message']['header']['lyrics'] != null) {
          isInstrumental =
              trackSubtitles['message']['header']['lyrics']['instrumental'] ==
              1;
        }

        if (artworkUrl != null ||
            isInstrumental ||
            (trackSubtitles != null &&
                trackSubtitles['message']['header']['status_code'] == 200 &&
                _headerHasSubtitles(
                  trackSubtitles['message']['header'],
                  trackSubtitles['message']['body'],
                )) ||
            (trackRichsync != null &&
                trackRichsync['message']['header']['status_code'] == 200)) {
          List<Lyric> lyrics = [];
          String? writtenBy;
          String? copyright;
          bool isPureMusic = isInstrumental;
          String? language;

          if (trackSubtitles != null &&
              trackSubtitles['message']['header']['status_code'] == 200) {
            final header = trackSubtitles['message']['header'];
            final lyricsHeader = header['lyrics'];
            if (lyricsHeader != null) {
              isPureMusic = lyricsHeader['instrumental'] == 1;
            }

            if (_headerHasSubtitles(
              header,
              trackSubtitles['message']['body'],
            )) {
              final subtitleBody = trackSubtitles['message']['body'];
              final subtitleList = subtitleBody['subtitle_list'];
              if (subtitleList != null && subtitleList.isNotEmpty) {
                final subtitle = subtitleList[0]['subtitle'];
                final lrc = subtitle['subtitle_body'];

                language = subtitle['subtitle_language'];
                language = language == 'z1' ? 'zht' : language;

                final copyrightText = subtitle['lyrics_copyright'] as String?;
                if (copyrightText != null && copyrightText.isNotEmpty) {
                  final lines = copyrightText.split('\n');
                  for (var line in lines) {
                    final trimmedLine = line.trim();
                    if (trimmedLine.startsWith('Writer(s):')) {
                      writtenBy = trimmedLine
                          .substring('Writer(s):'.length)
                          .trim();
                    } else if (trimmedLine.startsWith('Copyright:')) {
                      copyright = trimmedLine
                          .substring('Copyright:'.length)
                          .trim();
                    }
                  }
                }
                lyrics = LrcParser.parse(lrc).lyrics;
              }
            }
          }

          if (trackRichsync != null &&
              trackRichsync['message']['header']['status_code'] == 200) {
            final richsyncBody = trackRichsync['message']['body'];
            if (richsyncBody != null && richsyncBody['richsync'] != null) {
              final richsync = richsyncBody['richsync'];
              final richsyncLrc = richsync['richsync_body'] as String?;
              if (richsyncLrc != null && richsyncLrc.isNotEmpty) {
                final richLyrics = MusixmatchRichParser.parse(richsyncLrc);
                if (richLyrics.isNotEmpty) {
                  lyrics = richLyrics;
                }
              }
            }
          }

          return LyricsResult(
            lyrics: lyrics,
            language: language,
            source: 'Musixmatch',
            writtenBy: writtenBy,
            copyright: copyright,
            isPureMusic: isPureMusic,
          );
        }
      } else if (statusCode == 401 &&
          data['message']['header']['hint'] == 'renew' &&
          allowRefresh) {
        final refreshed = await fetchNewToken(scope: scope);
        if (refreshed != null) {
          await _settingsService.setMusixmatchToken(refreshed);
          return _getLyricsResult(
            track,
            artist,
            duration,
            refreshed,
            onArtworkUrl,
            scope: scope,
            allowRefresh: false,
          );
        }
      }
    }
    return null;
  }

  bool _headerHasSubtitles(dynamic header, dynamic body) {
    if (header is! Map) return false;
    final available = header['available'];
    if (available is num) return available > 0;
    if (body is! Map) return false;
    final subtitleList = body['subtitle_list'];
    return subtitleList is List && subtitleList.isNotEmpty;
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
    String language, {
    LyricsRequestScope? scope,
  }) async {
    try {
      if (scope?.isCancelled == true) return LyricsResult.empty();
      String? token = await _usableToken();
      if (token == null) {
        token = await fetchNewToken(scope: scope);
        if (token != null) {
          await _settingsService.setMusixmatchToken(token);
        } else {
          return LyricsResult.failure(
            source: 'Musixmatch',
            message: 'Failed to get Musixmatch token',
            translation: true,
            translationProvider: 'Musixmatch',
          );
        }
      }

      final trackUrl = _apiUri('matcher.track.get', {
        'q_artist': data.artist,
        'q_track': data.title,
        'usertoken': token,
      });

      final trackResponse = await _performGet(trackUrl, token, scope: scope);
      if (trackResponse == null) return LyricsResult.empty();

      final trackData = jsonDecode(trackResponse);
      final trackBody = trackData['message']?['body'];
      final track = trackBody?['track'];

      if (track == null) return LyricsResult.empty();

      final trackId = track['track_id'].toString();

      // 2. Fetch Translation
      final transUrl = _apiUri('crowd.track.translations.get', {
        'translation_fields_set': 'minimal',
        'selected_language': language,
        'track_id': trackId,
        'comment_format': 'text',
        'part': 'user',
        'usertoken': token,
      });

      final transResponse = await _performGet(transUrl, token, scope: scope);
      if (transResponse == null) return LyricsResult.empty();

      final transData = jsonDecode(transResponse);

      if (transData['message']['header']['status_code'] != 200) {
        throw Exception(
          'Failed to fetch translation, code ${transData['message']['header']['status_code']}, ${transData['message']['header']['error_description']}',
        );
      }

      final transBody = transData['message']?['body'];
      final translationsList = transBody?['translations_list'] as List?;

      if (translationsList == null || translationsList.isEmpty) {
        AppLogger.debug(
          '[Musixmatch] No translations found for track $trackId in language $language',
        );
        return LyricsResult.empty();
      }

      // 3. Fetch Original Lyrics for Timestamps
      // track.subtitles.get
      final subUrl = _apiUri('track.subtitles.get', {
        'track_id': trackId,
        'subtitle_format': 'lrc',
        'usertoken': token,
      });

      final subResponse = await _performGet(subUrl, token, scope: scope);
      List<Lyric> originalLyrics = [];
      if (subResponse != null) {
        final subData = jsonDecode(subResponse);
        final subBody = subData['message']?['body'];
        final subList = subBody?['subtitle_list'] as List?;
        if (subList != null && subList.isNotEmpty) {
          final lrcBody = subList[0]['subtitle']?['subtitle_body'];
          if (lrcBody != null && lrcBody is String) {
            originalLyrics = LrcParser.parse(lrcBody).lyrics;
          }
        }
      }

      if (originalLyrics.isEmpty) {
        return LyricsResult.empty();
      }

      // 4. Map Translations to Original Lyrics
      List<Map<String, String>> rawTranslation = [];
      String? lang;

      for (var item in translationsList) {
        final translation = item['translation'];
        if (translation != null) {
          final matchedLine = translation['matched_line'] as String?;
          final description = translation['description'] as String?;

          if (matchedLine != null &&
              description != null &&
              description.isNotEmpty) {
            rawTranslation.add({
              'original': matchedLine.trim(),
              'translated': description,
            });
          }
        }
      }

      if (rawTranslation.isNotEmpty) {
        // Try to get language from first translation item
        if (translationsList.isNotEmpty) {
          final firstTrans = translationsList[0]['translation'];
          if (firstTrans != null) {
            lang = firstTrans['language'];
            lang = lang == 'z1' ? 'zht' : lang;
          }
        }

        return LyricsResult(
          lyrics: [],
          rawTranslation: rawTranslation,
          source: 'Musixmatch',
          translation: true,
          isSynced: true,
          language: lang ?? language,
          translationProvider: 'Musixmatch',
        );
      }

      return LyricsResult.empty();
    } catch (e) {
      AppLogger.debug('[Musixmatch] Error fetching translation: $e');
      return failureUnlessCancelled(
        e,
        scope: scope,
        source: 'Musixmatch',
        translation: true,
        translationProvider: 'Musixmatch',
      );
    }
  }

  Future<String?> _performGet(
    Uri url,
    String token, {
    int maxTrial = 3,
    LyricsRequestScope? scope,
  }) async {
    if (maxTrial < 0) return null;

    try {
      final response = await scopedGet(
        url,
        scope: scope,
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Check for 401 or captcha in body
        final header = _messageHeader(body);
        final statusCode = header?['status_code'];
        final hint = header?['hint'];
        if (statusCode == 401 && hint == 'renew') {
          final newToken = await fetchNewToken(scope: scope);
          if (newToken != null && newToken != token) {
            await _settingsService.setMusixmatchToken(newToken);
            final newUrl = url.replace(
              queryParameters: Map<String, String>.from(url.queryParameters)
                ..['usertoken'] = newToken,
            );
            return await _performGet(
              newUrl,
              newToken,
              maxTrial: maxTrial - 1,
              scope: scope,
            );
          }
        } else if (statusCode == 401 && hint == 'captcha') {
          await Future.delayed(const Duration(seconds: 1));
          return await _performGet(
            url,
            token,
            maxTrial: maxTrial - 1,
            scope: scope,
          );
        }
        return body;
      }
    } catch (e) {
      AppLogger.debug('[Musixmatch] Request error: $e');
    }
    return null;
  }

  Future<String?> _usableToken() async {
    final token = (await _settingsService.getMusixmatchToken()).current;
    if (!isUsableMusixmatchToken(token)) return null;
    return token!.trim();
  }

  Uri _apiUri(String method, Map<String, dynamic> query) {
    return Uri.parse('$_apiBase/$method').replace(
      queryParameters: {
        ...query,
        'app_id': _appId,
        'format': 'json',
        't': _requestId(),
      },
    );
  }

  Map<String, dynamic>? _messageHeader(String body) {
    try {
      final data = jsonDecode(body);
      final message = data is Map ? data['message'] : null;
      final header = message is Map ? message['header'] : null;
      if (header is Map<String, dynamic>) return header;
      if (header is Map) return Map<String, dynamic>.from(header);
    } catch (_) {}
    return null;
  }

  String _requestId() {
    final random = Random();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
