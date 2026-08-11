import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../models/general_translation_request_data.dart';
import '../../utils/lrc_parser.dart';
import '../../utils/rich_lrc_parser.dart';
import '../../utils/app_logger.dart';
import '../settings_service.dart';

class MusixmatchService {
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

  final SettingsService _settingsService = SettingsService();
  static const String _appId = 'web-desktop-app-v1.0';
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Authority': 'apic-desktop.musixmatch.com',
    'Cookie':
        'AWSELB=unknown; x-mxm-user-id=; x-mxm-token-guid=; mxm-encrypted-token=;',
  };

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(String)? onArtworkUrl,
  }) async {
    try {
      String? token = (await _settingsService.getMusixmatchToken()).current;
      if (token == null || token.isEmpty) {
        onStatusUpdate?.call('[Musixmatch] Getting token...');
        token = await fetchNewToken();
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
      );

      if (result != null) {
        return result;
      }
    } catch (e) {
      AppLogger.debug('[Musixmatch] Error fetching lyrics: $e');
    }
    return LyricsResult.empty();
  }

  Future<String?> fetchNewToken() async {
    final t = _randomId();
    final url = Uri.parse(
      'https://apic-desktop.musixmatch.com/ws/1.1/token.get?app_id=$_appId&t=$t',
    );
    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['body']['user_token'];
      }
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
    Function(String)? onArtworkUrl,
  ) async {
    final t = _randomId();
    final url =
        Uri.parse(
          'https://apic-desktop.musixmatch.com/ws/1.1/macro.subtitles.get',
        ).replace(
          queryParameters: {
            'namespace': 'lyrics_richsynched',
            'optional_calls': 'track.richsync,matcher.track.get',
            'subtitle_format': 'lrc',
            'q_track': track,
            'q_artist': artist.join(', '),
            'f_subtitle_length': duration.toString(),
            'q_duration': duration.toString(),
            'f_subtitle_length_max_deviation': '40',
            'usertoken': token,
            'app_id': _appId,
            't': t,
            'format': 'json',
          },
        );

    final response = await http
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 10));

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
                trackSubtitles['message']['header']['available'] > 0) ||
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

            if (header['available'] > 0) {
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
      } else if (statusCode == 401) {
        // Token expired?
        await _settingsService.setMusixmatchToken(''); // Clear token
      }
    }
    return null;
  }

  Future<LyricsResult> fetchTranslation(
    GeneralTranslationRequestData data,
    String language,
  ) async {
    try {
      String? token = (await _settingsService.getMusixmatchToken()).current;
      if (token == null || token.isEmpty) {
        token = await fetchNewToken();
        if (token != null) {
          await _settingsService.setMusixmatchToken(token);
        } else {
          return LyricsResult.empty();
        }
      }

      // 1. Get Track ID
      final t = _randomId();
      final trackUrl =
          Uri.parse(
            'https://apic-desktop.musixmatch.com/ws/1.1/matcher.track.get',
          ).replace(
            queryParameters: {
              'q_artist': data.artist,
              'q_track': data.title,
              'usertoken': token,
              'app_id': _appId,
              't': t,
              'format': 'json',
            },
          );

      final trackResponse = await _performGet(trackUrl, token);
      if (trackResponse == null) return LyricsResult.empty();

      final trackData = jsonDecode(trackResponse);
      final trackBody = trackData['message']?['body'];
      final track = trackBody?['track'];

      if (track == null) return LyricsResult.empty();

      final trackId = track['track_id'].toString();

      // 2. Fetch Translation
      final transUrl =
          Uri.parse(
            'https://apic-desktop.musixmatch.com/ws/1.1/crowd.track.translations.get',
          ).replace(
            queryParameters: {
              'translation_fields_set': 'minimal',
              'selected_language': language,
              'track_id': trackId,
              'comment_format': 'text',
              'part': 'user',
              'usertoken': token,
              'app_id': _appId,
              't': t,
              'format': 'json',
            },
          );

      final transResponse = await _performGet(transUrl, token);
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
      final subUrl =
          Uri.parse(
            'https://apic-desktop.musixmatch.com/ws/1.1/track.subtitles.get',
          ).replace(
            queryParameters: {
              'track_id': trackId,
              'subtitle_format': 'lrc',
              'usertoken': token,
              'app_id': _appId,
              't': t,
              'format': 'json',
            },
          );

      final subResponse = await _performGet(subUrl, token);
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
      return LyricsResult.empty();
    }
  }

  Future<String?> _performGet(Uri url, String token, {int maxTrial = 3}) async {
    if (maxTrial < 0) return null;

    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Check for 401 or captcha in body
        if (body.contains('"status_code":401')) {
          if (body.contains('"hint":"renew"')) {
            // Refresh token
            final newToken = await fetchNewToken();
            if (newToken != null) {
              await _settingsService.setMusixmatchToken(newToken);
              // Update URL with new token
              final newUrl = url.replace(
                queryParameters: Map.from(url.queryParameters)
                  ..['usertoken'] = newToken,
              );
              return _performGet(newUrl, newToken, maxTrial: maxTrial - 1);
            }
          } else if (body.contains('"hint":"captcha"')) {
            // Wait and retry
            await Future.delayed(const Duration(seconds: 1));
            return _performGet(url, token, maxTrial: maxTrial - 1);
          }
        }
        return body;
      }
    } catch (e) {
      AppLogger.debug('[Musixmatch] Request error: $e');
    }
    return null;
  }

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(10, (i) => chars[random.nextInt(chars.length)]).join();
  }
}
