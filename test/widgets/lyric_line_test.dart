import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/widgets/lyric_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildHarness({
  required bool isHighlighted,
  bool translationHighlightOnly = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: LyricLine(
        lyric: Lyric(
          startTime: Duration.zero,
          text: 'Hello',
          translation: '你好',
        ),
        isHighlighted: isHighlighted,
        isPrerendered: false,
        fontSize: 36,
        inactiveScale: 0.85,
        translationHighlightOnly: translationHighlightOnly,
        experimentalRichInlineFontSizeGlitching: false,
        adjustedPosition: Duration.zero,
        isPlaying: false,
      ),
    ),
  );
}

Widget _buildRichHarness({
  required Duration richSyncThreshold,
  required Duration partDuration,
}) {
  final parts = [
    LyricInlinePart(
      startTime: Duration.zero,
      endTime: partDuration,
      text: 'Hello ',
    ),
    LyricInlinePart(
      startTime: partDuration,
      endTime: partDuration * 2,
      text: 'world',
    ),
  ];
  return MaterialApp(
    home: Scaffold(
      body: LyricLine(
        lyric: Lyric(
          startTime: Duration.zero,
          text: 'Hello world',
          inlineParts: parts,
        ),
        isHighlighted: true,
        isPrerendered: false,
        fontSize: 36,
        inactiveScale: 0.85,
        translationHighlightOnly: true,
        experimentalRichInlineFontSizeGlitching: false,
        adjustedPosition: partDuration,
        isPlaying: false,
        richSyncThreshold: richSyncThreshold,
      ),
    ),
  );
}

Widget _buildAnnotatedHarness({required List<FuriganaAnnotation> annotations}) {
  return MaterialApp(
    home: Scaffold(
      body: LyricLine(
        lyric: Lyric(
          startTime: Duration.zero,
          text: '沈むように溶けて',
          annotations: annotations,
        ),
        isHighlighted: true,
        isPrerendered: false,
        fontSize: 36,
        inactiveScale: 0.85,
        translationHighlightOnly: true,
        experimentalRichInlineFontSizeGlitching: false,
        adjustedPosition: Duration.zero,
        isPlaying: false,
      ),
    ),
  );
}

Widget _buildRichAnnotatedHarness() {
  // Two word level parts; the first one is long enough to show the progress
  // wipe that marks a rich sync line.
  return MaterialApp(
    home: Scaffold(
      body: LyricLine(
        lyric: Lyric(
          startTime: Duration.zero,
          text: '矛盾に不純',
          inlineParts: [
            LyricInlinePart(
              startTime: Duration.zero,
              endTime: const Duration(seconds: 3),
              text: '矛盾に',
            ),
            LyricInlinePart(
              startTime: const Duration(seconds: 3),
              endTime: const Duration(seconds: 6),
              text: '不純',
            ),
          ],
          annotations: const [
            FuriganaAnnotation(start: 0, end: 2, reading: 'むじゅん'),
          ],
        ),
        isHighlighted: true,
        isPrerendered: false,
        fontSize: 36,
        inactiveScale: 0.85,
        translationHighlightOnly: true,
        experimentalRichInlineFontSizeGlitching: false,
        adjustedPosition: const Duration(seconds: 1),
        isPlaying: false,
      ),
    ),
  );
}

Widget _buildMultiPartAnnotatedHarness() {
  // 最低 / 界隈 are separate rich parts but one kanji run (さいていかいわい).
  return MaterialApp(
    home: Scaffold(
      body: LyricLine(
        // Position past every part's start so all of them are in the same
        // (lifted) state and their glyph positions are comparable.
        adjustedPosition: const Duration(seconds: 5),
        lyric: Lyric(
          startTime: Duration.zero,
          text: '最低界隈です',
          inlineParts: [
            LyricInlinePart(
              startTime: Duration.zero,
              endTime: const Duration(seconds: 2),
              text: '最低',
            ),
            LyricInlinePart(
              startTime: const Duration(seconds: 2),
              endTime: const Duration(seconds: 4),
              text: '界隈',
            ),
            LyricInlinePart(
              startTime: const Duration(seconds: 4),
              endTime: const Duration(seconds: 6),
              text: 'です',
            ),
          ],
          annotations: const [
            FuriganaAnnotation(start: 0, end: 4, reading: 'さいていかいわい'),
          ],
        ),
        isHighlighted: true,
        isPrerendered: false,
        fontSize: 36,
        inactiveScale: 0.85,
        translationHighlightOnly: true,
        experimentalRichInlineFontSizeGlitching: false,
        isPlaying: false,
      ),
    ),
  );
}

void main() {
  testWidgets('translation animates out instead of being removed immediately', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(isHighlighted: true));

    expect(find.text('你好'), findsOneWidget);

    await tester.pumpWidget(_buildHarness(isHighlighted: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('你好'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('你好'), findsNothing);
  });

  testWidgets('rich sync threshold gates the per-word progress wipe', (
    tester,
  ) async {
    // Segment longer than the threshold: the progress wipe (ShaderMask) runs.
    await tester.pumpWidget(
      _buildRichHarness(
        richSyncThreshold: const Duration(milliseconds: 100),
        partDuration: const Duration(milliseconds: 300),
      ),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsWidgets);

    // Same segment, threshold above it: rendered as a whole, no wipe.
    await tester.pumpWidget(
      _buildRichHarness(
        richSyncThreshold: const Duration(milliseconds: 800),
        partDuration: const Duration(milliseconds: 300),
      ),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('renders kanji readings as ruby text', (tester) async {
    await tester.pumpWidget(
      _buildAnnotatedHarness(
        annotations: const [
          FuriganaAnnotation(start: 0, end: 1, reading: 'しず'),
          FuriganaAnnotation(start: 5, end: 6, reading: 'と'),
        ],
      ),
    );
    await tester.pump();

    // The reading sits above the annotated run, the run itself stays in place.
    expect(find.text('しず'), findsOneWidget);
    expect(find.text('と'), findsOneWidget);
    expect(find.text('沈'), findsOneWidget);
    expect(find.text('溶'), findsOneWidget);

    final readingRect = tester.getRect(find.text('しず'));
    final kanjiRect = tester.getRect(find.text('沈'));
    expect(readingRect.bottom, lessThanOrEqualTo(kanjiRect.top));
  });

  testWidgets('keeps the annotated kanji on the text baseline', (tester) async {
    await tester.pumpWidget(
      _buildAnnotatedHarness(
        annotations: const [
          FuriganaAnnotation(start: 0, end: 1, reading: 'しず'),
        ],
      ),
    );
    await tester.pump();

    // The ruby placeholder must not push the base below the line: its bottom
    // has to match the kana that follows, with the reading stacked above.
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText).first,
    );
    final rubyBox = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first;
    final kanaBox = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 1, extentOffset: 2),
        )
        .first;
    expect((rubyBox.bottom - kanaBox.bottom).abs(), lessThan(2.0));

    final reading = tester.getRect(find.text('しず'));
    expect(
      reading.bottom,
      lessThanOrEqualTo(tester.getRect(find.text('沈')).top),
    );
  });

  testWidgets('renders plain text when there are no annotations', (
    tester,
  ) async {
    await tester.pumpWidget(_buildAnnotatedHarness(annotations: const []));
    await tester.pump();

    expect(find.text('沈むように溶けて'), findsOneWidget);
  });

  testWidgets('keeps rich sync while annotating a word', (tester) async {
    await tester.pumpWidget(_buildRichAnnotatedHarness());
    await tester.pump(const Duration(milliseconds: 600));

    // The reading is stacked above its word...
    expect(find.text('むじゅん'), findsOneWidget);
    // ...and the word keeps its rich sync progress wipe.
    expect(find.byType(ShaderMask), findsWidgets);
  });

  testWidgets('does not repeat a reading across the parts it spans', (
    tester,
  ) async {
    await tester.pumpWidget(_buildMultiPartAnnotatedHarness());
    // Let the lift/padding animations settle before measuring positions.
    await tester.pump(const Duration(milliseconds: 600));

    // The run spans 最低 and 界隈: the parts are merged into one rich part, so
    // the reading shows once and the merged word keeps its progress wipe.
    expect(find.text('さいていかいわい'), findsOneWidget);
    // `_RichPart` paints the text twice (base + progress wipe), so the merged
    // word shows up as more than one Text.
    expect(find.text('最低界隈'), findsWidgets);
    expect(find.byType(ShaderMask), findsWidgets);
  });

  testWidgets('aligns annotated and plain rich parts on one baseline', (
    tester,
  ) async {
    await tester.pumpWidget(_buildMultiPartAnnotatedHarness());
    await tester.pump(const Duration(milliseconds: 600));

    // 最低界隈 carries the reading, です does not: their glyph tops must line
    // up, or annotated words look sunk into the line.
    final annotated = tester.getRect(find.text('最低界隈').first);
    final plain = tester.getRect(find.text('です').first);
    expect((annotated.top - plain.top).abs(), lessThan(2.5));
  });
}
