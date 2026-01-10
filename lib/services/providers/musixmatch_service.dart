import 'dart:convert';
import 'dart:developer';
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

  Future<List<Lyric>> fetchLyrics({
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
      final lyricsLrc = await _getLyricsLrc(
        title,
        artist,
        durationSeconds,
        token,
      );

      if (lyricsLrc != null && lyricsLrc.isNotEmpty) {
        onStatusUpdate?.call("Processing lyrics...");
        return LrcParser.parse(lyricsLrc);
      }
    } catch (e) {
      print('Error fetching Musixmatch lyrics: $e');
    }
    return [];
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

  Future<String?> _getLyricsLrc(
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
            'optional_calls': 'track.richsync',
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final statusCode = data['message']['header']['status_code'];

      if (statusCode == 200) {
        final body = data['message']['body'];
        final macroCalls = body['macro_calls'];
        final trackSubtitles = macroCalls['track.subtitles.get'];

        if (trackSubtitles != null &&
            trackSubtitles['message']['header']['status_code'] == 200 &&
            trackSubtitles['message']['header']['available'] > 0) {
          final subtitleBody = trackSubtitles['message']['body'];
          final subtitleList = subtitleBody['subtitle_list'];
          if (subtitleList != null && subtitleList.isNotEmpty) {
            return subtitleList[0]['subtitle']['subtitle_body'];
          }
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
