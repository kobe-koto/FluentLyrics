import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:flutter_test/flutter_test.dart';

String _annotated(String text, List<FuriganaAnnotation> annotations) {
  // Renders as: 星[ほし]のように見[み]えて...
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
    test('aligns the kana of the line with the reading', () {
      final annotations = FuriganaHelper.align(
        text: '星のように見えてゆくように',
        reading: 'ほしのようにみえてゆくように',
        readingIsRomaji: false,
      );

      expect(_annotated('星のように見えてゆくように', annotations), '[ほし]のように[み]えてゆくように');
    });

    test('handles katakana readings and long vowels', () {
      final annotations = FuriganaHelper.align(
        text: '光るメロディー',
        reading: 'ヒカルメロディー',
        readingIsRomaji: false,
      );

      expect(_annotated('光るメロディー', annotations), '[ヒカ]るメロディー');
    });
  });

  group('romaji readings', () {
    test('aligns the romanized track', () {
      final annotations = FuriganaHelper.align(
        text: '星のように見えてゆくように',
        reading: 'ho shi no yo u ni mi e te yu ku yo u ni',
        readingIsRomaji: true,
      );

      expect(
        _annotated('星のように見えてゆくように', annotations),
        '[ho shi]のように[mi]えてゆくように',
      );
    });

    test('merges sokuon with the following kana', () {
      final annotations = FuriganaHelper.align(
        text: '花ならばきっとよかったでしょう',
        reading: 'ha na na ra ba ki tto yo ka tta de syo u',
        readingIsRomaji: true,
      );

      expect(
        _annotated('花ならばきっとよかったでしょう', annotations),
        '[ha na]ならばきっとよかったでしょう',
      );
    });

    test('accepts Hepburn and Kunrei spellings', () {
      const cases = {'shi zu ka': 'shi zu', 'si zu ka': 'si zu'};
      for (final entry in cases.entries) {
        final annotations = FuriganaHelper.align(
          text: '静か',
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
        text: '「鳥を見ることなんて」',
        reading: '「to ri wo mi ru ko to na n te」',
        readingIsRomaji: true,
      );

      expect(_annotated('「鳥を見ることなんて」', annotations), '「[to ri]を[mi]ることなんて」');
    });
  });

  group('bail outs', () {
    test('returns nothing when the reading does not match the line', () {
      expect(
        FuriganaHelper.align(
          text: '星のように',
          reading: 'ko re wa ma tta ku chi ga u',
          readingIsRomaji: true,
        ),
        isEmpty,
      );
      expect(
        FuriganaHelper.align(
          text: '星のように',
          reading: 'まったくちがうよみかた',
          readingIsRomaji: false,
        ),
        isEmpty,
      );
    });

    test('returns nothing when there is no kanji to annotate', () {
      expect(
        FuriganaHelper.align(
          text: 'ほしのように',
          reading: 'ほしのように',
          readingIsRomaji: false,
        ),
        isEmpty,
      );
      expect(
        FuriganaHelper.align(
          text: '',
          reading: 'ho shi',
          readingIsRomaji: true,
        ),
        isEmpty,
      );
    });
  });
}
