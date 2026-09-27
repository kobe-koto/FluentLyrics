import 'dart:convert';

import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/services/lyrics_request_scope.dart';
import 'package:fluent_lyrics/services/pref_setting.dart';
import 'package:fluent_lyrics/services/providers/musixmatch_service.dart';
import 'package:fluent_lyrics/services/secret_store.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a missing available count still parses subtitle_list', () async {
    final result = await _fetch(
      _macro(
        subtitleList: [
          {
            'subtitle': {
              'subtitle_body': '[00:01.00]hello\n[00:02.00]world',
              'subtitle_language': 'en',
              'lyrics_copyright': 'Writer(s): Someone\nCopyright: Label',
            },
          },
        ],
      ),
    );

    expect(result.isFailure, isFalse);
    expect(result.lyrics.map((line) => line.text), ['hello', 'world']);
    expect(result.language, 'en');
    expect(result.writtenBy, 'Someone');
    expect(result.copyright, 'Label');
  });

  test('an explicit zero count does not parse a subtitle list', () async {
    final result = await _fetch(
      _macro(
        available: 0,
        subtitleList: [
          {
            'subtitle': {
              'subtitle_body': '[00:01.00]should not be used',
              'subtitle_language': 'en',
            },
          },
        ],
      ),
    );

    expect(result.isFailure, isFalse);
    expect(result.lyrics, isEmpty);
  });

  test('a missing count does not discard richsync', () async {
    final result = await _fetch(
      _macro(
        richsyncBody:
            '[{"ts": 1.0, "te": 2.0, "x": "rich", "l": [{"c": "rich", "o": 0.0}]}]',
      ),
    );

    expect(result.isFailure, isFalse);
    expect(result.lyrics.map((line) => line.text), ['rich']);
    expect(result.isRichSync, isTrue);
  });

  test('an all-zero token is not saved', () async {
    final store = MemorySecretStore();
    final client = _RoutingClient(
      (_) => http.Response(_tokenBody('0' * 56), 200),
    );

    final token = await _service(
      store,
    ).fetchNewToken(scope: LyricsRequestScope(client: client));

    expect(token, isNull);
    expect(store.values, isEmpty);
    expect(client.uris.single.host, 'apic.musixmatch.com');
    expect(client.uris.single.path, '/ws/1.1/token.get');
    expect(client.uris.single.queryParameters['app_id'], 'android-player-v1.0');
    expect(client.uris.single.queryParameters['user_language'], 'en');
    expect(client.headers.single['user-agent'], contains('Dalvik'));
  });

  test('an upgrade stub is not saved', () async {
    final store = MemorySecretStore();
    final client = _RoutingClient(
      (_) => http.Response(
        _tokenBody('UpgradeOnlyUpgradeOnlyUpgradeOnlyUpgradeOnly'),
        200,
      ),
    );

    final token = await _service(
      store,
    ).fetchNewToken(scope: LyricsRequestScope(client: client));

    expect(token, isNull);
    expect(store.values, isEmpty);
  });

  test('a stored placeholder is not sent as the user token', () async {
    final store = MemorySecretStore({
      PrefSettings.musixmatchToken.key: '0' * 56,
    });
    final client = _RoutingClient((request) {
      if (request.url.path.endsWith('token.get')) {
        return http.Response(_tokenBody('fresh-token'), 200);
      }
      return http.Response(
        _macro(
          subtitleList: [
            {
              'subtitle': {'subtitle_body': '[00:01.00]fresh'},
            },
          ],
        ),
        200,
      );
    });

    final result = await _service(store).fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 120,
      scope: LyricsRequestScope(client: client),
    );

    expect(result.lyrics.map((line) => line.text), ['fresh']);
    expect(client.uris.first.path, '/ws/1.1/token.get');
    expect(client.uris.last.queryParameters['usertoken'], 'fresh-token');
    expect(store.values[PrefSettings.musixmatchToken.key], 'fresh-token');
  });

  test('lyrics and token requests use the Android API', () async {
    final store = MemorySecretStore();
    final client = _RoutingClient((request) {
      if (request.url.path.endsWith('token.get')) {
        return http.Response(_tokenBody('android-token'), 200);
      }
      return http.Response(
        _macro(
          subtitleList: [
            {
              'subtitle': {
                'subtitle_body': '[00:01.00]android',
                'subtitle_language': 'en',
              },
            },
          ],
        ),
        200,
      );
    });

    final result = await _service(store).fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 120,
      scope: LyricsRequestScope(client: client),
    );

    expect(result.lyrics.map((line) => line.text), ['android']);
    expect(store.values[PrefSettings.musixmatchToken.key], 'android-token');
    expect(
      client.uris.map((uri) => uri.host),
      everyElement('apic.musixmatch.com'),
    );
    expect(client.uris.map((uri) => uri.path), [
      '/ws/1.1/token.get',
      '/ws/1.1/macro.subtitles.get',
    ]);
    expect(client.uris.last.queryParameters['app_id'], 'android-player-v1.0');
    expect(client.uris.last.queryParameters['usertoken'], 'android-token');
  });

  test('a 401 renew replaces the token and retries', () async {
    final store = MemorySecretStore({
      PrefSettings.musixmatchToken.key: 'old-token',
    });
    var macroCalls = 0;
    final client = _RoutingClient((request) {
      if (request.url.path.endsWith('token.get')) {
        return http.Response(_tokenBody('new-token'), 200);
      }
      macroCalls += 1;
      if (macroCalls == 1) return http.Response(_statusBody(401, 'renew'), 200);
      return http.Response(
        _macro(
          subtitleList: [
            {
              'subtitle': {
                'subtitle_body': '[00:01.00]refreshed',
                'subtitle_language': 'en',
              },
            },
          ],
        ),
        200,
      );
    });

    final result = await _service(store).fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 120,
      scope: LyricsRequestScope(client: client),
    );

    expect(result.lyrics.map((line) => line.text), ['refreshed']);
    expect(store.values[PrefSettings.musixmatchToken.key], 'new-token');
    expect(client.uris.last.queryParameters['usertoken'], 'new-token');
  });

  test(
    'a failed renew does not replace a usable token with a placeholder',
    () async {
      final store = MemorySecretStore({
        PrefSettings.musixmatchToken.key: 'old-token',
      });
      final client = _RoutingClient((request) {
        if (request.url.path.endsWith('token.get')) {
          return http.Response(_tokenBody('0' * 8), 200);
        }
        return http.Response(_statusBody(401, 'renew'), 200);
      });

      final result = await _service(store).fetchLyrics(
        title: 'Song',
        artist: const ['Artist'],
        durationSeconds: 120,
        scope: LyricsRequestScope(client: client),
      );

      expect(result.lyrics, isEmpty);
      expect(store.values[PrefSettings.musixmatchToken.key], 'old-token');
    },
  );
}

Future<LyricsResult> _fetch(String body) {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsService(
    secretStore: MemorySecretStore({PrefSettings.musixmatchToken.key: 'token'}),
  );
  final scope = LyricsRequestScope(client: _JsonClient(body));
  return MusixmatchService(settingsService: settings).fetchLyrics(
    title: 'Song',
    artist: const ['Artist'],
    durationSeconds: 120,
    scope: scope,
  );
}

String _macro({
  int? available,
  List<Map<String, dynamic>>? subtitleList,
  String? richsyncBody,
}) {
  final header = <String, dynamic>{'status_code': 200};
  if (available != null) header['available'] = available;
  return jsonEncode({
    'message': {
      'header': {'status_code': 200},
      'body': {
        'macro_calls': {
          'track.subtitles.get': {
            'message': {
              'header': header,
              if (subtitleList != null) 'body': {'subtitle_list': subtitleList},
            },
          },
          if (richsyncBody != null)
            'track.richsync.get': {
              'message': {
                'header': {'status_code': 200},
                'body': {
                  'richsync': {'richsync_body': richsyncBody},
                },
              },
            },
        },
      },
    },
  });
}

String _tokenBody(String token, {int statusCode = 200, String? hint}) {
  return jsonEncode({
    'message': {
      'header': {'status_code': statusCode, 'hint': ?hint},
      'body': {'user_token': token},
    },
  });
}

String _statusBody(int statusCode, String hint) {
  return jsonEncode({
    'message': {
      'header': {'status_code': statusCode, 'hint': hint},
    },
  });
}

SettingsService _settings(MemorySecretStore store) {
  SharedPreferences.setMockInitialValues({});
  return SettingsService(secretStore: store);
}

MusixmatchService _service(MemorySecretStore store) {
  return MusixmatchService(settingsService: _settings(store));
}

class _RoutingClient extends http.BaseClient {
  _RoutingClient(this.onRequest);

  final http.Response Function(http.Request request) onRequest;
  final uris = <Uri>[];
  final headers = <Map<String, String>>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    uris.add(req.url);
    headers.add(req.headers);
    final response = onRequest(req);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      request: request,
    );
  }
}

class _JsonClient extends http.BaseClient {
  _JsonClient(this.body);

  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response(body, 200);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      request: request,
    );
  }
}
