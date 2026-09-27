import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/utils/romaji_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts the mora separated readings providers ship', () {
    expect(RomajiHelper.toKana('ho shi'), 'ほし');
    expect(RomajiHelper.toKana('ha na na ra ba'), 'はなならば');
    expect(RomajiHelper.toKana('mi e te yu ku'), 'みえてゆく');
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
      RomajiHelper.toKana('ho shi no yo u ni mi e te yu ku yo u ni'),
      'ほしのようにみえてゆくように',
    );
    expect(
      RomajiHelper.toKana('ha na na ra ba ki tto yo ka tta de syo u'),
      'はなならばきっとよかったでしょう',
    );
  });

  test('returns null for units it does not know', () {
    expect(RomajiHelper.toKana('xyz abc'), isNull);
    expect(RomajiHelper.toKana('shi zu bad'), isNull);
    expect(RomajiHelper.toKana(''), isNull);
  });

  test('turns an aligned romaji track into kana annotations', () {
    final annotations = FuriganaHelper.align(
      text: '星のように見えてゆくように',
      reading: 'ho shi no yo u ni mi e te yu ku yo u ni',
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
      FuriganaAnnotation(start: 0, end: 1, reading: 'ほし'),
      FuriganaAnnotation(start: 5, end: 6, reading: 'み'),
    ]);
  });
}
