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
    with SingleTickerProviderStateMixin {
  /// Progress jump (in ms) above which the dots snap instantly instead
  /// of following the smooth interpolation. This catches actual seeks
  /// while ignoring the normal 250ms media-poll interval.
  static const int _snapJumpThresholdMs = 500;

  /// If no real progress update arrives within this window we stop
  /// extrapolating (the media has likely paused or the interlude ended).
  static const Duration _interpolationTimeout = Duration(milliseconds: 500);

  late Ticker _progressTicker;
  bool _snapAnimations = false;

  // — Progress interpolation state —
  /// Notifier carrying the smoothed progress for this interlude.
  /// Using a ValueNotifier instead of setState in the ticker keeps the
  /// indicator's own widget tree (Transform.scale + Row + dots + shadows)
  /// from being rebuilt every frame; only the ListenableBuilder that
  /// actually needs the value rebuilds.
  final ValueNotifier<double> _smoothProgress = ValueNotifier<double>(0.0);
  double _lastRealProgress = 0.0;
  final Stopwatch _interpolationWatch = Stopwatch();
  bool _hasRealProgress = false;

  /// Entrance, 0..1, timed from mount on the same ticker. Wall clock rather
  /// than interlude progress: the row only switches to the indicator on the
  /// next position tick, up to 250ms into the interlude, and a progress based
  /// entrance would already be partly skipped by then.
  final ValueNotifier<double> _enter = ValueNotifier<double>(0.0);

  late final Listenable _frame = Listenable.merge([_smoothProgress, _enter]);

  @override
  void initState() {
    super.initState();
    _progressTicker = createTicker(_onProgressTick)..start();

    // Seed interpolation from the initial progress so the Ticker can advance
    // smoothly even before the first real position update arrives.
    _lastRealProgress = widget.progress;
    _smoothProgress.value = widget.progress;
    _interpolationWatch.start();
    _hasRealProgress = true;
  }

  void _onProgressTick(Duration elapsed) {
    final enterMs = InterludeIndicatorHelper.enterDurationForDuration(
      widget.duration,
    ).inMilliseconds;
    _enter.value = enterMs <= 0
        ? 1.0
        : (elapsed.inMilliseconds / enterMs).clamp(0.0, 1.0);

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
    _smoothProgress.value = next;
  }

  @override
  void didUpdateWidget(covariant InterludeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldSnapForProgressJump(oldWidget)) {
      _enableSnapAnimationsForFrame();
    }
    // Re-anchor interpolation on every real position update.
    _lastRealProgress = widget.progress;
    _interpolationWatch
      ..reset()
      ..start();
    _hasRealProgress = true;
  }

  @override
  void dispose() {
    _progressTicker.dispose();
    _smoothProgress.dispose();
    _enter.dispose();
    super.dispose();
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    // The indicator takes the size it is given (the lyric row it overlays)
    // and never sizes the row itself. Everything that depends on progress or
    // the entrance is rebuilt by the inner ListenableBuilder, so a frame only
    // repaints the dots and the two Transform.scales.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ListenableBuilder(
          listenable: _frame,
          builder: (context, _) {
            final progress = _smoothProgress.value;
            final enter = Curves.easeOutCubic.transform(_enter.value);
            final targetScale = InterludeIndicatorHelper.targetScale(
              progress: progress,
              duration: widget.duration,
            );
            final targetOpacity = InterludeIndicatorHelper.targetOpacity(
              progress: progress,
              duration: widget.duration,
            );
            final breathingScale = InterludeIndicatorHelper.breathingScale(
              progress: progress,
              duration: widget.duration,
            );

            const enterStartScale = InterludeIndicatorHelper.enterStartScale;
            final enterScale =
                enterStartScale + (1.0 - enterStartScale) * enter;

            return Transform.scale(
              scale: targetScale * enterScale,
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: targetOpacity * enter,
                child: Transform.scale(
                  scale: breathingScale,
                  alignment: Alignment.center,
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
