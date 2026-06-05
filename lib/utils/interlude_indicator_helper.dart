class InterludeIndicatorHelper {
  const InterludeIndicatorHelper._();

  static const int maxBreathingCycleDurationMs = 1350;
  static const int quietGapDurationMs = 150;
  static const int tailSwellDurationMs = 140;
  static const int tailShrinkDurationMs = 160;
  static const int tailDurationMs = tailSwellDurationMs + tailShrinkDurationMs;
  static const double overlap = 0.3;
  static const double swellScale = 1.2;

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
      millisecondsFromEnd: quietGapDurationMs + tailDurationMs,
    );
  }

  static Duration breathingWindowForDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) return Duration.zero;
    final breathingWindowMs =
        duration.inMilliseconds - quietGapDurationMs - tailDurationMs;
    return Duration(
      milliseconds: breathingWindowMs < 0 ? 0 : breathingWindowMs,
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

  static double tailStartForDuration(Duration duration) {
    return _progressFromEnd(
      duration: duration,
      millisecondsFromEnd: tailDurationMs,
    );
  }

  static double swellEndForDuration(Duration duration) {
    return _progressFromEnd(
      duration: duration,
      millisecondsFromEnd: tailShrinkDurationMs,
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
    return ((progress - (dotIndex * step * d)) / d).clamp(0.0, 1.0);
  }

  static double _progressFromEnd({
    required Duration duration,
    required int millisecondsFromEnd,
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
