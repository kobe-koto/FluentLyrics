import 'package:fluent_lyrics/services/lyrics_request_scope.dart';
import 'package:fluent_lyrics/services/providers/lrclib_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('plain lyrics are returned as unsynced', () async {
    final service = LrclibService(
      httpGet: (_) async => http.Response('''
[
  {
    "trackName": "Song",
    "plainLyrics": "first line\\nsecond line",
    "syncedLyrics": "",
    "enhancedLyrics": "",
    "instrumental": false
  }
]
''', 200),
    );

    final result = await service.fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      album: 'Album',
      durationSeconds: 120,
    );

    expect(result.lyrics, hasLength(2));
    expect(result.isSynced, isFalse);
  });

  test('synced lyrics are returned as synced', () async {
    final service = LrclibService(
      httpGet: (_) async => http.Response('''
[
  {
    "trackName": "Song",
    "plainLyrics": "first line",
    "syncedLyrics": "[00:01.00]first line\\n[00:02.00]second line",
    "enhancedLyrics": "",
    "instrumental": false
  }
]
''', 200),
    );

    final result = await service.fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      album: 'Album',
      durationSeconds: 120,
    );

    expect(result.lyrics, hasLength(2));
    expect(result.isSynced, isTrue);
  });

  test('a cancelled request is empty rather than a failure', () async {
    late final LyricsRequestScope scope;
    final client = _CancelThenThrowClient(() => scope.cancel());
    scope = LyricsRequestScope(client: client);
    final service = LrclibService();

    final result = await service.fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      album: 'Album',
      durationSeconds: 120,
      scope: scope,
    );

    expect(result.isFailure, isFalse);
    expect(result.lyrics, isEmpty);
  });
}

class _CancelThenThrowClient extends http.BaseClient {
  _CancelThenThrowClient(this.onSend);

  final void Function() onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onSend();
    throw http.ClientException('Connection closed', request.url);
  }
}
