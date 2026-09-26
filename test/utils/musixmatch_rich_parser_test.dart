import 'package:fluent_lyrics/utils/rich_lrc_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses line and word timings', () {
    final lyrics = MusixmatchRichParser.parse('''
[
  {
    "ts": 1.0,
    "te": 2.0,
    "x": "hello",
    "l": [
      {"c": "hel", "o": 0.0},
      {"c": "lo", "o": 0.25}
    ]
  }
]
''');

    expect(lyrics, hasLength(1));
    expect(lyrics.single.text, 'hello');
    expect(lyrics.single.startTime, const Duration(seconds: 1));
    expect(lyrics.single.endTime, const Duration(seconds: 2));
    expect(lyrics.single.inlineParts!.map((part) => part.text), ['hel', 'lo']);
    expect(
      lyrics.single.inlineParts![0].endTime,
      const Duration(milliseconds: 1250),
    );
    expect(lyrics.single.inlineParts![1].endTime, const Duration(seconds: 2));
  });

  test('keeps a line that has no word parts', () {
    final lyrics = MusixmatchRichParser.parse(
      '[{"ts": 0.5, "te": 1.5, "x": "plain"}]',
    );

    expect(lyrics.single.text, 'plain');
    expect(lyrics.single.inlineParts, isNull);
  });

  test('returns no lyrics for invalid rich sync json', () {
    expect(MusixmatchRichParser.parse('not-json'), isEmpty);
  });
}
