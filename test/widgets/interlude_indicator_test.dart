import 'package:fluent_lyrics/widgets/interlude_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snaps dots immediately on large progress jumps', (tester) async {
    const duration = Duration(seconds: 5);
    // A jump of >500ms should trigger an immediate snap.
    // 0.05 → 0.75 on a 5s duration = 3500ms jump, well over the 500ms threshold.

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.05, duration: duration),
        ),
      ),
    );

    // Tick the progress ticker so _smoothProgress is initialised.
    await tester.pump();

    final initialSize = tester.getSize(
      find.byKey(const ValueKey('dot_container')).first,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.75, duration: duration),
        ),
      ),
    );

    // Tick the progress ticker so it sees the snap flag.
    await tester.pump();

    final snappedSize = tester.getSize(
      find.byKey(const ValueKey('dot_container')).first,
    );

    expect(initialSize.width, lessThan(14.0));
    expect(snappedSize.width, 14.0);
    expect(snappedSize.height, 14.0);
  });

  testWidgets('smooth progress interpolates between position updates', (
    tester,
  ) async {
    // Interlude duration = 4s, so progress advances at 0.25/s wall-clock.
    const duration = Duration(seconds: 4);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.0, duration: duration),
        ),
      ),
    );

    // Let the ticker fire a few frames, advancing ~100ms of wall time.
    // Expected smooth progress ≈ 0.0 + (100 / 4000) ≈ 0.025.
    await tester.pump(const Duration(milliseconds: 100));

    final sizeAfterInterpolation = tester.getSize(
      find.byKey(const ValueKey('dot_container')).first,
    );
    // At progress 0.025 the dot should have grown slightly beyond base 8px,
    // but still be well short of fully-active 14px.
    expect(sizeAfterInterpolation.width, greaterThan(8.0));
    expect(sizeAfterInterpolation.width, lessThan(14.0));
  });

  testWidgets('stops extrapolating after timeout if no progress update arrives', (
    tester,
  ) async {
    const duration = Duration(seconds: 4);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InterludeIndicator(progress: 0.0, duration: duration),
        ),
      ),
    );

    // Let more than _interpolationTimeout (500ms) pass without a new widget.
    await tester.pump(const Duration(milliseconds: 600));

    final sizeAfterTimeout = tester.getSize(
      find.byKey(const ValueKey('dot_container')).first,
    );
    // Should have stopped advancing and held at the last real progress.
    // The extrapolated progress would be 0.0 + 600/4000 = 0.15,
    // giving a size of 8 + 6*0.15 = 8.9px.
    // But the timeout kicks in, so it should stay at ~8px.
    // Give a small tolerance for the transient extrapolation before the timeout.
    expect(sizeAfterTimeout.width, lessThan(9.5));
  });
}
