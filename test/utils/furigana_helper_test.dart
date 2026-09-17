import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:flutter_test/flutter_test.dart';

String _annotated(String text, List<FuriganaAnnotation> annotations) {
  // Renders as: 沈[しず]むように溶[と]けて...
  final buffer = StringBuffer();
  var index = 0;
  for (final annotation in annotations) {
    buffer.write(text.substring(index, annotation.start));
    buffer.write('[${annotation.reading}]');
    index = annotation.end;
  }
  buffer.write(text.substring(index));
  return buffer.toString();
}

void main() {
  group('kana readings', () {
    test('aligns the kana of the line with the reading (NetEase sample)', () {
      final annotations = FuriganaHelper.align(
        text: '沈むように溶けてゆくように',
        reading: 'しずむようにとけてゆくように',
        readingIsRomaji: false,
      );

      expect(_annotated('沈むように溶けてゆくように', annotations), '[しず]むように[と]けてゆくように');
    });

    test('handles katakana readings and long vowels', () {
      final annotations = FuriganaHelper.align(
        text: '駆けるメロディー',
        reading: 'カケルメロディー',
        readingIsRomaji: false,
      );

      expect(_annotated('駆けるメロディー', annotations), '[カ]けるメロディー');
    });
  });

  group('romaji readings', () {
    test('aligns the romanized track (NetEase sample)', () {
      final annotations = FuriganaHelper.align(
        text: '沈むように溶けてゆくように',
        reading: 'shi zu mu yo u ni to ke te yu ku yo u ni',
        readingIsRomaji: true,
      );

      expect(
        _annotated('沈むように溶けてゆくように', annotations),
        '[shi zu]むように[to]けてゆくように',
      );
    });

    test('merges sokuon with the following kana (Lemon sample)', () {
      final annotations = FuriganaHelper.align(
        text: '夢ならばどれほどよかったでしょう',
        reading: 'yu me na ra ba do re ho do yo ka tta de syo u',
        readingIsRomaji: true,
      );

      expect(
        _annotated('夢ならばどれほどよかったでしょう', annotations),
        '[yu me]ならばどれほどよかったでしょう',
      );
    });

    test('accepts Hepburn and Kunrei spellings', () {
      const cases = {'shi zu mu': 'shi zu', 'si zu mu': 'si zu'};
      for (final entry in cases.entries) {
        final annotations = FuriganaHelper.align(
          text: '沈む',
          reading: entry.key,
          readingIsRomaji: true,
        );
        expect(annotations, [
          FuriganaAnnotation(start: 0, end: 1, reading: entry.value),
        ], reason: entry.key);
      }
    });

    test('tolerates a particle romanized as spoken', () {
      final annotations = FuriganaHelper.align(
        text: '私は',
        reading: 'wa ta shi wa',
        readingIsRomaji: true,
      );

      expect(_annotated('私は', annotations), '[wa ta shi]は');
    });
  });

  group('punctuation in the reading track', () {
    test('ignores quote tokens the provider kept in', () {
      final annotations = FuriganaHelper.align(
        text: '「誰かを好きになることなんて」',
        reading: '「da re ka wo su ki ni na ru ko to na n te」',
        readingIsRomaji: true,
      );

      expect(
        _annotated('「誰かを好きになることなんて」', annotations),
        '「[da re]かを[su]きになることなんて」',
      );
    });
  });

  group('bail outs', () {
    test('returns nothing when the reading does not match the line', () {
      expect(
        FuriganaHelper.align(
          text: '沈むように',
          reading: 'ko re wa ma tta ku chi ga u',
          readingIsRomaji: true,
        ),
        isEmpty,
      );
      expect(
        FuriganaHelper.align(
          text: '沈むように',
          reading: 'まったくちがうよみかた',
          readingIsRomaji: false,
        ),
        isEmpty,
      );
    });

    test('returns nothing when there is no kanji to annotate', () {
      expect(
        FuriganaHelper.align(
          text: 'しずむように',
          reading: 'しずむように',
          readingIsRomaji: false,
        ),
        isEmpty,
      );
      expect(
        FuriganaHelper.align(
          text: '',
          reading: 'shi zu mu',
          readingIsRomaji: true,
        ),
        isEmpty,
      );
    });
  });
}
