import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/lyric_model.dart';
import '../../utils/lrc_parser.dart';
import '../settings_service.dart';

class MusixmatchService {
  final SettingsService _settingsService = SettingsService();
  static const String _appId = 'web-desktop-app-v1.0';
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 FluentLyrics/0.1-git',
    'Accept': 'application/json',
    'Authority': 'apic-desktop.musixmatch.com',
    'Cookie':
        'AWSELB=unknown; x-mxm-user-id=; x-mxm-token-guid=; mxm-encrypted-token=;',
  };

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      String? token = await _settingsService.getMusixmatchToken();
      if (token == null || token.isEmpty) {
        onStatusUpdate?.call("Getting Musixmatch token...");
        token = await fetchNewToken();
        if (token != null) {
          await _settingsService.setMusixmatchToken(token);
        } else {
          throw Exception("Failed to get Musixmatch token");
        }
      }

      onStatusUpdate?.call("Searching lyrics on Musixmatch...");
      final result = await _getLyricsResult(
        title,
        artist,
        durationSeconds,
        token,
      );

      if (result != null) {
        return result;
      }
    } catch (e) {
      print('Error fetching Musixmatch lyrics: $e');
    }
    return LyricsResult.empty();
  }

  Future<String?> fetchNewToken() async {
    final t = _randomId();
    final url = Uri.parse(
      'https://apic-desktop.musixmatch.com/ws/1.1/token.get?app_id=$_appId&t=$t',
    );
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['body']['user_token'];
      }
    } catch (e) {
      print('Error fetching Musixmatch token: $e');
    }
    return null;
  }

  Future<LyricsResult?> _getLyricsResult(
    String track,
    String artist,
    int duration,
    String token,
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
            'q_artist': artist,
            'f_subtitle_length': duration.toString(),
            'q_duration': duration.toString(),
            'f_subtitle_length_max_deviation': '40',
            'usertoken': token,
            'app_id': _appId,
            't': t,
            'format': 'json',
          },
        );

    final response = await http.get(url, headers: _headers);

    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final statusCode = data['message']['header']['status_code'];

      if (statusCode == 200) {
        final body = data['message']['body'];
        final macroCalls = body['macro_calls'];
        final trackSubtitles = macroCalls['track.subtitles.get'];
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
              trackBody['album_coverart_800x800'] ??
              trackBody['album_coverart_500x500'] ??
              trackBody['album_coverart_350x350'] ??
              trackBody['album_coverart_100x100'];
        }

        if (artworkUrl != null ||
            (trackSubtitles != null &&
                trackSubtitles['message']['header']['status_code'] == 200 &&
                trackSubtitles['message']['header']['available'] > 0)) {
          List<Lyric> lyrics = [];
          String? writtenBy;
          String? copyright;

          if (trackSubtitles != null &&
              trackSubtitles['message']['header']['status_code'] == 200 &&
              trackSubtitles['message']['header']['available'] > 0) {
            final subtitleBody = trackSubtitles['message']['body'];
            final subtitleList = subtitleBody['subtitle_list'];
            if (subtitleList != null && subtitleList.isNotEmpty) {
              final subtitle = subtitleList[0]['subtitle'];
              final lrc = subtitle['subtitle_body'];
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
              lyrics = LrcParser.parse(lrc);
            }
          }

          return LyricsResult(
            lyrics: lyrics,
            source: 'Musixmatch',
            writtenBy: writtenBy,
            copyright: copyright,
            artworkUrl: artworkUrl,
          );
        }
      } else if (statusCode == 401) {
        // Token expired?
        await _settingsService.setMusixmatchToken(''); // Clear token
      }
    }
    return null;
  }

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(10, (i) => chars[random.nextInt(chars.length)]).join();
  }
}
