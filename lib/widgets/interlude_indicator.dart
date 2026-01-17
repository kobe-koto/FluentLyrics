import 'package:flutter/material.dart';

class InterludeIndicator extends StatelessWidget {
  final double progress;
  const InterludeIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    const double overlap = 0.3; // How much the next dot overlaps (0.0 to 1.0)
    const double totalDotWindow = 0.97; // Completion point before exit scale

    final double step = 1 - overlap;
    final double d = totalDotWindow / (2 * step + 1);

    // Target scale for the entire widget
    double targetScale = 1.0;
    if (progress >= totalDotWindow) {
      targetScale = ((1.0 - progress) / (1.0 - totalDotWindow)).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      alignment: Alignment.centerLeft,
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInCubic,
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: targetScale,
          duration: const Duration(milliseconds: 250),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedDot(progress: (progress / d).clamp(0.0, 1.0)),
              _AnimatedDot(
                progress: ((progress - (step * d)) / d).clamp(0.0, 1.0),
              ),
              _AnimatedDot(
                progress: ((progress - (2 * step * d)) / d).clamp(0.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final double progress;
  const _AnimatedDot({required this.progress});

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
            duration: const Duration(milliseconds: 300),
            curve: Curves.linear, // Tracking real progress linearly
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                if (progress > 0.1) // Only show glow when sufficiently active
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
