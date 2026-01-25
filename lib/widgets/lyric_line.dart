import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lyrics_provider.dart';

class LyricLine extends StatelessWidget {
  final String text;
  final bool isHighlighted;
  final double distance; // 0 is current, 1 is adjacent, etc.
  final bool isManualScrolling;
  final bool blurEnabled;

  const LyricLine({
    super.key,
    required this.text,
    required this.isHighlighted,
    this.distance = 0,
    this.isManualScrolling = false,
    this.blurEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final fontSize = lyricsProvider.fontSize;
    final inactiveScale = lyricsProvider.inactiveScale;

    // Calculate opacity and blur based on distance
    // Current line (distance 0) has full opacity and no blur.
    // Further lines fade and blur out.
    final double opacity = isHighlighted
        ? 1.0
        : (isManualScrolling
              ? 0.55
              : (0.4 / (distance.abs() * 0.5 + 1)).clamp(0.05, 0.4));
    final double blur = (isHighlighted || isManualScrolling || !blurEnabled)
        ? 0.0
        : (distance.abs() * 1.5).clamp(0.0, 4.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.symmetric(
        vertical: isHighlighted ? 16 : 12,
        horizontal: 24,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        opacity: opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuart,
            scale: isHighlighted ? 1.0 : inactiveScale,
            alignment: Alignment.centerLeft,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: fontSize,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                fontVariations: <FontVariation>[
                  FontVariation('wght', 600),
                  FontVariation('wght', 800),
                ],
                color: Colors.white,
                height: 1.2,
              ),
              child: Text(text, textAlign: TextAlign.left),
            ),
          ),
        ),
      ),
    );
  }
}
