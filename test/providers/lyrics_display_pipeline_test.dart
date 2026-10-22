import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/providers/lyrics_display_pipeline.dart';
import 'package:fluent_lyrics/utils/kanji_reading_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a line's annotations as `勇[ゆう]気[き]を見[み]た`.
String _render(Lyric lyric) {
  final annotations = lyric.annotations ?? const [];
  final buffer = StringBuffer();
  var index = 0;
  for (final annotation in annotations) {
    buffer.write(lyric.text.substring(index, annotation.start));
    buffer.write(lyric.text.substring(annotation.start, annotation.end));
    buffer.write('[${annotation.reading}]');
    index = annotation.end;
  }
  buffer.write(lyric.text.substring(index));
  return buffer.toString();
}

LyricsResult _lyrics(String text) => LyricsResult(
  lyrics: [Lyric(startTime: Duration.zero, text: text)],
  source: 'test',
);

/// A kana reading track (NetEase `klyric` style), line-level.
LyricsReading _kanaReading(String reading) => LyricsReading(
  lineType: LyricsReadingType.kana,
  lines: [Lyric(startTime: Duration.zero, text: reading)],
);

List<Lyric> _build(
  LyricsDisplayPipeline pipeline, {
  required LyricsResult lyrics,
  required LyricsReading reading,
  required bool splitEnabled,
  KanjiReadingSplitter? splitter,
}) {
  return pipeline.build(
    lyricsResult: lyrics,
    translationResult: null,
    reading: reading,
    richSyncEnabled: false,
    translationEnabled: false,
    annotationEnabled: true,
    annotationBias: 500,
    kanjiReadingSplitEnabled: splitEnabled,
    kanjiReadingSplitter: splitter,
    zhConversionTarget: 'off',
    zhConversionIgnoredLanguages: const [],
    translationAlignmentThreshold: 50,
    stripTimestamps: false,
  );
}

void main() {
  final splitter = KanjiReadingSplitter(const {
    '勇': ['ユウ'],
    '気': ['キ', 'き'],
  });

  test('without splitting, a kanji run keeps one whole-run annotation', () {
    final pipeline = LyricsDisplayPipeline();
    final result = _build(
      pipeline,
      lyrics: _lyrics('勇気'),
      reading: _kanaReading('ゆうき'),
      splitEnabled: false,
    );
    expect(_render(result.single), '勇気[ゆうき]');
  });

  test('with splitting, the run is divided per kanji', () {
    final pipeline = LyricsDisplayPipeline();
    final result = _build(
      pipeline,
      lyrics: _lyrics('勇気'),
      reading: _kanaReading('ゆうき'),
      splitEnabled: true,
      splitter: splitter,
    );
    expect(_render(result.single), '勇[ゆう]気[き]');
  });

  test(
    'enabling split but passing no splitter falls back to the whole run',
    () {
      final pipeline = LyricsDisplayPipeline();
      final result = _build(
        pipeline,
        lyrics: _lyrics('勇気'),
        reading: _kanaReading('ゆうき'),
        splitEnabled: true,
        splitter: null,
      );
      expect(_render(result.single), '勇気[ゆうき]');
    },
  );

  test('toggling split re-renders rather than returning a stale cache', () {
    final pipeline = LyricsDisplayPipeline();
    final lyrics = _lyrics('勇気');
    final reading = _kanaReading('ゆうき');

    final off = _build(
      pipeline,
      lyrics: lyrics,
      reading: reading,
      splitEnabled: false,
    );
    expect(_render(off.single), '勇気[ゆうき]');

    final on = _build(
      pipeline,
      lyrics: lyrics,
      reading: reading,
      splitEnabled: true,
      splitter: splitter,
    );
    expect(_render(on.single), '勇[ゆう]気[き]');
  });

  test('a QQ kana payload is unaffected by the split setting', () {
    final pipeline = LyricsDisplayPipeline();
    // Real QQ data ships a romaji line track alongside the per-kanji kana
    // payload; the kana payload wins and is already split by its own path.
    final reading = LyricsReading(
      lineType: LyricsReadingType.romaji,
      lines: [Lyric(startTime: Duration.zero, text: 'yuu ki')],
      kanaRaw: '1ゆう1き',
    );
    final withSplit = _build(
      pipeline,
      lyrics: _lyrics('勇気'),
      reading: reading,
      splitEnabled: true,
      splitter: splitter,
    );
    final withoutSplit = _build(
      LyricsDisplayPipeline(),
      lyrics: _lyrics('勇気'),
      reading: reading,
      splitEnabled: false,
    );
    expect(_render(withSplit.single), _render(withoutSplit.single));
    expect(_render(withSplit.single), '勇[ゆう]気[き]');
  });
}
