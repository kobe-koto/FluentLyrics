import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int shrinkDuration = 200;
    const double overlap = 0.3; // How much the next dot overlaps (0.0 to 1.0)
    final double totalDotWindow =
        1 - ((shrinkDuration + 150) / widget.duration.inMilliseconds);

    final double step = 1 - overlap;
    final double d = totalDotWindow / (2 * step + 1);

    // Calculate duration for each dot's animation
    final dotDuration = Duration(
      milliseconds: (d * totalDotWindow * widget.duration.inMilliseconds)
          .round(),
    );

    // Target scale for the entire widget
    double targetScale = 1.0;
    const double swellScale = 1.15;
    const int swellDuration = 250;
    final double swellStart =
        totalDotWindow - (swellDuration / widget.duration.inMilliseconds);

    if (widget.progress >= totalDotWindow) {
      targetScale =
          ((1.0 - widget.progress) / (1.0 - totalDotWindow)).clamp(0.0, 1.0) *
          swellScale;
    } else if (widget.progress >= swellStart) {
      // stop breathing animation when swell
      _breathingController.stop();
      final double swellProgress =
          (widget.progress - swellStart) / (totalDotWindow - swellStart);
      targetScale = 1.0 + (swellScale - 1.0) * swellProgress.clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.centerLeft,
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: shrinkDuration),
        curve: Curves.easeInCirc,
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: targetScale.clamp(0.0, 1.0),
          duration: const Duration(milliseconds: shrinkDuration),
          child: AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathingAnimation.value,
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(
                  progress: (widget.progress / d).clamp(0.0, 1.0),
                  duration: dotDuration,
                ),
                _AnimatedDot(
                  progress: ((widget.progress - (step * d)) / d).clamp(
                    0.0,
                    1.0,
                  ),
                  duration: dotDuration,
                ),
                _AnimatedDot(
                  progress: ((widget.progress - (2 * step * d)) / d).clamp(
                    0.0,
                    1.0,
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
