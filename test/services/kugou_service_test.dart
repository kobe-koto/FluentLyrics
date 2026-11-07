import 'dart:convert';

import 'package:fluent_lyrics/services/lyrics_request_scope.dart';
import 'package:fluent_lyrics/services/providers/kugou_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('searches, selects a lyric candidate, and downloads LRC', () async {
    final client = _KugouTestClient();
    final result = await KugouService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      scope: LyricsRequestScope(client: client),
    );

    expect(result.isFailure, isFalse);
    expect(result.source, 'Kugou Music');
    expect(result.lyrics.map((line) => line.text), ['hello', 'world']);
    expect(client.requests.map((request) => request.url.path), [
      '/api/v3/search/song',
      '/search',
      '/download',
      '/download',
    ]);
    expect(client.requests[1].url.queryParameters['hash'], 'hash');
    expect(client.requests[2].url.queryParameters['fmt'], 'krc');
    expect(client.requests[3].url.queryParameters['fmt'], 'lrc');
    expect(client.requests[3].url.queryParameters['id'], '1');
  });

  test('trims metadata lines when enabled', () async {
    const lrc =
        '[00:00.00]Song - Artist\n'
        '[00:00.50]作词：Writer\n'
        '[00:00.80]作曲：Composer\n'
        '[00:01.00]hello\n'
        '[00:02.00]world';

    final untrimmed = await KugouService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      scope: LyricsRequestScope(client: _KugouTestClient(lrc: lrc)),
    );
    expect(untrimmed.lyrics, hasLength(5));

    final trimmed = await KugouService().fetchLyrics(
      title: 'Song',
      artist: const ['Artist'],
      durationSeconds: 180,
      trimMetadata: true,
      scope: LyricsRequestScope(client: _KugouTestClient(lrc: lrc)),
    );
    expect(trimmed.lyrics.map((line) => line.text), ['hello', 'world']);
    expect(trimmed.writtenBy, 'Writer');
    expect(trimmed.composer, 'Composer');
  });
}

class _KugouTestClient extends http.BaseClient {
  _KugouTestClient({this.lrc = '[00:01.00]hello\n[00:02.00]world'});

  final String lrc;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final body = switch (request.url.path) {
      '/api/v3/search/song' => jsonEncode({
        'data': {
          'info': [
            {
              'songname': 'Song',
              'singername': 'Artist',
              'hash': 'hash',
              'duration': 180,
            },
          ],
        },
      }),
      '/search' => jsonEncode({
        'candidates': [
          {
            'id': '1',
            'accesskey': 'access',
            'song': 'Song',
            'singer': 'Artist',
            'duration': 180000,
          },
        ],
      }),
      '/download' => jsonEncode({'content': base64Encode(utf8.encode(lrc))}),
      _ => '{}',
    };
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}
