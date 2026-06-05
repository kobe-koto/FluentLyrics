import 'package:flutter/material.dart';
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
  static const int _snapJumpThresholdMs = 120;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _snapAnimations = false;

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

    _syncBreathingAnimation();
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
    _syncBreathingAnimation();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

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
      progress: widget.progress,
      duration: widget.duration,
    );
  }

  bool get _isSwellPhase {
    return InterludeIndicatorHelper.isSwellPhase(
      progress: widget.progress,
      duration: widget.duration,
    );
  }

  bool get _isShrinkPhase {
    return InterludeIndicatorHelper.isShrinkPhase(
      progress: widget.progress,
      duration: widget.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    final dotDuration = InterludeIndicatorHelper.dotDurationForDuration(
      widget.duration,
    );
    final targetScale = InterludeIndicatorHelper.targetScale(
      progress: widget.progress,
      duration: widget.duration,
    );
    final targetOpacity = InterludeIndicatorHelper.targetOpacity(
      progress: widget.progress,
      duration: widget.duration,
    );
    final scaleDuration = _isSwellPhase
        ? const Duration(
            milliseconds: InterludeIndicatorHelper.tailSwellDurationMs,
          )
        : _isShrinkPhase
        ? const Duration(
            milliseconds: InterludeIndicatorHelper.tailShrinkDurationMs,
          )
        : Duration.zero;
    final effectiveScaleDuration = _snapAnimations
        ? Duration.zero
        : scaleDuration;
    final effectiveOpacityDuration = _snapAnimations
        ? Duration.zero
        : const Duration(
            milliseconds: InterludeIndicatorHelper.tailShrinkDurationMs,
          );
    final effectiveDotDuration = _snapAnimations ? Duration.zero : dotDuration;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.centerLeft,
      child: AnimatedScale(
        scale: targetScale,
        duration: effectiveScaleDuration,
        curve: Curves.easeInCirc,
        alignment: _isBreathingPhase ? Alignment.center : Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: targetOpacity,
          duration: effectiveOpacityDuration,
          child: AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isBreathingPhase ? _breathingAnimation.value : 1.0,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(
                  progress: InterludeIndicatorHelper.dotProgress(
                    progress: widget.progress,
                    dotIndex: 0,
                    duration: widget.duration,
                  ),
                  duration: effectiveDotDuration,
                  lastDot: false,
                ),
                _AnimatedDot(
                  progress: InterludeIndicatorHelper.dotProgress(
                    progress: widget.progress,
                    dotIndex: 1,
                    duration: widget.duration,
                  ),
                  duration: effectiveDotDuration,
                  lastDot: false,
                ),
                _AnimatedDot(
                  progress: InterludeIndicatorHelper.dotProgress(
                    progress: widget.progress,
                    dotIndex: 2,
                    duration: widget.duration,
                  ),
                  duration: effectiveDotDuration,
                  lastDot: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final double progress;
  final Duration duration;
  final bool lastDot;
  const _AnimatedDot({
    required this.progress,
    required this.duration,
    required this.lastDot,
  });

  @override
  Widget build(BuildContext context) {
    const double n1 = 8.0; // Base size
    const double n2 = 14.0; // Active size
    const double baseOpacity = 0.15;
    const double activeOpacity = 0.9;

    final double size = n1 + (n2 - n1) * progress;
    final double opacity =
        baseOpacity + (activeOpacity - baseOpacity) * progress;

    return Padding(
      padding: lastDot ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: n2,
        height: n2,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic, // slow to fast
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: progress * 0.3),
                  blurRadius: 8 * progress,
                  spreadRadius: 1 * progress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
