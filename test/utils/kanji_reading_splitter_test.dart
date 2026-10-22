import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/utils/kanji_reading_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a split as `勇[ゆう]気[き]` for readable expectations.
String _render(String text, int start, List<FuriganaAnnotation> parts) {
  final buffer = StringBuffer();
  var index = start;
  for (final part in parts) {
    buffer.write(text.substring(index, part.start));
    buffer.write(text.substring(part.start, part.end));
    buffer.write('[${part.reading}]');
    index = part.end;
  }
  return buffer.toString();
}

void main() {
  // A tiny dictionary keyed like the trimmed KANJIDIC2 asset. Readings may be
  // katakana (on) or hiragana (kun); the splitter normalizes both.
  final splitter = KanjiReadingSplitter(const {
    '勇': ['ユウ', 'いさ'],
    '気': ['キ', 'ケ', 'いき', 'き'],
    '学': ['ガク', 'まな'],
    '校': ['コウ'],
    '山': ['サン', 'やま'],
    '川': ['セン', 'かわ'],
    '手': ['シュ', 'て', 'た'],
    '紙': ['シ', 'かみ', 'がみ'],
  });

  List<FuriganaAnnotation>? split(String run, String reading) =>
      splitter.split(text: run, start: 0, end: run.length, reading: reading);

  group('splits a compound onto each kanji', () {
    test('勇気 -> 勇ゆう 気き', () {
      final parts = split('勇気', 'ゆうき');
      expect(parts, isNotNull);
      expect(_render('勇気', 0, parts!), '勇[ゆう]気[き]');
    });

    test('山川 -> 山やま 川かわ', () {
      final parts = split('山川', 'やまかわ');
      expect(parts, isNotNull);
      expect(_render('山川', 0, parts!), '山[やま]川[かわ]');
    });
  });

  group('sound changes', () {
    test('gemination: 学校 -> 学がっ 校こう', () {
      final parts = split('学校', 'がっこう');
      expect(parts, isNotNull);
      expect(_render('学校', 0, parts!), '学[がっ]校[こう]');
    });

    test('rendaku: 手紙 -> 手て 紙がみ', () {
      final parts = split('手紙', 'てがみ');
      expect(parts, isNotNull);
      expect(_render('手紙', 0, parts!), '手[て]紙[がみ]');
    });
  });

  group('keeps the whole run when it cannot split cleanly', () {
    test('jukujikun 今日 -> きょう returns null (no kanji in the dict)', () {
      expect(split('今日', 'きょう'), isNull);
    });

    test('single kanji run returns null', () {
      expect(split('気', 'き'), isNull);
    });

    test('empty reading returns null', () {
      expect(split('勇気', ''), isNull);
    });

    test('reading that exhausts before the kanji returns null', () {
      // Two kanji, one kana: cannot cover both.
      expect(split('勇気', 'き'), isNull);
    });
  });

  group('ambiguity is rejected', () {
    test('a run with two valid partitions returns null', () {
      // Both kanji can read か or かか, so かかか splits as either
      // か|かか or かか|か. Two solutions -> keep the whole run.
      final ambiguous = KanjiReadingSplitter(const {
        '甲': ['か', 'かか'],
        '乙': ['か', 'かか'],
      });
      final parts = ambiguous.split(
        text: '甲乙',
        start: 0,
        end: 2,
        reading: 'かかか',
      );
      expect(parts, isNull);
    });

    test('a single valid partition still resolves', () {
      final unambiguous = KanjiReadingSplitter(const {
        '甲': ['か', 'かか'],
        '乙': ['き'],
      });
      final parts = unambiguous.split(
        text: '甲乙',
        start: 0,
        end: 2,
        reading: 'かき',
      );
      expect(parts, isNotNull);
      expect(_render('甲乙', 0, parts!), '甲[か]乙[き]');
    });
  });

  group('respects run offset within a line', () {
    test('annotations are positioned at the run start', () {
      final parts = splitter.split(
        text: 'あの勇気を',
        start: 2,
        end: 4,
        reading: 'ゆうき',
      );
      expect(parts, isNotNull);
      expect(parts!.length, 2);
      expect(parts.first.start, 2);
      expect(parts.first.end, 3);
      expect(parts.last.start, 3);
      expect(parts.last.end, 4);
    });
  });
}
