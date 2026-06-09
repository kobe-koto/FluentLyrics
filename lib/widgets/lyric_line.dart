import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/lyric_model.dart';

class LyricLine extends StatelessWidget {
  static final Expando<List<LyricInlinePart>> _mergedInlinePartsCache = Expando(
    'mergedInlineParts',
  );
  static final RegExp _wordOrNumberPattern = RegExp(
    r'[\p{L}\p{N}]',
    unicode: true,
  );
  static final RegExp _bracketOrQuotePattern = RegExp(
    '[()\\[\\]{}<>（）［］｛｝〈〉《》「」『』【】〔〕“”‘’"\']',
  );
  static final RegExp _punctuationOrSymbolPattern = RegExp(
    r'[\p{P}\p{S}]',
    unicode: true,
  );

  final Lyric lyric;
  final bool isHighlighted;
  final double distance; // 0 is current, 1 is adjacent, etc.
  final bool isManualScrolling;
  final bool blurEnabled;
  final bool inViewport;
  final double fontSize;
  final double inactiveScale;
  final bool translationHighlightOnly;
  final bool experimentalRichInlineFontSizeGlitching;
  final Duration adjustedPosition;
  final bool isPlaying;

  const LyricLine({
    super.key,
    required this.lyric,
    required this.isHighlighted,
    required this.fontSize,
    required this.inactiveScale,
    required this.translationHighlightOnly,
    required this.experimentalRichInlineFontSizeGlitching,
    required this.adjustedPosition,
    required this.isPlaying,
    this.distance = 0,
    this.isManualScrolling = false,
    this.blurEnabled = true,
    this.inViewport = true,
  });

  @override
  Widget build(BuildContext context) {
    final lyric = this.lyric;
    final isHighlighted = this.isHighlighted;
    final distance = this.distance;
    final isManualScrolling = this.isManualScrolling;
    final blurEnabled = this.blurEnabled;
    final inViewport = this.inViewport;
    final fontSize = this.fontSize;
    final inactiveScale = this.inactiveScale;
    final translationHighlightOnly = this.translationHighlightOnly;

    final mergedInlineParts = _getMergedInlineParts(lyric.inlineParts ?? []);
    final isRichLine =
        mergedInlineParts.isNotEmpty &&
        lyric.text.trim().isNotEmpty && // empty text check
        mergedInlineParts.length > 1; // multiple parts check

    const double minOpacity = 0.4;

    // Calculate opacity and blur based on distance
    // Current line (distance 0) has full opacity and no blur.
    // Further lines fade and blur out.
    final double opacity =
        !inViewport // not in viewport
        ? minOpacity
        : isHighlighted // highlighted line
        ? 1.0
        : (isManualScrolling
              ? 0.55 // non-highlighted line during manual scrolling
              : (minOpacity / (distance.abs() * 0.5 + 1)).clamp(
                  0.05,
                  minOpacity,
                )); // non-highlighted line
    final double blur = !inViewport
        ? 0.0
        : (isHighlighted || isManualScrolling || !blurEnabled)
        ? 0.0
        : (distance.abs() * 1.5).clamp(0.0, 4.0);

    final bool shouldDisplayTranslation =
        (isHighlighted || !translationHighlightOnly) &&
        lyric.translation != null &&
        lyric.translation!.isNotEmpty;

    final lineStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: fontSize,
      fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
      color: isRichLine && isHighlighted
          ? Colors.white.withAlpha(128)
          : Colors.white,
      height: 1.2,
    );

    final scaledText = AnimatedScale(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      scale: isHighlighted ? 1.0 : inactiveScale,
      alignment: Alignment.centerLeft,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        style: lineStyle,
        child: Builder(
          builder: (context) {
            final mainText = _buildText(context);
            if (!shouldDisplayTranslation) {
              return mainText;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                mainText,
                shouldDisplayTranslation
                    ? const SizedBox(width: double.infinity, height: 8)
                    : const SizedBox(width: double.infinity, height: 0),
                shouldDisplayTranslation
                    ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                        opacity: 1.0,
                        child: Builder(
                          builder: (context) {
                            final style = DefaultTextStyle.of(context).style;
                            return Text(
                              lyric.translation!,
                              style: style.copyWith(
                                fontSize: (style.fontSize! * 0.65)
                                    .roundToDouble(),
                                height: 1.2,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              textAlign: TextAlign.left,
                            );
                          },
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ],
            );
          },
        ),
      ),
    );

    final filteredText = ImageFiltered(
      enabled: blur != 0.0,
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: scaledText,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.symmetric(
        vertical: isHighlighted ? 20 : 12,
        horizontal: 24,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        opacity: opacity,
        child: filteredText,
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final lyric = this.lyric;
    final isHighlighted = this.isHighlighted;
    final text = lyric.text;
    if (!isHighlighted ||
        lyric.inlineParts == null ||
        lyric.inlineParts!.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.left,
        style: DefaultTextStyle.of(context).style,
      );
    } else if (lyric.inlineParts!.length == 1) {
      return Text(
        lyric.inlineParts!.first.text,
        textAlign: TextAlign.left,
        style: DefaultTextStyle.of(context).style,
      );
    }
    final richTextStyle = DefaultTextStyle.of(context).style.copyWith(
      color: Colors.white,
      fontSize: experimentalRichInlineFontSizeGlitching
          ? DefaultTextStyle.of(context).style.fontSize! / 0.9
          : DefaultTextStyle.of(context).style.fontSize!,
      height: 1.2,
    );

    final inlineParts = _getMergedInlineParts(lyric.inlineParts!);

    return Text.rich(
      TextSpan(
        children: inlineParts.map<InlineSpan>((part) {
          if (part.text.trim().isEmpty) {
            return TextSpan(text: part.text, style: richTextStyle);
          }
          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _RichPart(
              text: part.text,
              startTime: part.startTime,
              endTime: part.endTime,
              style: richTextStyle,
              adjustedPosition: adjustedPosition,
              isPlaying: isPlaying,
            ),
          );
        }).toList(),
      ),
      textAlign: TextAlign.left,
    );
  }

  List<LyricInlinePart> _getMergedInlineParts(List<LyricInlinePart> parts) {
    final cached = _mergedInlinePartsCache[parts];
    if (cached != null) {
      return cached;
    }

    final merged = _mergeAttachedPunctuation(parts);
    _mergedInlinePartsCache[parts] = merged;
    return merged;
  }

  List<LyricInlinePart> _mergeAttachedPunctuation(List<LyricInlinePart> parts) {
    if (parts.length < 2) return parts;

    final merged = <LyricInlinePart>[];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final next = i + 1 < parts.length ? parts[i + 1] : null;

      if (_isSingleQuote(part.text) &&
          merged.isNotEmpty &&
          !_isWhitespace(merged.last.text)) {
        final previous = merged.removeLast();
        if (next != null && !_isWhitespace(next.text)) {
          merged.add(
            LyricInlinePart(
              startTime: previous.startTime,
              endTime: _latestEndTime(previous.endTime, next.endTime),
              text: previous.text + part.text + next.text,
            ),
          );
          i++;
        } else {
          merged.add(
            LyricInlinePart(
              startTime: previous.startTime,
              endTime: _latestEndTime(previous.endTime, part.endTime),
              text: previous.text + part.text,
            ),
          );
        }
      } else if (merged.isNotEmpty &&
          _isAttachablePunctuation(part.text) &&
          !_endsWithWhitespace(merged.last.text)) {
        final previous = merged.removeLast();
        merged.add(
          LyricInlinePart(
            startTime: previous.startTime,
            endTime: _latestEndTime(previous.endTime, part.endTime),
            text: previous.text + part.text,
          ),
        );
      } else {
        merged.add(part);
      }
    }

    return merged;
  }

  bool _isSingleQuote(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.split('').every((char) => char == '\'' || char == '’');
  }

  bool _isAttachablePunctuation(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains(_wordOrNumberPattern)) {
      return false;
    }
    if (trimmed.contains(_bracketOrQuotePattern)) {
      return false;
    }
    return trimmed.contains(_punctuationOrSymbolPattern);
  }

  bool _endsWithWhitespace(String text) {
    return text.isNotEmpty && text[text.length - 1].trim().isEmpty;
  }

  bool _isWhitespace(String text) {
    return text.trim().isEmpty;
  }

  Duration _latestEndTime(Duration a, Duration b) {
    return a > b ? a : b;
  }
}

class _RichPart extends StatefulWidget {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final TextStyle style;
  final Duration adjustedPosition;
  final bool isPlaying;

  const _RichPart({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.style,
    required this.adjustedPosition,
    required this.isPlaying,
  });

  @override
  State<_RichPart> createState() => _RichPartState();
}

class _RichPartState extends State<_RichPart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _startTimer;
  bool _hasReachedStartTime = false;
  static const Duration _defaultProgressAnimationDuration = Duration(
    milliseconds: 350,
  );
  static const Duration _progressAnimationThreshold = Duration(
    milliseconds: 800,
  );
  static const Duration _positionResyncThreshold = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.endTime - widget.startTime,
    );
    _syncControllerWithPlayback();
  }

  @override
  void didUpdateWidget(_RichPart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final durationChanged =
        widget.endTime - widget.startTime !=
        oldWidget.endTime - oldWidget.startTime;
    if (durationChanged) {
      _controller.duration = widget.endTime - widget.startTime;
    }

    final timingChanged =
        widget.startTime != oldWidget.startTime ||
        widget.endTime != oldWidget.endTime;
    final playbackChanged = widget.isPlaying != oldWidget.isPlaying;
    final positionDelta = widget.adjustedPosition - oldWidget.adjustedPosition;
    final positionJumped =
        positionDelta < Duration.zero ||
        positionDelta > _positionResyncThreshold;

    if (durationChanged ||
        timingChanged ||
        playbackChanged ||
        positionJumped ||
        !widget.isPlaying) {
      _syncControllerWithPlayback();
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerWithPlayback() {
    _startTimer?.cancel();

    final duration = widget.endTime - widget.startTime;
    final durationMs = duration.inMilliseconds;

    if (durationMs <= 0) {
      if (widget.adjustedPosition < widget.startTime) {
        _hasReachedStartTime = false;
        if (_controller.value != 0) _controller.value = 0;
        if (_controller.isAnimating) _controller.stop();
        if (widget.isPlaying) {
          _startTimer = Timer(widget.startTime - widget.adjustedPosition, () {
            if (!mounted || !widget.isPlaying) return;
            setState(() {
              _hasReachedStartTime = true;
            });
            _controller.value = 1.0;
          });
        }
        return;
      }

      _hasReachedStartTime = true;
      if (_controller.value != 1) _controller.value = 1;
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    if (widget.adjustedPosition < widget.startTime) {
      _hasReachedStartTime = false;
      if (_controller.value != 0) _controller.value = 0;
      if (_controller.isAnimating) _controller.stop();
      if (widget.isPlaying) {
        _startTimer = Timer(widget.startTime - widget.adjustedPosition, () {
          if (!mounted || !widget.isPlaying) return;
          setState(() {
            _hasReachedStartTime = true;
          });
          _controller.value = 0.0;
          _controller.forward();
        });
      }
      return;
    }

    if (widget.adjustedPosition >= widget.endTime) {
      _hasReachedStartTime = true;
      if (_controller.value != 1) _controller.value = 1;
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    _hasReachedStartTime = true;

    final double targetProgress =
        (widget.adjustedPosition - widget.startTime).inMilliseconds /
        durationMs;

    if (!widget.isPlaying) {
      if ((_controller.value - targetProgress).abs() > 0.01) {
        _controller.value = targetProgress;
      }
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    final double diffMs = ((_controller.value - targetProgress) * durationMs)
        .abs();
    if (_controller.value == 0.0 || diffMs > 400) {
      _controller.value = targetProgress;
    }

    if (!_controller.isAnimating && _controller.value < 1.0) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.endTime - widget.startTime;

    final baseText = Text(
      widget.text,
      textAlign: TextAlign.left,
      style: widget.style,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final bool isLifting = _hasReachedStartTime;
        final bool isShort =
            duration < _progressAnimationThreshold ||
            (widget.text.length <= 1 &&
                widget.text.contains(
                  RegExp(r'[\p{P}\p{S}]', unicode: true),
                )); // check for punctuation

        return RepaintBoundary(
          child: AnimatedContainer(
            duration: isShort
                ? _defaultProgressAnimationDuration
                : duration + const Duration(milliseconds: 150),
            curve: Curves.easeOutQuint,
            transform: Matrix4.translationValues(0, isLifting ? -2 : 0, 0),
            child: Stack(
              children: [
                Opacity(
                  opacity: (isShort && isLifting) ? 1.0 : 0.4,
                  child: child!,
                ),
                if (isLifting && !isShort)
                  Positioned.fill(
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect bounds) {
                        if (bounds.width <= 0) {
                          return const LinearGradient(
                            colors: [Colors.transparent, Colors.transparent],
                          ).createShader(bounds);
                        }
                        final totalWidth = bounds.width;
                        final fadeWidth = totalWidth * 0.15;
                        final pRight = totalWidth * progress * 1.15;
                        final pLeft = pRight - fadeWidth;

                        final alignLeft = (pLeft / totalWidth) * 2 - 1;
                        final alignRight = (pRight / totalWidth) * 2 - 1;

                        return LinearGradient(
                          begin: Alignment(alignLeft, 0),
                          end: Alignment(alignRight, 0),
                          colors: const [Colors.white, Colors.transparent],
                        ).createShader(bounds);
                      },
                      child: child, // Uses the exact same cached Text layout
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: baseText,
    );
  }
}
