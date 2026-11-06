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
}

class _KugouTestClient extends http.BaseClient {
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
      '/download' => jsonEncode({
        'content': base64Encode(
          utf8.encode('[00:01.00]hello\n[00:02.00]world'),
        ),
      }),
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
