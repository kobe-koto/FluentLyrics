import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/widgets/lyric_line.dart';
import 'package:flutter/material.dart';
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
}
