import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../constants/app_defaults.dart';
import '../models/lyric_model.dart';
import '../utils/furigana_helper.dart';
import 'ruby_text.dart';

class LyricLine extends StatelessWidget {
  static const Duration _translationAnimationDuration = Duration(
    milliseconds: 260,
  );
  static const Duration _translationReverseAnimationDuration = Duration(
    milliseconds: 200,
  );

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
  final bool isPrerendered;
  final double distance; // 0 is current, 1 is adjacent, etc.
  final bool isManualScrolling;
  final bool blurEnabled;
  final bool inViewport;
  final double fontSize;
  final double inactiveScale;
  final bool translationHighlightOnly;
  final bool experimentalRichInlineFontSizeGlitching;
  final bool experimentalAnnotationFontSizeGlitching;

  /// Rich-sync word segments shorter than this are rendered as a whole instead
  /// of animating a per-word progress wipe. See `_RichPartState`.
  final Duration richSyncThreshold;
  final Duration adjustedPosition;
  final bool isPlaying;

  const LyricLine({
    super.key,
    required this.lyric,
    required this.isHighlighted,
    required this.isPrerendered,
    required this.fontSize,
    required this.inactiveScale,
    required this.translationHighlightOnly,
    required this.experimentalRichInlineFontSizeGlitching,
    required this.experimentalAnnotationFontSizeGlitching,
    this.richSyncThreshold = const Duration(
      milliseconds: AppDefaults.richSyncThresholdMs,
    ),
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
      fontWeight: FontWeight.w800,
      color: Colors.white,
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                mainText,
                _buildTranslationSwitcher(shouldDisplayTranslation),
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

  Widget _buildTranslationSwitcher(bool shouldDisplayTranslation) {
    final translation = lyric.translation;
    return AnimatedSwitcher(
      duration: _translationAnimationDuration,
      reverseDuration: _translationReverseAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        final children = <Widget>[...previousChildren, ?currentChild];
        if (children.isEmpty) return const SizedBox.shrink();
        return Stack(
          alignment: AlignmentDirectional.topStart,
          children: children,
        );
      },
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: AlignmentDirectional.topStart,
            child: SlideTransition(position: offset, child: child),
          ),
        );
      },
      child: shouldDisplayTranslation
          ? Builder(
              key: ValueKey<String>('translation:$translation'),
              builder: (context) {
                final style = DefaultTextStyle.of(context).style;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    translation!,
                    style: style.copyWith(
                      fontSize: (style.fontSize! * 0.65).roundToDouble(),
                      height: 1.2,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              },
            )
          : const SizedBox.shrink(key: ValueKey<String>('translation:none')),
    );
  }

  /// Ruby for rich (word level) lines.
  ///
  /// An annotated kanji run is rendered as one plain ruby block (`最低界隈` with
  /// さいていかいわい above it) even when the rich sync payload splits it into
  /// several parts: parts cannot share one reading, and repeating the reading
  /// above each of them would print it once per kanji. Everything outside the
  /// annotated runs stays a rich widget, so the progress wipe is kept where it
  /// can be.
  Widget _buildRichAnnotatedText(
    BuildContext context,
    List<FuriganaAnnotation> annotations,
    List<LyricInlinePart> parts,
  ) {
    final text = lyric.text;
    final baseStyle = DefaultTextStyle.of(context).style;
    final annotationStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 36) * 0.42,
      height: 1.0,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
    );
    final richTextStyle = baseStyle.copyWith(
      color: Colors.white,
      fontSize: experimentalRichInlineFontSizeGlitching
          ? (baseStyle.fontSize ?? 36) / 0.9
          : baseStyle.fontSize,
      height: 1.2,
    );

    // Word level ranges in line coordinates. Richify can merge parts from
    // another provider, whose boundaries do not line up, so each part is
    // re-anchored in the line text instead of trusting the running offset.
    final ranges = <({int start, int end, LyricInlinePart part})>[];
    var offset = 0;
    for (final part in parts) {
      var start = offset;
      var end = start + part.text.length;
      final matches =
          start <= text.length &&
          end <= text.length &&
          text.substring(start, end) == part.text;
      if (!matches && part.text.isNotEmpty) {
        final found = text.indexOf(part.text);
        if (found >= 0) {
          start = found;
          end = found + part.text.length;
        }
      }
      ranges.add((start: start, end: end, part: part));
      offset = end;
    }

    final spans = <InlineSpan>[];

    void addRichRange(int from, int to) {
      if (to <= from) return;
      for (final range in ranges) {
        final clipStart = from > range.start ? from : range.start;
        final clipEnd = to < range.end ? to : range.end;
        if (clipEnd <= clipStart) continue;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _RichPart(
              text: text.substring(clipStart, clipEnd),
              startTime: range.part.startTime,
              endTime: range.part.endTime,
              style: richTextStyle,
              adjustedPosition: adjustedPosition,
              isPlaying: isPlaying,
              isHighlighted: isHighlighted,
              richSyncThreshold: richSyncThreshold,
            ),
          ),
        );
      }
    }

    final sorted = [...annotations]..sort((a, b) => a.start.compareTo(b.start));
    var cursor = 0;
    for (final annotation in sorted) {
      final start = annotation.start.clamp(0, text.length);
      final end = annotation.end.clamp(0, text.length);
      if (end <= start) continue;
      addRichRange(cursor, start);
      // The annotated run may span several word level parts; they are merged
      // into one rich part (keeping its style and progress wipe) instead of
      // being flattened to plain text, and the reading is stacked above it.
      final covered = [
        for (final range in ranges)
          if (range.start < end && range.end > start) range,
      ];
      final richBase = _RichPart(
        text: text.substring(start, end),
        startTime: covered.isEmpty
            ? Duration.zero
            : covered.first.part.startTime,
        endTime: covered.isEmpty ? Duration.zero : covered.last.part.endTime,
        style: richTextStyle,
        adjustedPosition: adjustedPosition,
        isPlaying: isPlaying,
        isHighlighted: isHighlighted,
        richSyncThreshold: richSyncThreshold,
      );

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: RubyText(
            reading: Text(
              annotation.reading,
              style: annotationStyle,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            base: richBase,
          ),
        ),
      );
      cursor = end;
    }
    addRichRange(cursor, text.length);

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
      style: baseStyle,
    );
  }

  /// Renders the line as ruby text: each annotated run shows its reading above
  /// the original characters. Flutter has no ruby support, so every run becomes
  /// a [WidgetSpan] holding a two line column.
  Widget _buildAnnotatedText(
    BuildContext context,
    List<FuriganaAnnotation> annotations,
  ) {
    final baseStyle = DefaultTextStyle.of(context).style;
    // On the platforms that shrink the text inside a widget span, the ruby base
    // has to grow the same way the rich parts do, otherwise the annotated kanji
    // print smaller than the kana around them.
    final annotationBaseStyle = experimentalAnnotationFontSizeGlitching
        ? baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 36) / 0.9)
        : null;
    final annotationStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 36) * 0.42,
      height: 1.0,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
    );

    final text = lyric.text;
    final spans = <InlineSpan>[];
    var index = 0;
    for (final annotation in annotations) {
      if (annotation.start > index) {
        spans.add(TextSpan(text: text.substring(index, annotation.start)));
      }
      if (annotation.end > annotation.start) {
        spans.add(
          WidgetSpan(
            // `RubyText` reports the base text's baseline, so the kanji stays
            // exactly on the line's baseline with the reading above it.
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: RubyText(
              reading: Text(
                annotation.reading,
                style: annotationStyle,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
              base: Text(
                text.substring(annotation.start, annotation.end),
                style: annotationBaseStyle,
              ),
            ),
          ),
        );
      }
      index = annotation.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
      style: baseStyle,
    );
  }

  Widget _buildText(BuildContext context) {
    final lyric = this.lyric;
    final shouldBeRichLine = isHighlighted || isPrerendered;
    final text = lyric.text;

    final annotations = lyric.annotations;
    if (annotations != null && annotations.isNotEmpty) {
      // Rich (word level) lines keep their per-word widgets and animations as
      // the base of the ruby, so annotating a line does not drop rich sync.
      final parts = lyric.inlineParts;
      if (shouldBeRichLine && parts != null && parts.length > 1) {
        return _buildRichAnnotatedText(context, annotations, parts);
      }
      return _buildAnnotatedText(context, annotations);
    }
    if (!shouldBeRichLine ||
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
              isHighlighted: isHighlighted,
              richSyncThreshold: richSyncThreshold,
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
  final bool isHighlighted;
  final Duration richSyncThreshold;

  const _RichPart({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.style,
    required this.adjustedPosition,
    required this.isPlaying,
    required this.isHighlighted,
    required this.richSyncThreshold,
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
    milliseconds: 500,
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
            duration < widget.richSyncThreshold ||
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
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 75),
                  opacity: widget.isHighlighted
                      ? (isShort && isLifting)
                            ? 1.0
                            : 0.4
                      : 1.0,
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
