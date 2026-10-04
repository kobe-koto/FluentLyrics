import 'dart:convert';

import 'package:fluent_lyrics/utils/qqmusic_request_sign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sign matches the known musics.fcg vector', () {
    final payload = utf8.encode('{"foo":"bar","num":1}');

    expect(
      QQMusicRequestSign.sign(payload),
      'zzcf3ea51dcp3xdwnxisjgufsk0znclehf2t85bc1d3d4',
    );
  });

  test('search body keeps the signed key order', () {
    const expected =
        '{"result":{"method":"DoSearchForQQMusicDesktop","module":"music.search.SearchCgiService","param":{"grp":0,"num_per_page":10,"page_num":1,"query":"江南","search_type":0,"searchid":"7"}},"comm":{"ct":19,"cv":2201,"chid":"0","guid":"ABCDEF1234567890ABCDEF1234567890"}}';
    final request = QQMusicSearchRequest.build(
      query: '江南',
      guid: 'ABCDEF1234567890ABCDEF1234567890',
      searchId: '7',
    );

    expect(request.body, expected);
    expect(request.sign, QQMusicRequestSign.sign(utf8.encode(expected)));
    expect(request.uri.path, '/cgi-bin/musics.fcg');
    expect(request.uri.queryParameters['sign'], request.sign);
    expect(request.uri.queryParameters.containsKey('comm'), isFalse);
  });
}
