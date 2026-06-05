import 'package:fluent_lyrics/widgets/interlude_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snaps dots immediately on large progress jumps', (
    tester,
  ) async {
    const duration = Duration(seconds: 5);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.05, duration: duration),
        ),
      ),
    );

    final initialSize = tester.getSize(find.byType(AnimatedContainer).first);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.75, duration: duration),
        ),
      ),
    );

    final snappedSize = tester.getSize(find.byType(AnimatedContainer).first);

    expect(initialSize.width, lessThan(14.0));
    expect(snappedSize.width, 14.0);
    expect(snappedSize.height, 14.0);
  });
}
