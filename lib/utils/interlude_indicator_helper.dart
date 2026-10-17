import 'dart:math' as math;

class InterludeIndicatorHelper {
  const InterludeIndicatorHelper._();

  static const int maxBreathingCycleDurationMs = 1350;
  static const int quietGapDurationMs = 150;
  static const int tailSwellDurationMs = 140;
  static const int tailShrinkDurationMs = 160;
  static const int tailDurationMs = tailSwellDurationMs + tailShrinkDurationMs;
  static const double overlap = 0.45;
  static const double swellScale = 1.2;
  static const double breathingAmplitude = 0.04;

  /// The quiet gap and tail together take at most this share of the
  /// interlude. Long interludes keep the fixed timings above; short ones scale
  /// them down so the dots are not squeezed out entirely.
  static const double maxTailShare = 0.4;

  /// Interludes shorter than this stay a blank line. The dots cannot enter,
  /// fill and leave in less without reading as a flash.
  static const int minDisplayDurationMs = 1000;

  static const int maxEnterDurationMs = 300;
  static const double enterShare = 0.25;
  static const double enterStartScale = 0.5;

  static bool shouldDisplay(Duration duration) {
    return duration.inMilliseconds >= minDisplayDurationMs;
  }

  /// Fade and scale in from mount, capped to a share of short interludes.
  static Duration enterDurationForDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) return Duration.zero;
    final ms = (duration.inMilliseconds * enterShare).round();
    return Duration(milliseconds: math.min(ms, maxEnterDurationMs));
  }

  static bool isBreathingPhase({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return false;
    return progress < totalDotWindowForDuration(duration);
  }

  static bool isSwellPhase({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return false;
    final tailStart = tailStartForDuration(duration);
    final swellEnd = swellEndForDuration(duration);
    return progress >= tailStart && progress < swellEnd;
  }

  static bool isShrinkPhase({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return false;
    return progress >= swellEndForDuration(duration);
  }

  static double totalDotWindowForDuration(Duration duration) {
    return _progressFromEnd(
      duration: duration,
      millisecondsFromEnd: _scaledTailMs(
        quietGapDurationMs + tailDurationMs,
        duration,
      ),
    );
  }

  static Duration breathingWindowForDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) return Duration.zero;
    final breathingWindowMs =
        duration.inMilliseconds -
        _scaledTailMs(quietGapDurationMs + tailDurationMs, duration);
    return Duration(
      milliseconds: breathingWindowMs < 0 ? 0 : breathingWindowMs.round(),
    );
  }

  static Duration breathingCycleDurationForDuration(Duration duration) {
    final breathingWindowMs = breathingWindowForDuration(
      duration,
    ).inMilliseconds;
    if (breathingWindowMs <= 0) return Duration.zero;

    final cycleCount = (breathingWindowMs / maxBreathingCycleDurationMs).ceil();
    return Duration(milliseconds: (breathingWindowMs / cycleCount).ceil());
  }

  /// Breathing scale at [progress]. Follows the interlude clock, so it is in
  /// phase however late the indicator mounts. A whole number of half cycles
  /// fits the window, so it starts and ends at 1.0 and the quiet gap picks up
  /// without a snap.
  static double breathingScale({
    required double progress,
    required Duration duration,
  }) {
    if (!isBreathingPhase(progress: progress, duration: duration)) return 1.0;
    final cycleMs = breathingCycleDurationForDuration(duration).inMilliseconds;
    if (cycleMs <= 0) return 1.0;
    final elapsedMs = progress * duration.inMilliseconds;
    return 1.0 + breathingAmplitude * math.sin(math.pi * elapsedMs / cycleMs);
  }

  static double tailStartForDuration(Duration duration) {
    return _progressFromEnd(
      duration: duration,
      millisecondsFromEnd: _scaledTailMs(tailDurationMs, duration),
    );
  }

  static double swellEndForDuration(Duration duration) {
    return _progressFromEnd(
      duration: duration,
      millisecondsFromEnd: _scaledTailMs(tailShrinkDurationMs, duration),
    );
  }

  static Duration dotDurationForDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) return Duration.zero;
    final totalDotWindow = totalDotWindowForDuration(duration);
    if (totalDotWindow <= 0) return Duration.zero;
    final step = 1 - overlap;
    final d = totalDotWindow / (2 * step + 1);
    return Duration(
      milliseconds: (d * totalDotWindow * duration.inMilliseconds).round(),
    );
  }

  static double targetScale({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return 1.0;
    final tailStart = tailStartForDuration(duration);
    final swellEnd = swellEndForDuration(duration);

    if (progress >= swellEnd) {
      return (1.0 - _phaseProgress(progress, start: swellEnd, end: 1.0)) *
          swellScale;
    }

    if (progress >= tailStart) {
      return 1.0 +
          (swellScale - 1.0) *
              _phaseProgress(progress, start: tailStart, end: swellEnd);
    }

    return 1.0;
  }

  static double targetOpacity({
    required double progress,
    required Duration duration,
  }) {
    if (duration.inMilliseconds <= 0) return 0.0;
    final swellEnd = swellEndForDuration(duration);
    if (progress < swellEnd) return 1.0;
    return 1.0 - _phaseProgress(progress, start: swellEnd, end: 1.0);
  }

  static double dotProgress({
    required double progress,
    required int dotIndex,
    required Duration duration,
  }) {
    final totalDotWindow = totalDotWindowForDuration(duration);
    final step = 1 - overlap;
    final d = totalDotWindow / (2 * step + 1);
    if (d <= 0) return 0.0;
    return ((progress - (dotIndex * step * d)) / d).clamp(0.0, 1.0);
  }

  /// [ms] scaled so the quiet gap and tail fit [maxTailShare] of [duration].
  static double _scaledTailMs(int ms, Duration duration) {
    final durationMs = duration.inMilliseconds;
    if (durationMs <= 0) return ms.toDouble();
    const fixedMs = quietGapDurationMs + tailDurationMs;
    final factor = math.min(1.0, durationMs * maxTailShare / fixedMs);
    return ms * factor;
  }

  static double _progressFromEnd({
    required Duration duration,
    required double millisecondsFromEnd,
  }) {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (1 - (millisecondsFromEnd / duration.inMilliseconds)).clamp(
      0.0,
      1.0,
    );
  }

  static double _phaseProgress(
    double progress, {
    required double start,
    required double end,
  }) {
    if (end <= start) return 1.0;
    return ((progress - start) / (end - start)).clamp(0.0, 1.0);
  }
}
