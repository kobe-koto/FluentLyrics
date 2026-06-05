import 'package:fluent_lyrics/utils/interlude_indicator_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const duration = Duration(seconds: 5);

  test('isSwellPhase returns false for non-positive durations', () {
    expect(
      InterludeIndicatorHelper.isSwellPhase(
        progress: 0.5,
        duration: Duration.zero,
      ),
      isFalse,
    );
  });

  test('dots and breathing end before gap and tail begin', () {
    expect(InterludeIndicatorHelper.totalDotWindowForDuration(duration), 0.91);
    expect(InterludeIndicatorHelper.tailStartForDuration(duration), 0.94);
    expect(InterludeIndicatorHelper.swellEndForDuration(duration), 0.968);
    expect(
      InterludeIndicatorHelper.isBreathingPhase(
        progress: 0.909,
        duration: duration,
      ),
      isTrue,
    );
    expect(
      InterludeIndicatorHelper.isBreathingPhase(
        progress: 0.91,
        duration: duration,
      ),
      isFalse,
    );
    expect(
      InterludeIndicatorHelper.dotProgress(
        progress: 0.949,
        dotIndex: 2,
        duration: duration,
      ),
      1.0,
    );
  });

  test('breathing cycle duration fits an integer count into the breathing window', () {
    expect(
      InterludeIndicatorHelper.breathingWindowForDuration(duration),
      const Duration(milliseconds: 4550),
    );
    expect(
      InterludeIndicatorHelper.breathingCycleDurationForDuration(duration),
      const Duration(milliseconds: 1138),
    );
  });

  test('targetScale stays at one during the quiet gap', () {
    expect(
      InterludeIndicatorHelper.targetScale(
        progress: 0.925,
        duration: duration,
      ),
      1.0,
    );
  });

  test('targetScale swells during tail swell phase', () {
    final scale = InterludeIndicatorHelper.targetScale(
      progress: 0.95,
      duration: duration,
    );

    expect(scale, greaterThan(1.0));
    expect(scale, lessThanOrEqualTo(InterludeIndicatorHelper.swellScale));
  });

  test('targetScale and opacity shrink and fade during tail shrink phase', () {
    final scale = InterludeIndicatorHelper.targetScale(
      progress: 0.98,
      duration: duration,
    );
    final opacity = InterludeIndicatorHelper.targetOpacity(
      progress: 0.98,
      duration: duration,
    );

    expect(scale, lessThan(InterludeIndicatorHelper.swellScale));
    expect(scale, greaterThan(0.0));
    expect(opacity, lessThan(1.0));
    expect(opacity, greaterThan(0.0));
  });

  test('dotProgress offsets each later dot', () {
    final firstDot = InterludeIndicatorHelper.dotProgress(
      progress: 0.2,
      dotIndex: 0,
      duration: duration,
    );
    final secondDot = InterludeIndicatorHelper.dotProgress(
      progress: 0.2,
      dotIndex: 1,
      duration: duration,
    );

    expect(firstDot, greaterThan(secondDot));
  });

  test('dotDurationForDuration returns zero for non-positive durations', () {
    expect(
      InterludeIndicatorHelper.dotDurationForDuration(Duration.zero),
      Duration.zero,
    );
  });
}
