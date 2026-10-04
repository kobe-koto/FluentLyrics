import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Request sign for the QQ Music `musics.fcg` gateway.
class QQMusicRequestSign {
  static const _part1Indexes = [23, 14, 6, 36, 16, 40, 7, 19];
  static const _part2Indexes = [16, 1, 32, 12, 19, 27, 8, 5];
  static const _scramble = [
    89,
    39,
    179,
    150,
    218,
    82,
    58,
    252,
    177,
    52,
    186,
    123,
    120,
    64,
    242,
    133,
    143,
    161,
    121,
    179,
  ];
  static const _guidCharset = 'ABCDEF1234567890';
  static const _searchIdEBase = 18014398509481984;
  static const _searchIdNBase = 4294967296;
  static const _searchIdNMax = 4194304;
  static const _dayMillis = 24 * 60 * 60 * 1000;

  static String sign(List<int> payload) {
    final hash = sha1.convert(payload).toString().toUpperCase();
    final part1 = String.fromCharCodes([
      for (final index in _part1Indexes)
        if (index < hash.length) hash.codeUnitAt(index),
    ]);
    final part2 = String.fromCharCodes([
      for (final index in _part2Indexes) hash.codeUnitAt(index),
    ]);
    final scrambled = List<int>.generate(_scramble.length, (index) {
      final hi = _hexNibble(hash.codeUnitAt(index * 2));
      final lo = _hexNibble(hash.codeUnitAt(index * 2 + 1));
      return _scramble[index] ^ ((hi << 4) | lo);
    });
    final encoded = base64Encode(scrambled).replaceAll(RegExp(r'[+/\\=]'), '');
    return 'zzc$part1$encoded$part2'.toLowerCase();
  }

  static String guid([Random? random]) {
    final source = random ?? Random();
    return List.generate(
      32,
      (_) => _guidCharset[source.nextInt(_guidCharset.length)],
    ).join();
  }

  static String searchId([Random? random, int? nowMillis]) {
    final source = random ?? Random();
    final e = source.nextInt(20) + 1;
    final n = source.nextInt(_searchIdNMax + 1);
    final r = (nowMillis ?? DateTime.now().millisecondsSinceEpoch) % _dayMillis;
    return (e * _searchIdEBase + n * _searchIdNBase + r).toString();
  }

  static int _hexNibble(int value) {
    if (value >= 0x30 && value <= 0x39) return value - 0x30;
    if (value >= 0x41 && value <= 0x46) return value - 0x41 + 10;
    if (value >= 0x61 && value <= 0x66) return value - 0x61 + 10;
    throw FormatException('invalid hex nibble');
  }
}

/// Signed song-search body. Key order is part of the signature.
class QQMusicSearchRequest {
  static const endpoint = 'https://u.y.qq.com/cgi-bin/musics.fcg';
  static const resultKey = 'result';

  final String body;
  final String sign;

  const QQMusicSearchRequest({required this.body, required this.sign});

  Uri get uri => Uri.parse(endpoint).replace(queryParameters: {'sign': sign});

  factory QQMusicSearchRequest.build({
    required String query,
    int limit = 10,
    int page = 1,
    String? guid,
    String? searchId,
    Random? random,
  }) {
    final payload = jsonEncode({
      'result': {
        'method': 'DoSearchForQQMusicDesktop',
        'module': 'music.search.SearchCgiService',
        'param': {
          'grp': 0,
          'num_per_page': limit,
          'page_num': page,
          'query': query,
          'search_type': 0,
          'searchid': searchId ?? QQMusicRequestSign.searchId(random),
        },
      },
      'comm': {
        'ct': 19,
        'cv': 2201,
        'chid': '0',
        'guid': guid ?? QQMusicRequestSign.guid(random),
      },
    });
    return QQMusicSearchRequest(
      body: payload,
      sign: QQMusicRequestSign.sign(utf8.encode(payload)),
    );
  }
}
