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
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.centerLeft,
      child: AnimatedScale(
        scale: targetScale,
        duration: scaleDuration,
        curve: Curves.easeInCirc,
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: targetOpacity,
          duration: const Duration(
            milliseconds: InterludeIndicatorHelper.tailShrinkDurationMs,
          ),
          child: AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isBreathingPhase ? _breathingAnimation.value : 1.0,
                alignment: Alignment.centerLeft,
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
                  duration: dotDuration,
                ),
                _AnimatedDot(
                  progress: InterludeIndicatorHelper.dotProgress(
                    progress: widget.progress,
                    dotIndex: 1,
                    duration: widget.duration,
                  ),
                  duration: dotDuration,
                ),
                _AnimatedDot(
                  progress: InterludeIndicatorHelper.dotProgress(
                    progress: widget.progress,
                    dotIndex: 2,
                    duration: widget.duration,
                  ),
                  duration: dotDuration,
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
  const _AnimatedDot({required this.progress, required this.duration});

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
      padding: const EdgeInsets.only(right: 12),
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
