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
}
