import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lyric_model.dart';
import '../providers/lyrics_provider.dart';

class LyricLine extends StatelessWidget {
  final Lyric lyric;
  final bool isHighlighted;
  final double distance; // 0 is current, 1 is adjacent, etc.
  final bool isManualScrolling;
  final bool blurEnabled;

  const LyricLine({
    super.key,
    required this.lyric,
    required this.isHighlighted,
    this.distance = 0,
    this.isManualScrolling = false,
    this.blurEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final fontSize = lyricsProvider.fontSize.current;
    final inactiveScale = lyricsProvider.inactiveScale.current;

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
              child: Builder(
                builder: (context) => _buildText(context, lyricsProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, LyricsProvider lyricsProvider) {
    final text = lyric.text;
    if (!isHighlighted ||
        lyric.inlineParts == null ||
        lyric.inlineParts!.isEmpty) {
      return Text(text, textAlign: TextAlign.left);
    } else if (lyric.inlineParts!.length == 1) {
      return Text(
        lyric.inlineParts!.first.text,
        textAlign: TextAlign.left,
        style: DefaultTextStyle.of(context).style,
      );
    }

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: lyric.inlineParts!.map((part) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _RichPart(
              text: part.text,
              startTime: part.startTime,
              endTime: part.endTime,
              style: DefaultTextStyle.of(context).style,
            ),
          );
        }).toList(),
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _RichPart extends StatefulWidget {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final TextStyle style;

  const _RichPart({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.style,
  });

  @override
  State<_RichPart> createState() => _RichPartState();
}

class _RichPartState extends State<_RichPart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const Duration _defaultProgressAnimationDuration = Duration(
    milliseconds: 350,
  );
  static const Duration _progressAnimationThreshold = Duration(
    milliseconds: 800,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.endTime - widget.startTime,
    );
  }

  @override
  void didUpdateWidget(_RichPart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endTime - widget.startTime !=
        oldWidget.endTime - oldWidget.startTime) {
      _controller.duration = widget.endTime - widget.startTime;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsProvider = context.watch<LyricsProvider>();
    final adjustedPosition =
        lyricsProvider.currentPosition +
        lyricsProvider.globalOffset +
        lyricsProvider.trackOffset;

    final duration = widget.endTime - widget.startTime;

    // Synchronize controller with song position
    if (adjustedPosition < widget.startTime) {
      if (_controller.value != 0) _controller.value = 0;
    } else if (adjustedPosition >= widget.endTime) {
      if (_controller.value != 1) _controller.value = 1;
    } else {
      final durationMs = duration.inMilliseconds;
      if (durationMs > 0) {
        final double targetProgress =
            (adjustedPosition - widget.startTime).inMilliseconds / durationMs;
        // If we are significantly out of sync or just started, snap/animate
        if ((_controller.value - targetProgress).abs() > 0.1) {
          _controller.value = targetProgress;
        }

        if (lyricsProvider.isPlaying) {
          if (!_controller.isAnimating && _controller.value < 1.0) {
            _controller.forward();
          }
        } else {
          if (_controller.isAnimating) _controller.stop();
        }
      } else {
        _controller.value = 1.0;
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final bool isLifting = progress > 0;
        final bool isShort = duration < _progressAnimationThreshold;

        return AnimatedContainer(
          duration: isShort
              ? _defaultProgressAnimationDuration
              : duration + Duration(milliseconds: 150),
          curve: Curves.easeOutQuint,
          transform: Matrix4.translationValues(0, isLifting ? -2 : 0, 0),
          child: Stack(
            children: [
              Text(
                widget.text,
                style: widget.style.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              if (isLifting)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _KaraokeTextPainter(
                      text: widget.text,
                      style: widget.style,
                      progress: isShort ? 1.0 : progress,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KaraokeTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double progress;
  final TextScaler textScaler;

  _KaraokeTextPainter({
    required this.text,
    required this.style,
    required this.progress,
    required this.textScaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );

    textPainter.layout(maxWidth: size.width);

    final lines = textPainter.computeLineMetrics();
    final totalWidth = lines.fold(0.0, (sum, line) => sum + line.width);
    double currentTargetWidth = totalWidth * progress;

    final path = Path();
    double y = 0;

    for (final line in lines) {
      if (currentTargetWidth <= 0) break;

      final lineWidth = line.width;
      final fillWidth = currentTargetWidth >= lineWidth
          ? lineWidth
          : currentTargetWidth;

      path.addRect(Rect.fromLTWH(0, y, fillWidth, line.height));

      currentTargetWidth -= lineWidth;
      y += line.height;
    }

    canvas.save();
    canvas.clipPath(path);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KaraokeTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.progress != progress ||
        oldDelegate.textScaler != textScaler;
  }
}
