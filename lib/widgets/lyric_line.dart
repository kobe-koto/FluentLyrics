import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  final bool experimentalLineWideRichWipe;

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
    required this.experimentalLineWideRichWipe,
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
  /// An annotated kanji run is rendered as one plain ruby block (`青空月光` with
  /// あおぞらげっこう above it) even when the rich sync payload splits it into
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
        if (experimentalLineWideRichWipe) {
          return _buildLineWide(context);
        }
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

    if (experimentalLineWideRichWipe) {
      return _buildLineWide(context);
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

  /// Line-wide rich wipe: one continuous highlight sweep travels across the
  /// whole line instead of each word wiping independently. Each word still
  /// lifts, and the sweep's speed inside a word is governed by that word's
  /// duration (pixel width / duration), so short words light fast and long
  /// ones slow. See [_LineWideRichText].
  Widget _buildLineWide(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style;
    final richTextStyle = baseStyle.copyWith(
      color: Colors.white,
      fontSize: experimentalRichInlineFontSizeGlitching
          ? (baseStyle.fontSize ?? 36) / 0.9
          : baseStyle.fontSize,
      height: 1.2,
    );

    final annotations = lyric.annotations;
    final parts = lyric.inlineParts!;
    List<_LinePartSpec> specs;
    TextStyle? annotationStyle;
    if (annotations != null && annotations.isNotEmpty) {
      annotationStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 36) * 0.42,
        height: 1.0,
        fontWeight: FontWeight.w600,
        color: Colors.white60,
      );
      specs = _lineWideAnnotatedSpecs(annotations, parts);
    } else {
      specs = [
        for (final part in _getMergedInlineParts(parts))
          _LinePartSpec(
            text: part.text,
            startTime: part.startTime,
            endTime: part.endTime,
          ),
      ];
    }

    return _LineWideRichText(
      specs: specs,
      style: richTextStyle,
      annotationStyle: annotationStyle,
      adjustedPosition: adjustedPosition,
      isPlaying: isPlaying,
      isHighlighted: isHighlighted,
    );
  }

  /// Splits the line into [_LinePartSpec]s in reading order, keeping each
  /// word's own timing and attaching a reading to annotated runs. Mirrors the
  /// range anchoring in [_buildRichAnnotatedText].
  List<_LinePartSpec> _lineWideAnnotatedSpecs(
    List<FuriganaAnnotation> annotations,
    List<LyricInlinePart> parts,
  ) {
    final text = lyric.text;
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

    final specs = <_LinePartSpec>[];

    void addRange(int from, int to) {
      if (to <= from) return;
      for (final range in ranges) {
        final clipStart = from > range.start ? from : range.start;
        final clipEnd = to < range.end ? to : range.end;
        if (clipEnd <= clipStart) continue;
        specs.add(
          _LinePartSpec(
            text: text.substring(clipStart, clipEnd),
            startTime: range.part.startTime,
            endTime: range.part.endTime,
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
      addRange(cursor, start);
      final covered = [
        for (final range in ranges)
          if (range.start < end && range.end > start) range,
      ];
      specs.add(
        _LinePartSpec(
          text: text.substring(start, end),
          startTime: covered.isEmpty
              ? Duration.zero
              : covered.first.part.startTime,
          endTime: covered.isEmpty ? Duration.zero : covered.last.part.endTime,
          reading: annotation.reading,
        ),
      );
      cursor = end;
    }
    addRange(cursor, text.length);
    return specs;
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

/// One word of a line-wide rich wipe.
class _LinePartSpec {
  const _LinePartSpec({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.reading,
  });

  final String text;
  final Duration startTime;
  final Duration endTime;

  /// Furigana reading stacked above [text], when this run was annotated.
  final String? reading;
}

/// Pixel box of one spec in the laid-out line, plus its timing. Gaps
/// (whitespace specs) carry [isGap] so the front pauses across them.
class _GeomEntry {
  const _GeomEntry({
    required this.leftX,
    required this.width,
    required this.startTime,
    required this.endTime,
    required this.isGap,
  });

  final double leftX;
  final double width;
  final Duration startTime;
  final Duration endTime;
  final bool isGap;
}

/// Line geometry shared by every [_LineWidePart]: the pixel box of each word in
/// line coordinates and a mapping from playback position to a single sweep
/// front x. Keeping the front and fade in one coordinate space is what makes
/// the wipe continuous across word boundaries instead of restarting per part.
class _LineGeometry {
  const _LineGeometry(this.entries, this.totalWidth);

  final List<_GeomEntry> entries;
  final double totalWidth;

  /// Sweep front, in line pixels, for a playback position. Words already past
  /// contribute their full width; the word under the position contributes a
  /// prorated slice; later words contribute nothing. When the sweep is resting
  /// (next word not started, or line finished) the front sits at the last
  /// completed word's right edge.
  ///
  /// This only drives the *active* word's soft edge and the lift. Whether a
  /// word reads as finished is decided per word from its own timing (see
  /// [_LineWidePart]), so a long gap before the next word cannot leave a
  /// completed word with a parked fade.
  double frontXFor(Duration pos) {
    double front = 0;
    for (final entry in entries) {
      if (entry.isGap) continue;
      if (pos >= entry.endTime) {
        front = entry.leftX + entry.width;
        continue;
      }
      if (pos < entry.startTime) return front;
      final durationMs = (entry.endTime - entry.startTime).inMilliseconds;
      final f = durationMs <= 0
          ? 1.0
          : ((pos - entry.startTime).inMilliseconds / durationMs).clamp(
              0.0,
              1.0,
            );
      return entry.leftX + entry.width * f;
    }
    return front;
  }
}

/// Rich-sync line rendered as a single continuous highlight sweep.
///
/// Unlike [_RichPart], which wipes every word on its own controller, the whole
/// line shares one playback clock and one geometry. The sweep front is a single
/// x position in line pixels ([_LineGeometry.frontXFor]); every word fills left
/// to right as the front passes over it, and the soft leading edge has a fixed
/// pixel width, so the wipe is seamless across word boundaries. A word's fill
/// still advances at its own pixel-width / duration rate (short words light
/// fast, long ones slow) because the front is prorated by each word's timing.
/// Each word also lifts on its own when the front reaches it.
///
/// A [Ticker] interpolates the playback position between the ~250ms media polls
/// so the fill advances smoothly at frame rate. Only [_position] is pushed per
/// frame; the [Text.rich] shape and geometry are built once per line/style, and
/// each [_LineWidePart] subscribes to the position, so a frame repaints just
/// the words whose slice of the front changed.
class _LineWideRichText extends StatefulWidget {
  const _LineWideRichText({
    required this.specs,
    required this.style,
    required this.annotationStyle,
    required this.adjustedPosition,
    required this.isPlaying,
    required this.isHighlighted,
  });

  final List<_LinePartSpec> specs;
  final TextStyle style;
  final TextStyle? annotationStyle;
  final Duration adjustedPosition;
  final bool isPlaying;
  final bool isHighlighted;

  @override
  State<_LineWideRichText> createState() => _LineWideRichTextState();
}

class _LineWideRichTextState extends State<_LineWideRichText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Duration> _position = ValueNotifier<Duration>(
    Duration.zero,
  );
  Duration _anchor = Duration.zero;
  final Stopwatch _watch = Stopwatch();

  String? _geometrySig;
  _LineGeometry _geometry = const _LineGeometry(<_GeomEntry>[], 0);

  @override
  void initState() {
    super.initState();
    _anchor = widget.adjustedPosition;
    _position.value = _anchor;
    _ticker = createTicker(_onTick);
    // Only the highlighted (current) row animates. A prerendered next row would
    // otherwise sweep ahead of being selected whenever playback has already
    // advanced into its word-time range (e.g. the current line overruns).
    if (widget.isPlaying && widget.isHighlighted) {
      _watch.start();
      _ticker.start();
    }
  }

  void _onTick(Duration _) {
    _position.value = _anchor + _watch.elapsed;
  }

  @override
  void didUpdateWidget(_LineWideRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final positionChanged =
        widget.adjustedPosition != oldWidget.adjustedPosition;
    final playbackChanged = widget.isPlaying != oldWidget.isPlaying;

    if (positionChanged) {
      // A real position update (poll / seek / resync): snap to it, then let the
      // ticker extrapolate forward from there while playing.
      _anchor = widget.adjustedPosition;
      _watch
        ..reset()
        ..stop();
      if (widget.isPlaying) {
        _watch.start();
        if (!_ticker.isActive) _ticker.start();
      } else if (_ticker.isActive) {
        _ticker.stop();
      }
      _position.value = _anchor;
      return;
    }

    if (playbackChanged) {
      if (widget.isPlaying) {
        // Resume from the position already on screen, not from the stale anchor,
        // so pausing and playing does not rewind the sweep.
        _anchor = _position.value;
        _watch
          ..reset()
          ..start();
        if (!_ticker.isActive) _ticker.start();
      } else {
        _watch.stop();
        if (_ticker.isActive) _ticker.stop();
      }
      return;
    }

    // Pure rebuild with an unchanged position (viewport flip, ancestor
    // notifyListeners, the resync bridge re-emitting its frozen line-start
    // snapshot): keep the running clock untouched. Re-anchoring here would
    // reset _watch and jump the sweep back to [_anchor] mid-line.
  }

  @override
  void dispose() {
    _ticker.dispose();
    _position.dispose();
    super.dispose();
  }

  /// Measures each spec's pixel box once per line/style/scale change and caches
  /// the resulting [_LineGeometry]. Widths are measured with the same style and
  /// text scaler the parts render with, so the cumulative left offsets match
  /// the paragraph layout.
  void _ensureGeometry(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final fontSize = widget.style.fontSize ?? 36;
    final sig =
        '${scaler.scale(fontSize)}|'
        '${widget.specs.map((s) => s.text).join('\u0001')}';
    if (sig == _geometrySig) return;

    final entries = <_GeomEntry>[];
    var x = 0.0;
    for (final spec in widget.specs) {
      final painter = TextPainter(
        text: TextSpan(text: spec.text, style: widget.style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      entries.add(
        _GeomEntry(
          leftX: x,
          width: painter.width,
          startTime: spec.startTime,
          endTime: spec.endTime,
          isGap: spec.text.trim().isEmpty,
        ),
      );
      x += painter.width;
      painter.dispose();
    }
    _geometry = _LineGeometry(entries, x);
    _geometrySig = sig;
  }

  @override
  Widget build(BuildContext context) {
    _ensureGeometry(context);
    final geometry = _geometry;

    final children = <InlineSpan>[];
    for (var i = 0; i < widget.specs.length; i++) {
      final spec = widget.specs[i];
      if (spec.text.trim().isEmpty) {
        children.add(TextSpan(text: spec.text, style: widget.style));
        continue;
      }
      final entry = geometry.entries[i];
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _LineWidePart(
            spec: spec,
            style: widget.style,
            annotationStyle: widget.annotationStyle,
            position: _position,
            geometry: geometry,
            leftX: entry.leftX,
            width: entry.width,
            isHighlighted: widget.isHighlighted,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Text.rich(TextSpan(children: children), textAlign: TextAlign.left),
    );
  }
}

/// A single word in a [_LineWideRichText]. Subscribes to the shared playback
/// [position], derives the line-wide sweep front from [geometry], and renders
/// its own slice of that one gradient: a dimmed base with a left-to-right lit
/// overlay whose edge and fade are expressed in line pixels, so they line up
/// with the neighbouring words' slices.
class _LineWidePart extends StatelessWidget {
  const _LineWidePart({
    required this.spec,
    required this.style,
    required this.annotationStyle,
    required this.position,
    required this.geometry,
    required this.leftX,
    required this.width,
    required this.isHighlighted,
  });

  final _LinePartSpec spec;
  final TextStyle style;
  final TextStyle? annotationStyle;
  final ValueListenable<Duration> position;
  final _LineGeometry geometry;
  final double leftX;
  final double width;
  final bool isHighlighted;

  /// How long the trailing soft edge takes to slide off a word once that word
  /// finishes with no onward sweep (a gap before the next word, or the line
  /// end). Spreading the [fadePx] overrun over this time animates the gradient
  /// out of view instead of snapping the word to solid.
  static const Duration _finishDuration = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final baseText = Text(spec.text, textAlign: TextAlign.left, style: style);

    // Only the current (highlighted) row sweeps. A prerendered next row is
    // built ahead of being selected; without this guard, once playback runs
    // past this row's word-time range (e.g. the current line overruns its
    // words) the shared front would be > 0 here and the next row would visibly
    // animate before it is the active line. Render it as the plain dim base;
    // the sweep starts fresh when the row actually becomes highlighted.
    if (!isHighlighted) {
      final reading = spec.reading;
      if (reading == null || annotationStyle == null) return baseText;
      return RubyText(
        reading: Text(
          reading,
          style: annotationStyle,
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
        base: baseText,
      );
    }

    // Constant soft-edge width in line pixels keeps the leading fade identical
    // on every word instead of scaling with each word's width.
    final fadePx = (style.fontSize ?? 36) * 0.6;
    final durationMs = (spec.endTime - spec.startTime).inMilliseconds;

    final body = ValueListenableBuilder<Duration>(
      valueListenable: position,
      builder: (context, pos, _) {
        // While the word is active, follow the shared line front so the soft
        // edge crosses word boundaries as one continuous sweep.
        final shared = geometry.frontXFor(pos) - leftX;
        final double frontLocal;
        if (pos < spec.endTime) {
          frontLocal = shared;
        } else {
          // The word is done. The band must clear its right side so it reads as
          // finished. If the shared front has already moved past this word (the
          // next word started and is sweeping on) keep following it, so the
          // seam stays continuous. Otherwise there is nothing to hand off to (a
          // long gap, or the line end): ramp the front from the right edge out
          // to width + fadePx over [_finishDuration], sliding the gradient off
          // instead of snapping. pos advances on the shared ticker, so the ramp
          // animates at frame rate.
          final finishMs = _finishDuration.inMilliseconds;
          final elapsed = (pos - spec.endTime).inMilliseconds;
          final frac = finishMs <= 0
              ? 1.0
              : (elapsed / finishMs).clamp(0.0, 1.0);
          final ramp = width + fadePx * Curves.easeOut.transform(frac);
          frontLocal = shared > ramp ? shared : ramp;
        }
        final bool lifting = isHighlighted && frontLocal > 0;

        return AnimatedContainer(
          duration: Duration(
            milliseconds: durationMs > 0 ? (durationMs * 1.15).round() : 500,
          ),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, lifting ? -1.5 : 0, 0),
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 75),
                opacity: isHighlighted ? 0.4 : 1.0,
                child: baseText,
              ),
              if (frontLocal > 0 && width > 0)
                Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      final totalWidth = bounds.width;
                      if (totalWidth <= 0) {
                        return const LinearGradient(
                          colors: [Colors.transparent, Colors.transparent],
                        ).createShader(bounds);
                      }
                      // Soft edge TRAILS the front: solid white behind
                      // (x < front - fade), a white -> transparent band over
                      // [front - fade, front], transparent ahead. The front is
                      // the transparent end, so a word eases in from its dim
                      // base as the band sweeps across it, instead of showing a
                      // full white -> transparent gradient the instant it starts.
                      //
                      // Continuity: the previous word keeps drawing the band's
                      // left half until the front has moved a full [fadePx] into
                      // this word, so the edge crosses the seam as one gradient.
                      // Finished word with no onward sweep: frontLocal ramps
                      // from the right edge to width + fadePx over
                      // [_finishDuration], sliding the trailing band off the
                      // right side so the word eases to solid instead of
                      // snapping, and stays solid through any gap or line end.
                      final pLeft = frontLocal - fadePx;
                      final pRight = frontLocal;
                      final alignLeft = (pLeft / totalWidth) * 2 - 1;
                      final alignRight = (pRight / totalWidth) * 2 - 1;

                      return LinearGradient(
                        begin: Alignment(alignLeft, 0),
                        end: Alignment(alignRight, 0),
                        colors: const [Colors.white, Colors.transparent],
                      ).createShader(bounds);
                    },
                    child: baseText,
                  ),
                ),
            ],
          ),
        );
      },
    );

    final reading = spec.reading;
    if (reading == null || annotationStyle == null) {
      return body;
    }
    return RubyText(
      reading: Text(
        reading,
        style: annotationStyle,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
      base: body,
    );
  }
}
