import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/utils/romaji_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts the mora separated readings providers ship', () {
    expect(RomajiHelper.toKana('shi zu mu'), 'しずむ');
    expect(RomajiHelper.toKana('yu me na ra ba'), 'ゆめならば');
    expect(RomajiHelper.toKana('to ke te yu ku'), 'とけてゆく');
  });

  test('handles sokuon, small kana and long vowels', () {
    expect(RomajiHelper.toKana('ka tta'), 'かった');
    expect(RomajiHelper.toKana('syo u'), 'しょう');
    expect(RomajiHelper.toKana('kya kyu kyo'), 'きゃきゅきょ');
    expect(RomajiHelper.toKana('me ro di -'), 'めろでぃー');
  });

  test('accepts Hepburn and Kunrei spellings', () {
    expect(RomajiHelper.toKana('shi'), 'し');
    expect(RomajiHelper.toKana('si'), 'し');
    expect(RomajiHelper.toKana('fu'), 'ふ');
    expect(RomajiHelper.toKana('hu'), 'ふ');
    expect(RomajiHelper.toKana('tsu'), 'つ');
    expect(RomajiHelper.toKana('tu'), 'つ');
    expect(RomajiHelper.toKana('ji'), 'じ');
    expect(RomajiHelper.toKana('zi'), 'じ');
  });

  test('converts a full aligned line', () {
    expect(
      RomajiHelper.toKana('shi zu mu yo u ni to ke te yu ku yo u ni'),
      'しずむようにとけてゆくように',
    );
    expect(
      RomajiHelper.toKana('yu me na ra ba do re ho do yo ka tta de syo u'),
      'ゆめならばどれほどよかったでしょう',
    );
  });

  test('returns null for units it does not know', () {
    expect(RomajiHelper.toKana('xyz abc'), isNull);
    expect(RomajiHelper.toKana('shi zu bad'), isNull);
    expect(RomajiHelper.toKana(''), isNull);
  });

  test('turns an aligned romaji track into kana annotations', () {
    final annotations = FuriganaHelper.align(
      text: '沈むように溶けてゆくように',
      reading: 'shi zu mu yo u ni to ke te yu ku yo u ni',
      readingIsRomaji: true,
    );
    final kana = [
      for (final annotation in annotations)
        FuriganaAnnotation(
          start: annotation.start,
          end: annotation.end,
          reading: RomajiHelper.toKana(annotation.reading)!,
        ),
    ];

    expect(kana, const [
      FuriganaAnnotation(start: 0, end: 1, reading: 'しず'),
      FuriganaAnnotation(start: 5, end: 6, reading: 'と'),
    ]);
  });
}
