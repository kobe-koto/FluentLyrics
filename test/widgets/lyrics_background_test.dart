import 'dart:convert';
import 'dart:typed_data';

import 'package:fluent_lyrics/widgets/screen/lyrics/lyrics_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _testImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==',
);
final MemoryImage _testImageProvider = MemoryImage(_testImageBytes);

void main() {
  testWidgets('static background remains calm when motion is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(motionEnabled: false, animate: false),
    );
    await tester.pump();

    final initialAlignments = _readAlignments(tester);

    await tester.pump(const Duration(seconds: 5));

    expect(_readAlignments(tester), initialAlignments);
  });

  testWidgets('motion background continues evolving over time', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness(motionEnabled: true, animate: true));
    await tester.pump();

    final initialAlignments = _readAlignments(tester);

    await tester.pump(const Duration(seconds: 5));

    expect(_readAlignments(tester), isNot(initialAlignments));
  });

  testWidgets(
    'motion background freezes on pause and resumes from that frame',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(motionEnabled: true, animate: true),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      final liveAlignments = _readAlignments(tester);

      await tester.pumpWidget(
        _buildHarness(motionEnabled: true, animate: false),
      );
      await tester.pump();
      final pausedAlignments = _readAlignments(tester);

      expect(pausedAlignments, liveAlignments);

      await tester.pump(const Duration(seconds: 3));
      expect(_readAlignments(tester), pausedAlignments);

      await tester.pumpWidget(
        _buildHarness(motionEnabled: true, animate: true),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(_readAlignments(tester), isNot(pausedAlignments));
    },
  );
}

Widget _buildHarness({required bool motionEnabled, required bool animate}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox.expand(
        child: LyricsBackground(
          artProvider: _testImageProvider,
          motionEnabled: motionEnabled,
          animate: animate,
        ),
      ),
    ),
  );
}

List<(double, double)> _readAlignments(WidgetTester tester) {
  final alignFinder = find.descendant(
    of: find.byType(LyricsBackground),
    matching: find.byType(Align),
  );

  return tester
      .widgetList<Align>(alignFinder)
      .map((widget) {
        final alignment = widget.alignment.resolve(TextDirection.ltr);
        return (alignment.x, alignment.y);
      })
      .toList(growable: false);
}
