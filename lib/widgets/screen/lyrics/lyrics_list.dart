import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

  const LyricsList({
    super.key,
    required this.provider,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isManualScrolling,
    required this.onUserInteraction,
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
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              provider.loadingStatus.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      );
    }

    if (lyrics.isEmpty) {
      String message = 'No lyrics found for this track';
      if (metadata == null) {
        message = 'Start playing music';
      } else if (lyricsResult.isPureMusic) {
        message = 'Pure Music / Instrumental';
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle) {
          widget.onUserInteraction(provider.scrollAutoResumeDelay.current);
        }
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ScrollablePositionedList.builder(
          itemCount: lyrics.length + 1,
          itemScrollController: widget.itemScrollController,
          itemPositionsListener: widget.itemPositionsListener,
          minCacheExtent: 0,
          itemBuilder: (context, index) {
            if (index == lyrics.length) {
              return _buildLyricsInfoLine();
            }

            final lyric = lyrics[index];
            final isHighlighted = index == currentIndex;
            final distance = (index - currentIndex).toDouble();

            if (isHighlighted && isInterlude && lyric.text.trim().isEmpty) {
              return ValueListenableBuilder<Duration>(
                valueListenable: provider.currentPositionNotifier,
                builder: (context, currentPosition, child) {
                  return GestureDetector(
                    onDoubleTap: provider.controlAbility.canSeek
                        ? () => provider.seek(lyric.startTime)
                        : null,
                    behavior: HitTestBehavior.translucent,
                    child: InterludeIndicator(
                      progress: provider.interludeProgressForPosition(
                        currentPosition,
                      ),
                      duration: provider.interludeDuration,
                    ),
                  );
                },
              );
            }

            final hasRichInlineParts =
                lyric.inlineParts != null && lyric.inlineParts!.isNotEmpty;

            return _InViewportBuilder(
              index: index,
              notifier: _inViewport,
              builder: (context, inViewport) {
                return GestureDetector(
                  onDoubleTap: provider.controlAbility.canSeek
                      ? () => provider.seek(lyric.startTime)
                      : null,
                  behavior: HitTestBehavior.translucent,
                  child: hasRichInlineParts
                      ? _RichLineResyncBridge(
                          listenable: provider.positionResyncNotifier,
                          subscribeToResync: isHighlighted,
                          fallbackPosition: provider.currentPosition,
                          builder: (context, currentPosition) {
                            return _buildLyricLine(
                              lyric: lyric,
                              isHighlighted: isHighlighted,
                              distance: distance,
                              inViewport: inViewport,
                              currentPosition: currentPosition,
                            );
                          },
                        )
                      : _buildLyricLine(
                          lyric: lyric,
                          isHighlighted: isHighlighted,
                          distance: distance,
                          inViewport: inViewport,
                          currentPosition: provider.currentPosition,
                        ),
                );
              },
            );
          },
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).orientation == Orientation.landscape
                ? MediaQuery.of(context).size.height * 0.3
                : 0.0,
            bottom: MediaQuery.of(context).size.height / 3,
          ),
        ),
      ),
    );
  }

  Widget _buildLyricLine({
    required Lyric lyric,
    required bool isHighlighted,
    required double distance,
    required bool inViewport,
    required Duration currentPosition,
  }) {
    final provider = widget.provider;
    return LyricLine(
      lyric: lyric,
      isHighlighted: isHighlighted,
      distance: distance,
      isManualScrolling: widget.isManualScrolling,
      blurEnabled: provider.blurEnabled.current,
      inViewport: inViewport,
      fontSize: provider.fontSize.current,
      inactiveScale: provider.inactiveScale.current,
      translationHighlightOnly: provider.translationHighlightOnly.current,
      experimentalRichInlineFontSizeGlitching:
          provider.experimentalRichInlineFontSizeGlitching.current,
      adjustedPosition:
          currentPosition + provider.globalOffset + provider.trackOffset,
      isPlaying: provider.isPlaying,
    );
  }

  Widget _buildLyricsInfoLine() {
    final provider = widget.provider;
    final result = provider.lyricsResult;
    final transResult = provider.translationResult;
    final List<String> infoParts = [];
    if (result.source.isNotEmpty) {
      infoParts.add('Source: ${result.source}');
    }
    if (result.writtenBy != null && result.writtenBy!.isNotEmpty) {
      infoParts.add('Written by: ${result.writtenBy}');
    }
    if (result.composer != null && result.composer!.isNotEmpty) {
      infoParts.add('Composer: ${result.composer}');
    }
    if (result.contributor != null && result.contributor!.isNotEmpty) {
      infoParts.add('Contributor: ${result.contributor}');
    }
    if (result.copyright != null && result.copyright!.isNotEmpty) {
      infoParts.add('Copyright: ${result.copyright}');
    }
    if (transResult != null &&
        transResult.translationProvider != null &&
        transResult.translationProvider!.isNotEmpty) {
      infoParts.add('Translation Provider: ${transResult.translationProvider}');
    }
    if (transResult != null &&
        transResult.translationContributor != null &&
        transResult.translationContributor!.isNotEmpty) {
      infoParts.add(
        'Translation Contributor: ${transResult.translationContributor}',
      );
    }

    if (infoParts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 48, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: infoParts
            .map(
              (info) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  info,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
            .toList(),
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
