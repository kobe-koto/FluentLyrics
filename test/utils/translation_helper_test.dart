import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/translation_helper.dart';
import 'package:flutter_test/flutter_test.dart';

Lyric line(String text, int milliseconds) {
  return Lyric(
    startTime: Duration(milliseconds: milliseconds),
    text: text,
  );
}

void main() {
  test(
    'pairs by exact timestamp and leaves an empty translation uncovered',
    () {
      final paired = TranslationHelper.pair(
        originalLyrics: [line('one', 1000), line('two', 2000)],
        translatedLyrics: [
          line('一', 1000),
          line('   ', 2000),
          line('later', 3000),
        ],
      );

      expect(paired, [
        {'original': 'one', 'translated': '一'},
        {'original': 'two', 'translated': ''},
      ]);
    },
  );

  test('bias zero stays exact and a nonzero bias uses that window', () {
    final original = [line('one', 1000)];
    final translated = [line('一', 1050)];

    expect(
      TranslationHelper.pair(
        originalLyrics: original,
        translatedLyrics: translated,
      ).single['translated'],
      isEmpty,
    );
    expect(
      TranslationHelper.pair(
        originalLyrics: original,
        translatedLyrics: translated,
        translationBias: 100,
      ).single['translated'],
      '一',
    );
  });

  test('aligns a close original line and keeps the lyric timing', () {
    final aligned = TranslationHelper.align(
      originalLyrics: [line('Hello', 1000), line('untouched', 2000)],
      rawTranslation: [
        {'original': 'hello', 'translated': '你好'},
        {'original': 'other', 'translated': '其他'},
      ],
    );

    expect(aligned[0].translation, '你好');
    expect(aligned[0].startTime, const Duration(seconds: 1));
    expect(aligned[0].text, 'Hello');
    expect(aligned[1].translation, isNull);
    expect(aligned[1].text, 'untouched');
  });

  test('does not skip a nearby translation after a far match', () {
    final aligned = TranslationHelper.align(
      originalLyrics: [line('alpha', 0), line('beta', 1), line('gamma', 2)],
      rawTranslation: [
        {'original': 'alpha', 'translated': '甲'},
        {'original': 'gamma', 'translated': '丙'},
        {'original': 'skip', 'translated': '跳'},
        {'original': 'skip', 'translated': '跳'},
        {'original': 'beta', 'translated': '乙'},
      ],
    );

    expect(aligned.map((item) => item.translation), ['甲', '乙', '丙']);
  });

  test('coverage uses the percentage ceiling and ignores blank lines', () {
    final lyrics = [
      line('one', 1),
      line('   ', 2),
      line('two', 3),
      line('three', 4),
      line('four', 5),
      line('five', 6),
    ];
    final raw = [
      {'original': 'one', 'translated': '1'},
      {'original': 'two', 'translated': '2'},
      {'original': 'three', 'translated': '3'},
      {'original': 'four', 'translated': '4'},
    ];

    expect(
      TranslationHelper.coverage(currentLyrics: lyrics, rawTranslation: raw),
      (4, 5),
    );
    expect(
      TranslationHelper.hasSufficientCoverage(
        currentLyrics: lyrics,
        rawTranslation: raw,
        coverageThreshold: 80,
        perLineSimilarityThreshold: 80,
      ),
      isTrue,
    );
    expect(
      TranslationHelper.hasSufficientCoverage(
        currentLyrics: lyrics,
        rawTranslation: raw.take(3).toList(),
        coverageThreshold: 80,
        perLineSimilarityThreshold: 80,
      ),
      isFalse,
    );
    expect(
      TranslationHelper.hasSufficientCoverage(
        currentLyrics: lyrics,
        rawTranslation: const [],
        coverageThreshold: 0,
        perLineSimilarityThreshold: 80,
      ),
      isFalse,
    );
    expect(
      TranslationHelper.hasSufficientCoverage(
        currentLyrics: lyrics,
        rawTranslation: raw,
        coverageThreshold: 0,
        perLineSimilarityThreshold: 80,
      ),
      isTrue,
    );
  });
}
