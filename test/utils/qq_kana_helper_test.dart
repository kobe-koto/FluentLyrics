import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/utils/qq_kana_helper.dart';
import 'package:flutter_test/flutter_test.dart';

String _render(String line, List<FuriganaAnnotation> annotations) {
  final buffer = StringBuffer();
  var index = 0;
  for (final annotation in annotations) {
    buffer.write(line.substring(index, annotation.start));
    buffer.write('[${annotation.reading}]');
    index = annotation.end;
  }
  buffer.write(line.substring(index));
  return buffer.toString();
}

const _demoKana =
    '1し1きょく1へん1きょく1あお(900,120)1かぜ1はし2きょう(3400,180)1なに1み1はな(5300,160)1さ1よる1ぼく1し';

const _demoLines = <(int, int, String)>[
  (0, 400, 'サンプル - Demo (デモ)'),
  (400, 520, '词：Koto'),
  (520, 680, '曲：Koto'),
  (680, 760, '编曲：Koto'),
  (800, 3200, '青い風で走るテスト'),
  (3300, 5100, '今日何見た?'),
  (5200, 7400, '「花が咲く夜なんて'),
  (7400, 9100, '僕は知らなくてさ」'),
];

// Credit lines can insert empty single-digit runs for the latin after a colon
// (`1し1111きょく`). The caller may also drop those lines while the payload
// still starts at them.
const _paddedKana =
    '1し1111きょく1へん1きょく'
    '1あお(3100,80)1ひ1ひか1ひと1お'
    '1しろ1かみ1しるし'
    '1みぎ1あし1ひと1り1ある'
    '1む1だ2はなび1み';

const _paddedLines = <(int, int, String)>[
  (100, 700, 'SAMPLE - Koto'),
  (700, 1400, '词：Abc1'),
  (1400, 2100, '曲：Abc1'),
  (2100, 2800, '编曲：Abc1'),
  (3000, 6200, '青い灯が光ったのは一つの終わり'),
  (6200, 9000, '白い紙の印'),
  (9000, 12000, '右足で一人歩く まるでテスト'),
  (12000, 14500, '無駄な花火は見ない'),
  (14500, 16000, 'そのままね'),
];

void main() {
  group('parseRuns', () {
    test('reads the kanji count in front of each reading', () {
      final runs = QqKanaHelper.parseRuns('1あお1ば1はな1こ');
      expect(runs.map((r) => r.kanjiCount), [1, 1, 1, 1]);
      expect(runs.map((r) => r.reading), ['あお', 'ば', 'はな', 'こ']);
    });

    test('a compound reading carries the number of kanji it covers', () {
      final runs = QqKanaHelper.parseRuns('1う1そ2きょう1あめ');
      expect(runs[2].kanjiCount, 2);
      expect(runs[2].reading, 'きょう');
    });

    test('keeps the karaoke timings and drops them from the reading', () {
      final runs = QqKanaHelper.parseRuns('1あ(1547,224)お(1771,153)2か');
      expect(runs.first.reading, 'あお');
      expect(runs.first.timesMs, [1547, 1771]);
      expect(runs.last.reading, 'か');
    });

    test('rejects a payload that is not a list of kana readings', () {
      expect(QqKanaHelper.parseRuns(''), isEmpty);
      expect(QqKanaHelper.parseRuns('1abc'), isEmpty);
      // A zero means a two digit count we do not understand, so the whole
      // payload is refused instead of silently splitting it.
      expect(QqKanaHelper.parseRuns('1あお10ば'), isEmpty);
    });

    test('reads consecutive digits as consecutive padding entries', () {
      final runs = QqKanaHelper.parseRuns('1あお111ば2はな');
      expect(runs.map((r) => r.kanjiCount), [1, 1, 2]);
      expect(runs.map((r) => r.reading), ['あお', 'ば', 'はな']);
    });
  });

  group('annotateLines', () {
    test('annotates one kanji per run when the counts line up', () {
      final lines = [const QqKanaLine('青葉花子'), const QqKanaLine('本当')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1あお1ば1はな1こ1ほん1とう'),
      );

      expect(_render(lines[0].text, annotations[0]), '[あお][ば][はな][こ]');
      expect(_render(lines[1].text, annotations[1]), '[ほん][とう]');
    });

    test('skips the kana of the lyrics, which the payload omits', () {
      final lines = [const QqKanaLine('青い風'), const QqKanaLine('テスト')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1あお1かぜ'),
      );

      expect(_render(lines[0].text, annotations[0]), '[あお]い[かぜ]');
      expect(annotations[1], isEmpty);
    });

    test('a compound run covers several kanji with one reading', () {
      final lines = [const QqKanaLine('今日雨')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('2きょう1あめ'),
      );

      expect(_render(lines[0].text, annotations[0]), '[きょう][あめ]');
    });

    test('starts the lyrics after payload entries the caller trimmed away', () {
      // The payload also covers the credit lines; only the lyrics are passed.
      final lines = [const QqKanaLine('青い風')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1し1きょく1へん1きょく1あお1かぜ'),
      );

      expect(_render(lines[0].text, annotations[0]), '[あお]い[かぜ]');
    });

    test('uses the kana timings to pick between plausible offsets', () {
      final lines = [
        const QqKanaLine('青葉花子', startMs: 0, endMs: 1000),
        const QqKanaLine('本当', startMs: 1000, endMs: 2000),
      ];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1あお1ば1はな1こ1ほん(1500,200)1とう'),
      );

      expect(_render(lines[0].text, annotations[0]), '[あお][ば][はな][こ]');
      expect(_render(lines[1].text, annotations[1]), '[ほん][とう]');
    });

    test('does not annotate when the payload cannot cover the lyrics', () {
      final lines = [const QqKanaLine('青葉花子')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1あお1ば'),
      );

      expect(annotations.single, isEmpty);
    });
  });

  group('runs without a reading', () {
    test('are dropped instead of blocking the alignment', () {
      // `1し1111きょく` is 詞(し), three padding entries for the latin after
      // the colon, then 曲(きょく).
      final runs = QqKanaHelper.parseRuns('1し1111きょく');
      expect(runs.map((r) => r.reading), ['し', 'きょく']);

      final lines = [const QqKanaLine('詞：Abc1 曲：Abc1')];
      final annotations = QqKanaHelper.annotateLines(lines: lines, runs: runs);
      expect(_render(lines[0].text, annotations[0]), '[し]：Abc1 [きょく]：Abc1');
    });
  });

  group('a payload with credits, timings and a compound', () {
    final runs = QqKanaHelper.parseRuns(_demoKana);
    final lines = [
      for (final (start, end, text) in _demoLines)
        QqKanaLine(text, startMs: start, endMs: end),
    ];

    test('parses every run with its kanji count', () {
      expect(runs.length, 15);
      expect(runs.fold<int>(0, (sum, r) => sum + r.kanjiCount), 16);
      expect(runs[7].kanjiCount, 2);
      expect(runs[7].reading, 'きょう');
    });

    test('annotates the lyrics per kanji, after the credit lines', () {
      final annotations = QqKanaHelper.annotateLines(lines: lines, runs: runs);

      // The credit lines are covered by the payload's head, so the lyrics
      // start at offset 4 and every line lines up.
      expect(_render(lines[4].text, annotations[4]), '[あお]い[かぜ]で[はし]るテスト');
      expect(_render(lines[5].text, annotations[5]), '[きょう][なに][み]た?');
      expect(_render(lines[6].text, annotations[6]), '「[はな]が[さ]く[よる]なんて');
      expect(_render(lines[7].text, annotations[7]), '[ぼく]は[し]らなくてさ」');
    });
  });

  group('a payload whose credits use padding digits', () {
    // Lyrics the runtime sees: the credit lines are trimmed away, while the
    // payload still starts at them.
    final runs = QqKanaHelper.parseRuns(_paddedKana);
    final lines = [
      for (final (start, end, text) in _paddedLines)
        QqKanaLine(text, startMs: start, endMs: end),
    ];
    final displayed = lines.sublist(4);
    final annotations = QqKanaHelper.annotateLines(
      lines: displayed,
      runs: runs,
    );

    test('also aligns when the caller keeps the credit lines', () {
      final untrimmed = QqKanaHelper.annotateLines(lines: lines, runs: runs);
      expect(_render(lines[1].text, untrimmed[1]), '[し]：Abc1');
      expect(_render(lines[3].text, untrimmed[3]), '[へん][きょく]：Abc1');
      expect(
        _render(lines[4].text, untrimmed[4]),
        '[あお]い[ひ]が[ひか]ったのは[ひと]つの[お]わり',
      );
    });

    test('parses the single digit counts and skips the padding', () {
      expect(runs.length, 21);
      expect(runs.fold<int>(0, (sum, r) => sum + r.kanjiCount), 22);
      expect(runs.take(4).map((r) => r.reading), ['し', 'きょく', 'へん', 'きょく']);
      expect(runs[19].kanjiCount, 2);
      expect(runs[19].reading, 'はなび');
    });

    test('annotates the lyrics from the payload offset the credits end at', () {
      expect(
        _render(displayed[0].text, annotations[0]),
        '[あお]い[ひ]が[ひか]ったのは[ひと]つの[お]わり',
      );
      expect(
        _render(displayed[2].text, annotations[2]),
        '[みぎ][あし]で[ひと][り][ある]く まるでテスト',
      );
      expect(_render(displayed[3].text, annotations[3]), '[む][だ]な[はなび]は[み]ない');
      expect(_render(displayed.last.text, annotations.last), 'そのままね');
    });
  });
}
