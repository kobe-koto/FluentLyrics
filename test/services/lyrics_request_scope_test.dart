import 'dart:io';

import 'package:fluent_lyrics/services/lyrics_request_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('cancel aborts an in-flight client request', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((_) {});

    final scope = LyricsRequestScope();
    final pending = scope.client.get(
      Uri.parse('http://127.0.0.1:${server.port}/hang'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    scope.cancel();

    await expectLater(pending, throwsA(isA<http.ClientException>()));
    expect(scope.isCancelled, isTrue);
  });

  test('a cancelled error is an empty result, not a failure', () {
    final scope = LyricsRequestScope()..cancel();
    final result = failureUnlessCancelled(
      http.ClientException('Connection closed'),
      scope: scope,
      source: 'LRCLIB',
    );

    expect(result.isFailure, isFalse);
    expect(result.lyrics, isEmpty);
  });
}
