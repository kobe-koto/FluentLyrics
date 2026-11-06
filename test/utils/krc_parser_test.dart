import 'dart:convert';
import 'dart:io';

import 'package:fluent_lyrics/utils/krc_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decrypts KRC and parses line and word timings', () {
    const plaintext = '[1000,900]<0,400,0>Hello <400,500,0>world';
    final encoded = _encodeKrc(plaintext);

    final lyrics = KrcParser.parse(encoded);

    expect(lyrics, hasLength(1));
    expect(lyrics.single.text, 'Hello world');
    expect(lyrics.single.startTime.inMilliseconds, 1000);
    expect(lyrics.single.endTime!.inMilliseconds, 1900);
    expect(lyrics.single.inlineParts, hasLength(2));
    expect(lyrics.single.inlineParts![0].startTime.inMilliseconds, 1000);
    expect(lyrics.single.inlineParts![0].endTime.inMilliseconds, 1400);
    expect(lyrics.single.inlineParts![1].startTime.inMilliseconds, 1400);
    expect(lyrics.single.inlineParts![1].endTime.inMilliseconds, 1900);
  });

  test('unescapes KRC text and rejects non-KRC content', () {
    expect(KrcParser.parse(base64.encode(utf8.encode('plain'))), isEmpty);

    const plaintext = '[0,500]<0,500,0>I&apos;m here';
    final lyrics = KrcParser.parse(_encodeKrc(plaintext));
    expect(lyrics.single.text, "I'm here");
  });
}

String _encodeKrc(String plaintext) {
  const key = [
    0x40,
    0x47,
    0x61,
    0x77,
    0x5e,
    0x32,
    0x74,
    0x47,
    0x51,
    0x36,
    0x31,
    0x2d,
    0xce,
    0xd2,
    0x6e,
    0x69,
  ];
  final compressed = ZLibCodec().encode(utf8.encode(plaintext));
  final encrypted = List<int>.generate(
    compressed.length,
    (index) => compressed[index] ^ key[index % key.length],
  );
  return base64.encode([...utf8.encode('krc1'), ...encrypted]);
}
