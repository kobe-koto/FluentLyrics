import 'package:fluent_lyrics/utils/lrc_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses stacked timestamps, metadata tags, and end times', () {
    final parsed = LrcParser.parse('''
[ti:Song]
[ar:Artist]
[00:10.00]second
[00:01.50][00:20.00]stacked
''');

    expect(parsed.lrcMetadata, {'ti': 'Song', 'ar': 'Artist'});
    expect(parsed.lyrics.map((line) => line.text), [
      'stacked',
      'second',
      'stacked',
    ]);
    expect(parsed.lyrics[0].startTime, const Duration(milliseconds: 1500));
    expect(parsed.lyrics[0].endTime, const Duration(seconds: 10));
    expect(parsed.lyrics[1].endTime, const Duration(seconds: 20));
    expect(parsed.lyrics[2].endTime, isNull);
  });

  test('unescapes lyric text and drops empty head and tail lines', () {
    final parsed = LrcParser.parse('''
[00:01.00]
[00:02.00]rock &amp; roll
[00:03.00]   
''');

    expect(parsed.lyrics, hasLength(1));
    expect(parsed.lyrics.single.text, 'rock & roll');
    expect(parsed.lyrics.single.startTime, const Duration(seconds: 2));
  });

  test('a timestamp without a fractional second is not a timed line', () {
    final parsed = LrcParser.parse('[00:01]no decimal\n[00:02.00]kept');

    expect(parsed.lyrics.map((line) => line.text), ['kept']);
  });

  test('trims credit lines and a title-artist line from the ends', () {
    final parsed = LrcParser.parse('''
[ti:Song]
[ar:Artist]
[00:01.00]作词：甲
[00:02.00]real line
[00:03.00]middle line stays
[00:04.00]Song - Artist
''', trimMetadata: true);

    expect(parsed.lyrics.map((line) => line.text), [
      'real line',
      'middle line stays',
    ]);
    expect(parsed.trimmedMetadata['作词'], '甲');
  });

  test('keeps credit lines when metadata trimming is off', () {
    final parsed = LrcParser.parse('[00:01.00]作词：甲\n[00:02.00]line');

    expect(parsed.lyrics.map((line) => line.text), ['作词：甲', 'line']);
    expect(parsed.trimmedMetadata, isEmpty);
  });
}
