import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/lyric_model.dart';
import '../../../providers/lyrics_provider.dart';
import '../../lyric_line.dart';
import '../../interlude_indicator.dart';

/// How far outside the visible viewport a line is still considered "in
/// viewport" for animation/blur purposes. Matches the previous behavior of
/// treating any line within 2 of an actually-visible item as in-viewport.
const int _inViewportRadius = 2;

class LyricsList extends StatefulWidget {
  final LyricsProvider provider;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isManualScrolling;
  final Function(int) onUserInteraction;

  /// Called when the viewport size changes (window resize, orientation flip,
  /// pane re-layout). The lyric line widths/heights are now stale so the
  /// embedder should re-anchor to the current index without animation.
  final VoidCallback? onViewportResized;

  const LyricsList({
    super.key,
    required this.provider,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isManualScrolling,
    required this.onUserInteraction,
    this.onViewportResized,
  });

  @override
  State<LyricsList> createState() => _LyricsListState();
}

class _LyricsListState extends State<LyricsList> {
  /// Deduplicated set of indices currently considered in-viewport.
  ///
  /// Driven by [ItemPositionsListener.itemPositions] but only notifies when
  /// the resulting set actually changes, so per-line ValueListenableBuilders
  /// don't rebuild on every scroll tick.
  final _InViewportNotifier _inViewport = _InViewportNotifier();

  /// Viewport size last reported by [LayoutBuilder]. Tracked so the embedder
  /// can be notified once per actual resize (not on every layout pass that
  /// happens to keep the same constraints).
  Size? _lastViewportSize;

  static const Duration _viewportResizeDebounce = Duration(milliseconds: 50);

  Timer? _viewportResizeTimer;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_recomputeViewport);
    // Seed initial value once positions are populated post-mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recomputeViewport();
    });
  }

  @override
  void didUpdateWidget(covariant LyricsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemPositionsListener != widget.itemPositionsListener) {
      oldWidget.itemPositionsListener.itemPositions.removeListener(
        _recomputeViewport,
      );
      widget.itemPositionsListener.itemPositions.addListener(
        _recomputeViewport,
      );
      _recomputeViewport();
    }
  }

  @override
  void dispose() {
    _viewportResizeTimer?.cancel();
    widget.itemPositionsListener.itemPositions.removeListener(
      _recomputeViewport,
    );
    _inViewport.dispose();
    super.dispose();
  }

  void _recomputeViewport() {
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      _inViewport.update(const <int>{});
      return;
    }

    var minIndex = 1 << 30;
    var maxIndex = -(1 << 30);
    for (final pos in positions) {
      if (pos.index < minIndex) minIndex = pos.index;
      if (pos.index > maxIndex) maxIndex = pos.index;
    }
    final lower = minIndex - _inViewportRadius;
    final upper = maxIndex + _inViewportRadius;

    final next = <int>{};
    for (int i = lower; i <= upper; i++) {
      next.add(i);
    }
    _inViewport.update(next);
  }

  /// Called from the LayoutBuilder on every layout pass. Detects an actual
  /// viewport size change (window resize, orientation flip, pane re-layout)
  /// and debounces [onViewportResized]. Skipped on the first pass so we don't
  /// fire on mount.
  void _handleConstraints(BoxConstraints constraints) {
    final size = constraints.biggest;
    // Ignore unbounded / not-yet-laid-out constraints.
    if (!size.isFinite) return;
    final previous = _lastViewportSize;
    if (previous == null) {
      _lastViewportSize = size;
      return;
    }
    if (previous == size) return;
    _lastViewportSize = size;
    _scheduleResnap();
  }

  /// Coalesce a burst of resize-driven layouts into a single resnap.
  void _scheduleResnap() {
    _viewportResizeTimer?.cancel();
    _viewportResizeTimer = Timer(_viewportResizeDebounce, () {
      _viewportResizeTimer = null;
      if (!mounted) return;
      widget.onViewportResized?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final lyrics = provider.lyrics;
    final metadata = provider.currentMetadata;
    final lyricsResult = provider.lyricsResult;
    final currentIndex = provider.currentIndex;
    final isInterlude = provider.isInterlude;

    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: RepaintBoundary(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            RepaintBoundary(
              child: Text(
                provider.loadingStatus.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (lyrics.isEmpty) {
      String message = t.lyrics.noLyricsFound;
      if (metadata == null) {
        message = t.lyrics.startPlaying;
      } else if (lyricsResult.isPureMusic) {
        message = t.lyrics.pureMusic;
      } else if (provider.fetchFailureMessage != null) {
        message = provider.fetchFailureMessage!;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Plain lyrics have no line timestamps. Scroll the whole document by
    // track progress instead of highlighting a row.
    if (!lyricsResult.isSynced) {
      return _UnsyncedLyricsView(
        provider: provider,
        lyrics: lyrics,
        isManualScrolling: widget.isManualScrolling,
        onUserInteraction: widget.onUserInteraction,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle) {
          widget.onUserInteraction(provider.scrollAutoResumeDelay.current);
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _handleConstraints(constraints);
          // Compute the padding from the viewport constraints once per
          // layout pass. Previously we hit MediaQuery.of three times in
          // the inline EdgeInsets expression below, which subscribed this
          // widget to every MediaQueryData field (text scale, keyboard
          // insets, etc.) and burned a small amount of CPU on each build.
          final viewportHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final landscapeSpace = (provider.landscapeLeadingSpace.current / 100)
              .clamp(0.0, 1.0);
          final listPadding = EdgeInsets.only(
            top: isLandscape ? viewportHeight * landscapeSpace : 0.0,
            bottom: viewportHeight / 3,
          );
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ScrollablePositionedList.builder(
              itemCount: lyrics.length + 1,
              itemScrollController: widget.itemScrollController,
              itemPositionsListener: widget.itemPositionsListener,
              minCacheExtent: 0,
              itemBuilder: (context, index) {
                if (index == lyrics.length) {
                  return _LyricsInfoLine(provider: provider);
                }

                final lyric = lyrics[index];
                final isHighlighted = index == currentIndex;
                final isPrerendered = (index - currentIndex).abs() == 1;
                final distance = (index - currentIndex).toDouble();
                final hasRichInlineParts =
                    lyric.inlineParts != null && lyric.inlineParts!.isNotEmpty;
                final showInterludeIndicator =
                    isHighlighted && isInterlude && lyric.text.trim().isEmpty;

                // Outer shell is always _InViewportBuilder -> GestureDetector
                // regardless of whether this row is currently rendering an
                // interlude indicator or a normal LyricLine. Keeping the
                // outermost runtimeType stable lets Flutter's element
                // reconciler reuse the same Element when the highlighted row
                // flips between the two child shapes (e.g. user picks a
                // different candidate while the current line is an
                // interlude), so the row's RenderBox + GestureDetector
                // identity survive across the swap instead of being
                // unmounted and re-built one frame later. Cosmetic cleanup;
                // does not by itself fix any user-visible jitter (see the
                // _jumpToCurrentIndex change in lyrics_screen.dart for the
                // actual scroll-twitch fix).
                return _InViewportBuilder(
                  index: index,
                  notifier: _inViewport,
                  builder: (context, inViewport) {
                    return GestureDetector(
                      onDoubleTap: provider.controlAbility.canSeek
                          ? () => provider.seek(lyric.startTime)
                          : null,
                      behavior: HitTestBehavior.translucent,
                      child: showInterludeIndicator
                          ? ValueListenableBuilder<Duration>(
                              valueListenable: provider.currentPositionNotifier,
                              builder: (context, currentPosition, _) {
                                return RepaintBoundary(
                                  child: InterludeIndicator(
                                    progress: provider
                                        .interludeProgressForPosition(
                                          currentPosition,
                                        ),
                                    duration: provider.interludeDuration,
                                  ),
                                );
                              },
                            )
                          : hasRichInlineParts
                          ? _RichLineResyncBridge(
                              listenable: provider.positionResyncNotifier,
                              subscribeToResync: isHighlighted,
                              fallbackPosition: provider.currentPosition,
                              builder: (context, currentPosition) {
                                return _buildLyricLine(
                                  lyric: lyric,
                                  isHighlighted: isHighlighted,
                                  isPrerendered: isPrerendered,
                                  distance: distance,
                                  inViewport: inViewport,
                                  currentPosition: currentPosition,
                                );
                              },
                            )
                          : _buildLyricLine(
                              lyric: lyric,
                              isHighlighted: isHighlighted,
                              isPrerendered: isPrerendered,
                              distance: distance,
                              inViewport: inViewport,
                              currentPosition: provider.currentPosition,
                            ),
                    );
                  },
                );
              },
              padding: listPadding,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLyricLine({
    required Lyric lyric,
    required bool isHighlighted,
    required bool isPrerendered,
    required double distance,
    required bool inViewport,
    required Duration currentPosition,
  }) {
    final provider = widget.provider;
    return LyricLine(
      lyric: lyric,
      isHighlighted: isHighlighted,
      isPrerendered: isPrerendered,
      distance: distance,
      isManualScrolling: widget.isManualScrolling,
      blurEnabled: provider.blurEnabled.current,
      inViewport: inViewport,
      fontSize: provider.fontSize.current,
      inactiveScale: provider.inactiveScale.current,
      translationHighlightOnly: provider.translationHighlightOnly.current,
      experimentalRichInlineFontSizeGlitching:
          provider.experimentalRichInlineFontSizeGlitching.current,
      experimentalAnnotationFontSizeGlitching:
          provider.experimentalAnnotationFontSizeGlitching.current,
      richSyncThreshold: Duration(
        milliseconds: provider.richSyncThresholdMs.current,
      ),
      adjustedPosition:
          currentPosition + provider.globalOffset + provider.trackOffset,
      isPlaying: provider.isPlaying,
    );
  }
}

/// Scroll offset for unsynced lyrics. Returns null when there is no track
/// duration to map onto, so the view leaves the current offset alone.
double? _unsyncedScrollOffset({
  required Duration position,
  required Duration? duration,
  required double maxScrollExtent,
}) {
  if (duration == null || duration <= Duration.zero) return null;
  final progress = (position.inMicroseconds / duration.inMicroseconds).clamp(
    0.0,
    1.0,
  );
  if (maxScrollExtent <= 0) return 0;
  return progress * maxScrollExtent;
}

Duration? _unsyncedPositionForOffset({
  required double offset,
  required Duration? duration,
  required double maxScrollExtent,
}) {
  if (duration == null || duration <= Duration.zero) return null;
  if (maxScrollExtent <= 0) return Duration.zero;
  final progress = (offset / maxScrollExtent).clamp(0.0, 1.0);
  return Duration(microseconds: (duration.inMicroseconds * progress).round());
}

/// Linear scroll that still accepts drags. [ScrollController.animateTo] ignores
/// pointers and goes ballistic when it ends; both show up as hitching.
class _LinearFollowActivity extends ScrollActivity {
  _LinearFollowActivity(
    super.delegate, {
    required double from,
    required double to,
    required Duration duration,
    required TickerProvider vsync,
    required this.onDone,
  }) {
    _controller = AnimationController.unbounded(value: from, vsync: vsync)
      ..addListener(_tick)
      ..animateTo(
        to,
        duration: duration,
        curve: Curves.linear,
      ).whenComplete(_finish);
  }

  final void Function(bool completed) onDone;
  late final AnimationController _controller;
  bool _disposed = false;
  bool _completed = false;
  bool _reported = false;

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _disposed ? 0 : _controller.velocity;

  void _tick() {
    if (_disposed || _reported) return;
    if (delegate.setPixels(_controller.value).abs() <= 0.5) return;
    delegate.goIdle();
  }

  void _finish() {
    if (_disposed || _reported) return;
    _completed = true;
    _report(true);
    delegate.goIdle();
  }

  void _report(bool completed) {
    if (_reported) return;
    _reported = true;
    onDone(completed);
  }

  @override
  void dispose() {
    _disposed = true;
    _report(_completed);
    _controller.dispose();
    super.dispose();
  }
}

/// Plain lyric document scrolled by track progress. Line widgets are built
/// once per lyrics/style change. While playing, one linear activity runs to
/// the end of the document over the remaining track time. Samples inside the
/// seek window, and metrics noise, do not restart it.
class _UnsyncedLyricsView extends StatefulWidget {
  final LyricsProvider provider;
  final List<Lyric> lyrics;
  final bool isManualScrolling;
  final Function(int) onUserInteraction;

  const _UnsyncedLyricsView({
    required this.provider,
    required this.lyrics,
    required this.isManualScrolling,
    required this.onUserInteraction,
  });

  @override
  State<_UnsyncedLyricsView> createState() => _UnsyncedLyricsViewState();
}

class _UnsyncedLyricsViewState extends State<_UnsyncedLyricsView>
    with TickerProviderStateMixin {
  /// Samples within this distance of the on-screen position are corrections,
  /// not seeks. Restarting the linear run on them is what steps and jitters.
  static const Duration _seekSnap = Duration(milliseconds: 1200);
  static const double _offsetEpsilon = 0.5;
  static const double _extentEpsilon = 1;
  static const double _cacheExtent = 1000000;

  final ScrollController _controller = ScrollController();
  List<Widget>? _lineItems;
  Object? _lineToken;
  bool _pointerScrolling = false;
  bool _touching = false;
  bool _suppressFollow = false;
  bool _followScheduled = false;
  bool _followForce = false;
  bool _applyingScroll = false;
  bool _linearMotion = false;
  int _motionGeneration = 0;
  double? _plannedExtent;

  bool get _blocked =>
      _pointerScrolling || _suppressFollow || widget.isManualScrolling;

  @override
  void initState() {
    super.initState();
    widget.provider.currentPositionNotifier.addListener(_onPosition);
    _scheduleFollow(force: true);
  }

  @override
  void didUpdateWidget(covariant _UnsyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      oldWidget.provider.currentPositionNotifier.removeListener(_onPosition);
      widget.provider.currentPositionNotifier.addListener(_onPosition);
    }
    final followResumed =
        oldWidget.isManualScrolling && !widget.isManualScrolling;
    if (followResumed) {
      _suppressFollow = false;
      _pointerScrolling = false;
    }
    final startedPlaying =
        !oldWidget.provider.isPlaying && widget.provider.isPlaying;
    final stoppedPlaying =
        oldWidget.provider.isPlaying && !widget.provider.isPlaying;
    if (stoppedPlaying) {
      _stopFollowActivity();
    }
    if (_blocked) return;
    if (followResumed ||
        startedPlaying ||
        oldWidget.provider != widget.provider) {
      _syncFollow(force: true);
    }
  }

  @override
  void dispose() {
    _motionGeneration++;
    _linearMotion = false;
    widget.provider.currentPositionNotifier.removeListener(_onPosition);
    _controller.dispose();
    super.dispose();
  }

  void _onPosition() {
    if (_blocked || _touching) return;
    _syncFollow(force: !widget.provider.isPlaying);
  }

  void _scheduleFollow({required bool force}) {
    _followForce = _followForce || force;
    if (_followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forceFollow = _followForce;
      _followScheduled = false;
      _followForce = false;
      if (!mounted) return;
      _syncFollow(force: forceFollow);
    });
  }

  Duration _reportedPosition(Duration? duration) {
    var reported = widget.provider.currentPositionNotifier.value;
    if (reported.isNegative) reported = Duration.zero;
    if (duration != null && duration > Duration.zero && reported > duration) {
      return duration;
    }
    return reported;
  }

  bool _motionCovers(Duration reported, Duration duration, double extent) {
    if (!_linearMotion || _plannedExtent == null || !_controller.hasClients) {
      return false;
    }
    if ((extent - _plannedExtent!).abs() > _extentEpsilon) return false;
    final visual = _unsyncedPositionForOffset(
      offset: _controller.offset,
      duration: duration,
      maxScrollExtent: extent,
    );
    if (visual == null) return false;
    return (reported - visual).abs() <= _seekSnap;
  }

  void _syncFollow({required bool force}) {
    if (!mounted) return;
    if (_blocked || _touching) {
      // A drag already replaced the linear activity. jumpTo here would steal it.
      if (!_pointerScrolling && !_touching) _stopFollowActivity();
      return;
    }
    if (!_controller.hasClients) {
      _scheduleFollow(force: force);
      return;
    }
    final duration = widget.provider.currentMetadata?.duration;
    final extent = _controller.position.maxScrollExtent;
    if (duration == null || duration <= Duration.zero || extent <= 0) {
      _stopFollowActivity();
      _plannedExtent = extent;
      return;
    }
    final reported = _reportedPosition(duration);
    if (!widget.provider.isPlaying) {
      _stopFollowActivity();
      if (force) {
        final target = _unsyncedScrollOffset(
          position: reported,
          duration: duration,
          maxScrollExtent: extent,
        );
        if (target != null) _jumpTo(target);
      }
      _plannedExtent = extent;
      return;
    }
    if (_motionCovers(reported, duration, extent)) return;
    _startLinear(position: reported, duration: duration, extent: extent);
  }

  void _startLinear({
    required Duration position,
    required Duration duration,
    required double extent,
  }) {
    final positionController = _controller.position;
    if (positionController is! ScrollPositionWithSingleContext) {
      final target = _unsyncedScrollOffset(
        position: position,
        duration: duration,
        maxScrollExtent: extent,
      );
      if (target != null) _jumpTo(target);
      _plannedExtent = extent;
      return;
    }
    final target = _unsyncedScrollOffset(
      position: position,
      duration: duration,
      maxScrollExtent: extent,
    );
    if (target == null) return;
    final generation = ++_motionGeneration;
    _linearMotion = false;
    _jumpTo(target);
    _plannedExtent = extent;
    final remainingMicros = duration.inMicroseconds - position.inMicroseconds;
    if (remainingMicros < 16000 ||
        (extent - _controller.offset).abs() <= _offsetEpsilon) {
      return;
    }
    _linearMotion = true;
    positionController.beginActivity(
      _LinearFollowActivity(
        positionController,
        from: _controller.offset,
        to: extent,
        duration: Duration(microseconds: remainingMicros),
        vsync: this,
        onDone: (completed) {
          if (!mounted || generation != _motionGeneration) return;
          _linearMotion = false;
        },
      ),
    );
  }

  void _stopFollowActivity() {
    if (!_linearMotion) return;
    _motionGeneration++;
    _linearMotion = false;
    if (!_controller.hasClients) return;
    _applyingScroll = true;
    _controller.jumpTo(_controller.offset);
    _applyingScroll = false;
  }

  void _jumpTo(double target) {
    if (!_controller.hasClients) return;
    if ((_controller.offset - target).abs() <= _offsetEpsilon) return;
    _applyingScroll = true;
    _controller.jumpTo(target);
    _applyingScroll = false;
  }

  void _retargetExtent(double newExtent) {
    final duration = widget.provider.currentMetadata?.duration;
    final oldExtent = _plannedExtent;
    if (!_controller.hasClients ||
        duration == null ||
        duration <= Duration.zero ||
        oldExtent == null ||
        oldExtent <= 0 ||
        newExtent <= 0) {
      _plannedExtent = newExtent;
      _syncFollow(force: true);
      return;
    }
    final progress = (_controller.offset / oldExtent).clamp(0.0, 1.0);
    final position = Duration(
      microseconds: (duration.inMicroseconds * progress).round(),
    );
    if (_blocked || !widget.provider.isPlaying) {
      _stopFollowActivity();
      _plannedExtent = newExtent;
      _jumpTo(progress * newExtent);
      return;
    }
    _startLinear(position: position, duration: duration, extent: newExtent);
  }

  void _endTouch() {
    _touching = false;
    if (!mounted || _blocked) return;
    _syncFollow(force: true);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is! UserScrollNotification) return false;
    if (notification.direction != ScrollDirection.idle) {
      _pointerScrolling = true;
      _stopFollowActivity();
      final delay = widget.provider.scrollAutoResumeDelay.current;
      _suppressFollow = delay > 0;
      widget.onUserInteraction(delay);
      return false;
    }
    _pointerScrolling = false;
    if (!_suppressFollow && !widget.isManualScrolling) {
      _syncFollow(force: true);
    }
    return false;
  }

  bool _handleMetrics(ScrollMetricsNotification notification) {
    if (_applyingScroll || _blocked || _touching) return false;
    final extent = notification.metrics.maxScrollExtent;
    if (_plannedExtent != null &&
        (extent - _plannedExtent!).abs() <= _extentEpsilon) {
      return false;
    }
    _retargetExtent(extent);
    return false;
  }

  List<Widget> _lineItemsFor(LyricsProvider provider, List<Lyric> lyrics) {
    final fontSize = provider.fontSize.current;
    final token = (
      lyrics,
      fontSize,
      provider.lyricsResult,
      provider.translationResult,
    );
    final cached = _lineItems;
    if (cached != null && _lineToken == token) return cached;

    _lineToken = token;
    final items = <Widget>[
      for (final lyric in lyrics)
        _UnsyncedLyricText(lyric: lyric, fontSize: fontSize),
      _LyricsInfoLine(provider: provider),
    ];
    _lineItems = items;
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _lineItemsFor(widget.provider, widget.lyrics);
    final fontSize = widget.provider.fontSize.current;
    // One lyric row, so the last line can scroll clear of the bottom edge.
    // Horizontal inset lives on the row, matching synced LyricLine.
    final bottomLineSpacing =
        fontSize * _unsyncedLineHeight + _unsyncedLineVerticalPadding * 2;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Listener(
          onPointerDown: (_) => _touching = true,
          onPointerUp: (_) => _endTouch(),
          onPointerCancel: (_) => _endTouch(),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView(
              controller: _controller,
              scrollCacheExtent: const ScrollCacheExtent.pixels(_cacheExtent),
              padding: EdgeInsets.only(bottom: bottomLineSpacing),
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}

const double _unsyncedLineHorizontalPadding = 24;
const double _unsyncedLineVerticalPadding = 12;
const double _unsyncedLineHeight = 1.2;

class _UnsyncedLyricText extends StatelessWidget {
  final Lyric lyric;
  final double fontSize;

  const _UnsyncedLyricText({required this.lyric, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final translation = lyric.translation;
    final hasTranslation = translation != null && translation.isNotEmpty;
    final style = TextStyle(
      fontFamily: 'Outfit',
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: _unsyncedLineHeight,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _unsyncedLineVerticalPadding,
        horizontal: _unsyncedLineHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lyric.text, style: style),
          if (hasTranslation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                translation,
                style: style.copyWith(
                  fontSize: (fontSize * 0.65).roundToDouble(),
                  height: _unsyncedLineHeight,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LyricsInfoLine extends StatelessWidget {
  final LyricsProvider provider;

  const _LyricsInfoLine({required this.provider});

  @override
  Widget build(BuildContext context) {
    final result = provider.lyricsResult;
    final transResult = provider.translationResult;
    final info = t.lyrics.info;
    final infoParts = <String>[];
    if (result.source.isNotEmpty) {
      infoParts.add(info.source(value: result.source));
    }
    if (result.writtenBy != null && result.writtenBy!.isNotEmpty) {
      infoParts.add(info.writtenBy(value: result.writtenBy!));
    }
    if (result.composer != null && result.composer!.isNotEmpty) {
      infoParts.add(info.composer(value: result.composer!));
    }
    if (result.contributor != null && result.contributor!.isNotEmpty) {
      infoParts.add(info.contributor(value: result.contributor!));
    }
    if (result.copyright != null && result.copyright!.isNotEmpty) {
      infoParts.add(info.copyright(value: result.copyright!));
    }
    if (transResult != null &&
        transResult.translationProvider != null &&
        transResult.translationProvider!.isNotEmpty) {
      infoParts.add(
        info.translationProvider(value: transResult.translationProvider!),
      );
    }
    if (transResult != null &&
        transResult.translationContributor != null &&
        transResult.translationContributor!.isNotEmpty) {
      infoParts.add(
        info.translationContributor(value: transResult.translationContributor!),
      );
    }

    if (infoParts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 16,
        left: _unsyncedLineHorizontalPadding,
        right: _unsyncedLineHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final part in infoParts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                part,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps a stable widget shape for rich-sync lyric rows while subscribing to
/// [listenable] only when the row is currently highlighted.
///
/// This avoids two problems at once:
/// 1. Non-highlighted rich rows no longer rebuild on every resync event.
/// 2. Highlight transitions do not swap the row subtree between two different
///    runtimeTypes (plain LyricLine vs `ValueListenableBuilder<Duration>`), which
///    would discard the implicit animation state and make AnimatedPadding /
///    AnimatedScale jump instead of tween.
class _RichLineResyncBridge extends StatefulWidget {
  final ValueListenable<Duration> listenable;
  final bool subscribeToResync;
  final Duration fallbackPosition;
  final Widget Function(BuildContext context, Duration currentPosition) builder;

  const _RichLineResyncBridge({
    required this.listenable,
    required this.subscribeToResync,
    required this.fallbackPosition,
    required this.builder,
  });

  @override
  State<_RichLineResyncBridge> createState() => _RichLineResyncBridgeState();
}

class _RichLineResyncBridgeState extends State<_RichLineResyncBridge> {
  Duration? _resyncedPosition;

  @override
  void initState() {
    super.initState();
    _syncSubscription(null);
  }

  @override
  void didUpdateWidget(covariant _RichLineResyncBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable ||
        oldWidget.subscribeToResync != widget.subscribeToResync) {
      _syncSubscription(oldWidget);
    }
  }

  @override
  void dispose() {
    if (widget.subscribeToResync) {
      widget.listenable.removeListener(_handleResync);
    }
    super.dispose();
  }

  void _syncSubscription(_RichLineResyncBridge? oldWidget) {
    if (oldWidget != null && oldWidget.subscribeToResync) {
      oldWidget.listenable.removeListener(_handleResync);
    }

    if (widget.subscribeToResync) {
      _resyncedPosition = widget.listenable.value;
      widget.listenable.addListener(_handleResync);
    } else {
      _resyncedPosition = null;
    }
  }

  void _handleResync() {
    final next = widget.listenable.value;
    if (_resyncedPosition == next) return;
    setState(() {
      _resyncedPosition = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.subscribeToResync
          ? (_resyncedPosition ?? widget.listenable.value)
          : widget.fallbackPosition,
    );
  }
}

/// ChangeNotifier-backed set of viewport indices that only notifies when the
/// set's contents actually change. This keeps per-line in-viewport listeners
/// from rebuilding on every scroll tick.
class _InViewportNotifier extends ChangeNotifier {
  Set<int> _value = const <int>{};

  Set<int> get value => _value;

  bool contains(int index) => _value.contains(index);

  void update(Set<int> next) {
    if (setEquals(_value, next)) return;
    _value = next;
    notifyListeners();
  }
}

/// Builds [builder] with a fresh boolean indicating whether [index] is in the
/// current viewport, rebuilding only when that boolean flips for this index.
class _InViewportBuilder extends StatefulWidget {
  final int index;
  final _InViewportNotifier notifier;
  final Widget Function(BuildContext context, bool inViewport) builder;

  const _InViewportBuilder({
    required this.index,
    required this.notifier,
    required this.builder,
  });

  @override
  State<_InViewportBuilder> createState() => _InViewportBuilderState();
}

class _InViewportBuilderState extends State<_InViewportBuilder> {
  late bool _inViewport;

  @override
  void initState() {
    super.initState();
    _inViewport = widget.notifier.contains(widget.index);
    widget.notifier.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant _InViewportBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier ||
        oldWidget.index != widget.index) {
      oldWidget.notifier.removeListener(_handleChanged);
      widget.notifier.addListener(_handleChanged);
      final next = widget.notifier.contains(widget.index);
      if (next != _inViewport) {
        _inViewport = next;
      }
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    final next = widget.notifier.contains(widget.index);
    if (next == _inViewport) return;
    setState(() {
      _inViewport = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _inViewport);
  }
}
