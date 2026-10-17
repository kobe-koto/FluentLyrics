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

  test(
    'breathing cycle duration fits an integer count into the breathing window',
    () {
      expect(
        InterludeIndicatorHelper.breathingWindowForDuration(duration),
        const Duration(milliseconds: 4550),
      );
      expect(
        InterludeIndicatorHelper.breathingCycleDurationForDuration(duration),
        const Duration(milliseconds: 1138),
      );
    },
  );

  test('targetScale stays at one during the quiet gap', () {
    expect(
      InterludeIndicatorHelper.targetScale(progress: 0.925, duration: duration),
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

  test('short interludes scale the tail down instead of dropping the dots', () {
    const short = Duration(milliseconds: 700);
    final dotWindow = InterludeIndicatorHelper.totalDotWindowForDuration(short);

    // The fixed 450ms gap + tail would leave 250ms; capped at 40% it is 280ms.
    expect(dotWindow, closeTo(0.6, 1e-9));
    expect(
      InterludeIndicatorHelper.tailStartForDuration(short),
      greaterThan(dotWindow),
    );
    expect(
      InterludeIndicatorHelper.swellEndForDuration(short),
      greaterThan(InterludeIndicatorHelper.tailStartForDuration(short)),
    );
    expect(
      InterludeIndicatorHelper.dotProgress(
        progress: 0.0,
        dotIndex: 2,
        duration: short,
      ),
      0.0,
    );
    expect(
      InterludeIndicatorHelper.dotProgress(
        progress: dotWindow,
        dotIndex: 2,
        duration: short,
      ),
      closeTo(1.0, 1e-9),
    );
  });

  test('breathing starts and ends at rest and stays within amplitude', () {
    const amplitude = InterludeIndicatorHelper.breathingAmplitude;
    final window = InterludeIndicatorHelper.totalDotWindowForDuration(duration);

    expect(
      InterludeIndicatorHelper.breathingScale(progress: 0, duration: duration),
      1.0,
    );
    expect(
      InterludeIndicatorHelper.breathingScale(
        progress: window - 1e-6,
        duration: duration,
      ),
      closeTo(1.0, 0.001),
    );
    expect(
      InterludeIndicatorHelper.breathingScale(
        progress: window,
        duration: duration,
      ),
      1.0,
    );
    for (var p = 0.0; p < window; p += 0.01) {
      final scale = InterludeIndicatorHelper.breathingScale(
        progress: p,
        duration: duration,
      );
      expect(scale, inInclusiveRange(1 - amplitude, 1 + amplitude));
    }
  });

  test('only interludes long enough to animate are displayed', () {
    expect(
      InterludeIndicatorHelper.shouldDisplay(const Duration(milliseconds: 999)),
      isFalse,
    );
    expect(
      InterludeIndicatorHelper.shouldDisplay(const Duration(seconds: 1)),
      isTrue,
    );
  });

  test('entrance is capped and scales with short interludes', () {
    expect(
      InterludeIndicatorHelper.enterDurationForDuration(duration),
      const Duration(milliseconds: 300),
    );
    expect(
      InterludeIndicatorHelper.enterDurationForDuration(
        const Duration(seconds: 1),
      ),
      const Duration(milliseconds: 250),
    );
    expect(
      InterludeIndicatorHelper.enterDurationForDuration(Duration.zero),
      Duration.zero,
    );
  });
}
