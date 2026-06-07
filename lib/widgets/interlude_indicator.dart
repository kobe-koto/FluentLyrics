import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/interlude_indicator_helper.dart';

class InterludeIndicator extends StatefulWidget {
  final double progress;
  final Duration duration;
  const InterludeIndicator({
    super.key,
    required this.progress,
    required this.duration,
  });

  @override
  State<InterludeIndicator> createState() => _InterludeIndicatorState();
}

class _InterludeIndicatorState extends State<InterludeIndicator>
    with TickerProviderStateMixin {
  /// Progress jump (in ms) above which the dots snap instantly instead
  /// of following the smooth interpolation. This catches actual seeks
  /// while ignoring the normal 250ms media-poll interval.
  static const int _snapJumpThresholdMs = 500;

  /// If no real progress update arrives within this window we stop
  /// extrapolating (the media has likely paused or the interlude ended).
  static const Duration _interpolationTimeout = Duration(milliseconds: 500);

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late Ticker _progressTicker;
  bool _snapAnimations = false;

  // — Progress interpolation state —
  /// Notifier carrying the smoothed progress for this interlude.
  /// Using a ValueNotifier instead of setState in the ticker keeps the
  /// indicator's own widget tree (Transform.scale + Row + dots + shadows)
  /// from being rebuilt every frame; only the ValueListenableBuilders that
  /// actually need the value rebuild.
  final ValueNotifier<double> _smoothProgress = ValueNotifier<double>(0.0);
  double _lastRealProgress = 0.0;
  final Stopwatch _interpolationWatch = Stopwatch();
  bool _hasRealProgress = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: _effectiveBreathingCycleDuration,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _progressTicker = createTicker(_onProgressTick)..start();

    // Seed interpolation from the initial progress so the Ticker can advance
    // smoothly even before the first real position update arrives.
    _lastRealProgress = widget.progress;
    _smoothProgress.value = widget.progress;
    _interpolationWatch.start();
    _hasRealProgress = true;

    _syncBreathingAnimation();
  }

  void _onProgressTick(Duration elapsed) {
    final double next;
    if (widget.duration.inMilliseconds <= 0) {
      next = widget.progress;
    } else if (_snapAnimations) {
      next = widget.progress;
    } else if (_hasRealProgress) {
      final wallElapsed = _interpolationWatch.elapsed;
      if (wallElapsed > _interpolationTimeout) {
        next = _lastRealProgress;
      } else {
        final delta =
            wallElapsed.inMilliseconds / widget.duration.inMilliseconds;
        next = (_lastRealProgress + delta).clamp(0.0, 1.0);
      }
    } else {
      next = widget.progress;
    }
    if (_smoothProgress.value != next) {
      _smoothProgress.value = next;
      // Update breathing animation state if the phase boundary was crossed.
      _syncBreathingAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant InterludeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldSnapForProgressJump(oldWidget)) {
      _enableSnapAnimationsForFrame();
    }
    if (oldWidget.duration != widget.duration) {
      _breathingController.duration = _effectiveBreathingCycleDuration;
    }
    // Re-anchor interpolation on every real position update.
    _lastRealProgress = widget.progress;
    _interpolationWatch
      ..reset()
      ..start();
    _hasRealProgress = true;
    _syncBreathingAnimation();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _progressTicker.dispose();
    _smoothProgress.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Breathing helpers
  // ---------------------------------------------------------------------------

  void _syncBreathingAnimation() {
    if (!_isBreathingPhase) {
      if (_breathingController.isAnimating) {
        _breathingController.stop();
      }
    } else if (!_breathingController.isAnimating) {
      _breathingController.repeat(reverse: true);
    }
  }

  bool _shouldSnapForProgressJump(InterludeIndicator oldWidget) {
    if (oldWidget.duration != widget.duration) return true;

    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) return false;

    final jumpedMs = (widget.progress - oldWidget.progress).abs() * durationMs;
    return jumpedMs >= _snapJumpThresholdMs;
  }

  void _enableSnapAnimationsForFrame() {
    if (_snapAnimations) return;
    setState(() {
      _snapAnimations = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_snapAnimations) return;
      setState(() {
        _snapAnimations = false;
      });
    });
  }

  Duration get _effectiveBreathingCycleDuration {
    final duration = InterludeIndicatorHelper.breathingCycleDurationForDuration(
      widget.duration,
    );
    return duration == Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
  }

  bool get _isBreathingPhase {
    return InterludeIndicatorHelper.isBreathingPhase(
      progress: _smoothProgress.value,
      duration: widget.duration,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    // The fixed outer footprint (padding + alignment) is set up here once.
    // Everything inside that depends on smoothProgress is rebuilt by the
    // inner ValueListenableBuilder, so a position tick only repaints the
    // dots + the two Transform.scales -- not the surrounding row, padding,
    // breathing controller, or AnimatedDot SizedBox.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ValueListenableBuilder<double>(
          valueListenable: _smoothProgress,
          builder: (context, progress, _) {
            final targetScale = InterludeIndicatorHelper.targetScale(
              progress: progress,
              duration: widget.duration,
            );
            final targetOpacity = InterludeIndicatorHelper.targetOpacity(
              progress: progress,
              duration: widget.duration,
            );
            final isBreathing = InterludeIndicatorHelper.isBreathingPhase(
              progress: progress,
              duration: widget.duration,
            );

            return Transform.scale(
              scale: targetScale,
              alignment: isBreathing ? Alignment.center : Alignment.centerLeft,
              child: Opacity(
                opacity: targetOpacity,
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isBreathing ? _breathingAnimation.value : 1.0,
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedDot(
                        key: const ValueKey('interlude_dot_0'),
                        progress: InterludeIndicatorHelper.dotProgress(
                          progress: progress,
                          dotIndex: 0,
                          duration: widget.duration,
                        ),
                        lastDot: false,
                      ),
                      _AnimatedDot(
                        key: const ValueKey('interlude_dot_1'),
                        progress: InterludeIndicatorHelper.dotProgress(
                          progress: progress,
                          dotIndex: 1,
                          duration: widget.duration,
                        ),
                        lastDot: false,
                      ),
                      _AnimatedDot(
                        key: const ValueKey('interlude_dot_2'),
                        progress: InterludeIndicatorHelper.dotProgress(
                          progress: progress,
                          dotIndex: 2,
                          duration: widget.duration,
                        ),
                        lastDot: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot
// ---------------------------------------------------------------------------

class _AnimatedDot extends StatelessWidget {
  final double progress;
  final bool lastDot;
  const _AnimatedDot({
    super.key,
    required this.progress,
    required this.lastDot,
  });

  /// Below this progress threshold the glow shadow is effectively invisible
  /// (alpha 0.3 * progress < 0.1, blurRadius < 1.5px). Skipping the shadow
  /// entirely under that threshold avoids per-frame mask regeneration in
  /// Skia for an imperceptible visual.
  static const double _shadowThreshold = 0.15;

  @override
  Widget build(BuildContext context) {
    const double n1 = 8.0; // Base size
    const double n2 = 14.0; // Active size
    const double baseOpacity = 0.15;
    const double activeOpacity = 0.9;

    final double size = n1 + (n2 - n1) * progress;
    final double opacity =
        baseOpacity + (activeOpacity - baseOpacity) * progress;
    final bool showShadow = progress > _shadowThreshold;

    return Padding(
      padding: lastDot ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      // SizedBox here pins the layout footprint to n2 x n2 so the inner
      // size animation cannot bubble into the parent Row's layout.
      child: SizedBox(
        width: n2,
        height: n2,
        child: Center(
          child: Container(
            key: const ValueKey('dot_container'),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: progress * 0.3),
                        blurRadius: 8 * progress,
                        spreadRadius: 1 * progress,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
