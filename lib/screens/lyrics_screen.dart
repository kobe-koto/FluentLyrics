import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';
import '../models/lyric_model.dart';
import '../providers/lyrics_provider.dart';
import '../services/media_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/screen/lyrics/lyrics_background.dart';
import '../widgets/screen/lyrics/artwork_image_sizing.dart';
import '../widgets/screen/lyrics/lyrics_header.dart';
import '../widgets/screen/lyrics/lyrics_list.dart';
import '../widgets/screen/lyrics/lyrics_control_area.dart';
import '../widgets/screen/lyrics/permission_overlay.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  static const _maskGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black,
      Colors.black,
      Colors.transparent,
    ],
    stops: [0.0, 0.05, 0.95, 1.0],
  );
  static const Color _defaultBackgroundPlaceholderColor = Colors.black;
  static const Size _paletteSampleSize = Size.square(96);

  final Set<String> _failedArtUrls = {};
  final Map<String, Color> _backgroundPlaceholderColorCache = {};
  int _previousIndex = 0;
  int? _scheduledScrollIndex;
  int _artLoadGeneration = 0;
  String? _lastArtUrl;
  ImageProvider? _foregroundArtProvider;
  ImageProvider? _backgroundArtProvider;
  Color _backgroundPlaceholderColor = _defaultBackgroundPlaceholderColor;
  bool _isManualScrolling = false;
  Timer? _autoResumeTimer;
  String? _lastTitle;
  String? _lastArtist;
  bool _isForceReloading = false;
  bool _isScrubbing = false;
  double _scrubValue = 0.0;
  LyricsProvider? _scrollSyncProvider;
  LyricsProvider? _wakelockProvider;
  bool? _lastKeepScreenOn;
  List<Lyric>? _lastLyricsRef;
  bool? _lastLayoutIsLandscape;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<LyricsProvider>();

    if (_scrollSyncProvider != provider) {
      _scrollSyncProvider?.removeListener(_handleProviderChanged);
      _scrollSyncProvider = provider;
      _scrollSyncProvider!.addListener(_handleProviderChanged);
      _lastLyricsRef = provider.lyrics;
      // Seed art providers once at mount so the first frame already shows the
      // correct artwork without waiting for a provider notification.
      _updateArtProviders(
        provider.currentMetadata,
        provider.mediaService,
        provider.artworkUrlsNotifier.value,
      );
      _syncCurrentIndex(provider.currentIndex, provider.linesBefore.current);
    }

    if (!Platform.isAndroid) return;
    if (_wakelockProvider == provider) return;

    _wakelockProvider?.removeListener(_handleWakelockSettingChanged);
    _wakelockProvider = provider;
    _wakelockProvider!.addListener(_handleWakelockSettingChanged);
    _syncWakelock(provider.keepScreenOn.current);
  }

  ({int targetIndex, double alignment}) _resolveScrollTarget(
    int index,
    int linesBefore,
  ) {
    final safeIndex = index < 0 ? 0 : index;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final targetIndex = isLandscape
        ? safeIndex
        : (safeIndex - linesBefore).clamp(0, safeIndex);
    final alignment = isLandscape ? 0.3 : 0.0;
    return (targetIndex: targetIndex, alignment: alignment);
  }

  void _scrollToCurrentIndex(int index, int linesBefore) {
    if (!_itemScrollController.isAttached) return;
    final target = _resolveScrollTarget(index, linesBefore);
    _itemScrollController.scrollTo(
      index: target.targetIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutQuart,
      alignment: target.alignment,
    );
  }

  /// Snap (no animation) to [index]. Used when the displayed lyrics content
  /// changes (e.g. translation arrives, new lyrics returned) so the viewport
  /// re-anchors to the current line instead of letting line-height changes
  /// shift everything visually.
  ///
  /// Implemented via a 1μs `scrollTo` instead of `ItemScrollController.jumpTo`
  /// because SPL's `_jumpTo` unconditionally calls
  /// `primary.scrollController.jumpTo(0)` inside a `setState`, which produces
  /// a visible single-frame layout twitch (most apparent in landscape, where
  /// the anchor row IS the highlighted row). The 1μs `scrollTo` takes SPL's
  /// `_startScroll` fast path when the target is already visible, which just
  /// animates the existing primary scroll controller without forcing a
  /// `pixels = 0` round trip.
  ///
  /// * > assert(duration > Duration.zero);
  ///   SPL requies a non-zero positive duration for `scrollTo` during debug profile,
  ///   so we use 1μs as effectively zero.
  void _jumpToCurrentIndex(int index, int linesBefore) {
    if (!_itemScrollController.isAttached) return;
    final target = _resolveScrollTarget(index, linesBefore);
    _itemScrollController.scrollTo(
      index: target.targetIndex,
      alignment: target.alignment,
      duration: const Duration(microseconds: 1),
    );
  }

  void _syncCurrentIndex(int index, int linesBefore) {
    if (index == _previousIndex) return;
    _previousIndex = index;

    if (_isManualScrolling || _scheduledScrollIndex == index) {
      return;
    }

    _scheduledScrollIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scheduledScrollIndex == index) {
        _scheduledScrollIndex = null;
      }
      if (!mounted || _isManualScrolling) return;
      _scrollToCurrentIndex(index, linesBefore);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The screen itself does not listen to the provider. Each subtree below
    // listens to the minimum set of fields it actually renders, so a
    // notifyListeners() call from media polling does not force the entire
    // screen's element tree to rebuild.
    final provider = context.read<LyricsProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Layer. Only rebuilds when art, motion setting, or
          // playing state changes. Position ticks do NOT rebuild it.
          _BackgroundSection(
            provider: provider,
            getBackgroundArt: () => _backgroundArtProvider,
            getForegroundArt: () => _foregroundArtProvider,
            placeholderColor: _backgroundPlaceholderColor,
          ),

          // Content Layer
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                _handleLayoutModeChanged(isLandscape, provider);

                final lyricsListWidget = RepaintBoundary(
                  // RepaintBoundary around the ShaderMask + list keeps the
                  // mask's saveLayer cost isolated from the rest of the
                  // Scaffold. Without it, any sibling repaint (header,
                  // control area, permission overlay, background ticks) can
                  // invalidate the parent layer and force the masked region
                  // to recomposite even though its contents are unchanged.
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return _maskGradient.createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      // LyricsList reads many provider fields directly inside
                      // its own build; wrap it in a Consumer so it rebuilds
                      // on provider notifications without dragging the rest
                      // of the screen with it.
                      child: Consumer<LyricsProvider>(
                        builder: (context, p, _) => LyricsList(
                          provider: p,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          isManualScrolling: _isManualScrolling,
                          onUserInteraction: _handleUserInteraction,
                          onViewportResized: () => _resnapToCurrentIndex(p),
                        ),
                      ),
                    ),
                  ),
                );

                final headerWidget = _HeaderSection(
                  provider: provider,
                  getForegroundArt: () => _foregroundArtProvider,
                  onRefresh: _handleRefresh,
                  isLandscape: isLandscape,
                );

                final controlAreaWidget = _ControlSection(
                  provider: provider,
                  isScrubbing: _isScrubbing,
                  scrubValue: _scrubValue,
                  onScrubChanged: (value) {
                    setState(() {
                      _isScrubbing = true;
                      _scrubValue = value;
                    });
                  },
                  onScrubEnd: (value) {
                    final totalMs =
                        provider.currentMetadata?.duration.inMilliseconds ?? 1;
                    final ms = (value * totalMs).round();
                    provider.seek(Duration(milliseconds: ms));
                    setState(() {
                      _isScrubbing = false;
                    });
                  },
                );

                if (isLandscape) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Expanded(child: headerWidget),
                                  controlAreaWidget,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: lyricsListWidget),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    headerWidget,
                    Expanded(child: lyricsListWidget),
                    controlAreaWidget,
                  ],
                );
              },
            ),
          ),
          // Permission Overlay
          _PermissionOverlaySection(provider: provider),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<LyricsProvider>();
    setState(() {
      _isForceReloading = true;
      _lastArtUrl = null;
      _failedArtUrls.clear();
    });
    if (_foregroundArtProvider != null) {
      _foregroundArtProvider!.evict();
    }
    if (_backgroundArtProvider != null) {
      _backgroundArtProvider!.evict();
    }
    await provider.clearCurrentTrackCache();
  }

  void _handleProviderChanged() {
    final provider = _scrollSyncProvider;
    if (provider == null) return;

    // Keep the art providers in sync with whatever the provider reports.
    // Doing this here (rather than during build) means the surrounding
    // widget tree no longer has to listen to the full provider just to
    // notice an art-url change; ValueNotifier-driven sub-widgets that
    // read _foregroundArtProvider / _backgroundArtProvider get them via
    // setState below when they actually swap.
    _updateArtProviders(
      provider.currentMetadata,
      provider.mediaService,
      provider.artworkUrlsNotifier.value,
      forceReload: _isForceReloading,
    );
    if (_isForceReloading) _isForceReloading = false;

    // Detect display-content changes (new lyrics fetched, translation
    // arrived/cleared, rich-sync stripping toggled). LyricsProvider's `lyrics`
    // getter returns the same List reference when nothing changed thanks to
    // its alignment / stripping caches, so a reference inequality is a
    // reliable signal that the rendered content shifted.
    final lyricsRef = provider.lyrics;
    if (!identical(lyricsRef, _lastLyricsRef)) {
      _lastLyricsRef = lyricsRef;
      // Re-anchor to absorb height differences that the new lyrics /
      // translation may have introduced in the surrounding lines.
      // `_jumpToCurrentIndex` uses a 1μs `scrollTo` rather than SPL's raw
      // `jumpTo` so this no-op-by-target case (currentIndex unchanged) does
      // not trigger SPL's internal `primary.scrollController.jumpTo(0)` and
      // the resulting one-frame layout twitch.
      _resnapToCurrentIndex(provider);
      // Keep _previousIndex in sync so the subsequent _syncCurrentIndex call
      // does not also schedule an animated scrollTo for the same index.
      _previousIndex = provider.currentIndex;
      return;
    }

    _syncCurrentIndex(provider.currentIndex, provider.linesBefore.current);
  }

  void _handleLayoutModeChanged(bool isLandscape, LyricsProvider provider) {
    final previous = _lastLayoutIsLandscape;
    _lastLayoutIsLandscape = isLandscape;
    if (previous == null || previous == isLandscape) return;
    _resnapToCurrentIndex(provider);
  }

  /// Re-anchor the viewport to the current line without animation after the
  /// displayed content changes, so line-height differences from new lyrics or
  /// translations don't visually shift the page. Skipped while the user is
  /// manually scrolling.
  void _resnapToCurrentIndex(LyricsProvider provider) {
    if (_isManualScrolling) return;
    final index = provider.currentIndex;
    if (index < 0) return;
    final linesBefore = provider.linesBefore.current;
    // Defer one frame so the rebuilt ScrollablePositionedList has the new
    // item count / line widgets before we jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isManualScrolling) return;
      _jumpToCurrentIndex(index, linesBefore);
    });
  }

  void _updateArtProviders(
    MediaMetadata? metadata,
    MediaService mediaService,
    List<String> alternateUrls, {
    bool forceReload = false,
  }) {
    String? artUrl = metadata?.artUrl.trim();
    final title = metadata?.title;
    final artist = metadata?.artist.join(', ');

    if (title != _lastTitle || artist != _lastArtist) {
      _failedArtUrls.clear();
    }

    if (artUrl != null && _failedArtUrls.contains(artUrl)) {
      artUrl = 'fallback';
    }

    if (artUrl == null || artUrl.isEmpty || artUrl == 'fallback') {
      for (final url in alternateUrls) {
        if (!_failedArtUrls.contains(url)) {
          artUrl = url;
          break;
        }
      }
    }

    final hasValidArt =
        artUrl != null && artUrl.isNotEmpty && artUrl != 'fallback';

    if (hasValidArt && metadata != null) {
      if (artUrl != _lastArtUrl || forceReload) {
        _lastArtUrl = artUrl;
        if (!forceReload && _foregroundArtProvider != null) {
          _foregroundArtProvider!.evict();
        }
        _foregroundArtProvider = _getArtProvider(artUrl, mediaService);
        _precacheAndSwap(
          _foregroundArtProvider!,
          artUrl,
          _artColorCacheKey(artUrl),
          ++_artLoadGeneration,
        );
      }
    } else {
      if (!forceReload && title == _lastTitle && artist == _lastArtist) {
        // Keep current
      } else {
        _artLoadGeneration++;
        _backgroundPlaceholderColor = _defaultBackgroundPlaceholderColor;
        if (metadata == null) {
          _lastArtUrl = null;
          _foregroundArtProvider = const AssetImage('assets/album_art.png');
          _backgroundArtProvider = _foregroundArtProvider;
        } else {
          _lastArtUrl = artUrl;
        }
      }
    }

    _lastTitle = title;
    _lastArtist = artist;
  }

  void _precacheAndSwap(
    ImageProvider provider,
    String url,
    String colorCacheKey,
    int generation,
  ) {
    final placeholderFuture = _resolveBackgroundPlaceholderColor(
      provider,
      colorCacheKey,
    ).catchError((_) => _defaultBackgroundPlaceholderColor);

    precacheImage(provider, context)
        .then((_) async {
          if (!mounted || generation != _artLoadGeneration ||
              _lastArtUrl != url) {
            return;
          }

          final minSize = context.read<LyricsProvider>().artworkMinSize.current;
          if (minSize > 0 && url.startsWith('data:')) {
            final size = await _resolveImageSize(provider)
                .catchError((_) => Size.zero);
            if (!mounted || generation != _artLoadGeneration ||
                _lastArtUrl != url) {
              return;
            }
            final shorter = size.shortestSide.round();
            if (shorter > 0 && shorter < minSize) {
              _rejectArtwork(url);
              return;
            }
          }

          final placeholderColor = await placeholderFuture;
          if (mounted &&
              generation == _artLoadGeneration &&
              _lastArtUrl == url) {
            unawaited(_precacheForegroundArtSizes(provider, url));
            setState(() {
              _backgroundPlaceholderColor = placeholderColor;
              _backgroundArtProvider = provider;
            });
          }
        })
        .catchError((e) {
          if (mounted &&
              generation == _artLoadGeneration &&
              _lastArtUrl == url) {
            _rejectArtwork(url);
          }
        });
  }

  void _rejectArtwork(String url) {
    _failedArtUrls.add(url);
    final provider = context.read<LyricsProvider>();
    _updateArtProviders(
      provider.currentMetadata,
      provider.mediaService,
      provider.artworkUrlsNotifier.value,
    );
  }

  String _artColorCacheKey(String artUrl) {
    if (artUrl.startsWith('data:')) {
      return 'data:${artUrl.hashCode}';
    }
    return artUrl;
  }

  Future<Color> _resolveBackgroundPlaceholderColor(
    ImageProvider provider,
    String cacheKey,
  ) async {
    final cached = _backgroundPlaceholderColorCache[cacheKey];
    if (cached != null) return cached;

    final paletteImage = await _resolvePaletteImage(provider);
    final PaletteGenerator palette;
    try {
      palette = await PaletteGenerator.fromImage(
        paletteImage,
        maximumColorCount: 12,
      );
    } finally {
      paletteImage.dispose();
    }

    final sourceColor =
        palette.dominantColor?.color ??
        palette.darkMutedColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.mutedColor?.color ??
        palette.vibrantColor?.color;
    final placeholderColor = sourceColor == null
        ? _defaultBackgroundPlaceholderColor
        : _reserveColorForBackground(sourceColor);
    _backgroundPlaceholderColorCache[cacheKey] = placeholderColor;
    return placeholderColor;
  }

  Future<ui.Image> _resolvePaletteImage(ImageProvider provider) {
    final resized = ResizeImage(
      provider,
      width: _paletteSampleSize.width.round(),
      height: _paletteSampleSize.height.round(),
    );
    final stream = resized.resolve(
      const ImageConfiguration(size: _paletteSampleSize, devicePixelRatio: 1.0),
    );
    final completer = Completer<ui.Image>();
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(info.image.clone());
        }
        info.dispose();
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

  Color _reserveColorForBackground(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.72).clamp(0.0, 0.58).toDouble())
        .withLightness(hsl.lightness.clamp(0.24, 0.54).toDouble())
        .toColor();
  }

  Future<void> _precacheForegroundArtSizes(
    ImageProvider provider,
    String url,
  ) async {
    final intrinsicSize = await _resolveImageSize(
      provider,
    ).catchError((_) => Size.zero);
    if (!mounted || _lastArtUrl != url || intrinsicSize == Size.zero) return;

    for (final resizedProvider
        in ArtworkImageSizing.foregroundPrecacheProviders(
          provider,
          intrinsicWidth: intrinsicSize.width.round(),
          intrinsicHeight: intrinsicSize.height.round(),
        )) {
      unawaited(precacheImage(resizedProvider, context).catchError((_) {}));
    }
  }

  Future<Size> _resolveImageSize(ImageProvider provider) {
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final completer = Completer<Size>();
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
        info.dispose();
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

  ImageProvider _getArtProvider(String? artUrl, MediaService mediaService) {
    if (artUrl == null || artUrl.isEmpty || artUrl == 'fallback') {
      return const AssetImage('assets/album_art.png');
    }

    if (artUrl.startsWith('data:')) {
      final commaIndex = artUrl.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = artUrl
              .substring(commaIndex + 1)
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          return const AssetImage('assets/album_art.png');
        }
      }
    }

    if (artUrl.startsWith('file://')) {
      try {
        return FileImage(File(Uri.parse(artUrl).toFilePath()));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    if (artUrl.startsWith('/')) {
      try {
        return FileImage(File(artUrl));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    try {
      return CachedNetworkImageProvider(artUrl);
    } catch (e) {
      return const AssetImage('assets/album_art.png');
    }
  }

  void _handleUserInteraction(int delaySeconds) {
    if (delaySeconds == 0) return;

    if (!_isManualScrolling) {
      setState(() {
        _isManualScrolling = true;
      });
    }

    _autoResumeTimer?.cancel();
    _autoResumeTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) {
        setState(() {
          _isManualScrolling = false;
        });
        final provider = Provider.of<LyricsProvider>(context, listen: false);
        _scrollToCurrentIndex(
          provider.currentIndex,
          provider.linesBefore.current,
        );
      }
    });
  }

  void _handleWakelockSettingChanged() {
    final provider = _wakelockProvider;
    if (provider == null) return;
    _syncWakelock(provider.keepScreenOn.current);
  }

  void _syncWakelock(bool keepScreenOn) {
    if (_lastKeepScreenOn == keepScreenOn) return;
    _lastKeepScreenOn = keepScreenOn;
    if (keepScreenOn) {
      unawaited(WakelockPlus.enable());
    } else {
      unawaited(WakelockPlus.disable());
    }
  }

  @override
  void dispose() {
    _autoResumeTimer?.cancel();
    _scrollSyncProvider?.removeListener(_handleProviderChanged);
    if (Platform.isAndroid) {
      _wakelockProvider?.removeListener(_handleWakelockSettingChanged);
      unawaited(WakelockPlus.disable());
    }
    super.dispose();
  }
}

/// Background subtree. Rebuilds only when the visually relevant fields
/// (motion setting, isPlaying, art identity) change; positional ticks from
/// media polling do not trigger a rebuild here.
class _BackgroundSection extends StatelessWidget {
  final LyricsProvider provider;
  final ImageProvider? Function() getBackgroundArt;
  final ImageProvider? Function() getForegroundArt;
  final Color placeholderColor;

  const _BackgroundSection({
    required this.provider,
    required this.getBackgroundArt,
    required this.getForegroundArt,
    required this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<LyricsProvider, ({bool motion, bool isPlaying})>(
      selector: (_, p) =>
          (motion: p.backgroundMotionEnabled.current, isPlaying: p.isPlaying),
      builder: (context, s, child) {
        final bgArt =
            getBackgroundArt() ??
            getForegroundArt() ??
            const AssetImage('assets/album_art.png');
        return LyricsBackground(
          artProvider: bgArt,
          motionEnabled: s.motion,
          animate: s.isPlaying,
          placeholderColor: placeholderColor,
        );
      },
    );
  }
}

/// Header subtree. Listens only to fields the header actually renders:
/// the metadata identity (title/artist/album/artUrl) and the number of
/// candidates (to update the badge state).
class _HeaderSection extends StatelessWidget {
  final LyricsProvider provider;
  final ImageProvider? Function() getForegroundArt;
  final VoidCallback onRefresh;
  final bool isLandscape;

  const _HeaderSection({
    required this.provider,
    required this.getForegroundArt,
    required this.onRefresh,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<
      LyricsProvider,
      ({MediaMetadata? metadata, int candidatesLen})
    >(
      selector: (_, p) =>
          (metadata: p.currentMetadata, candidatesLen: p.candidates.length),
      // Custom shouldRebuild because MediaMetadata implements ==, and we want
      // record-shape comparison.
      shouldRebuild: (prev, next) =>
          prev.metadata != next.metadata ||
          prev.candidatesLen != next.candidatesLen,
      builder: (context, _, _) {
        final fg =
            getForegroundArt() ?? const AssetImage('assets/album_art.png');
        return LyricsHeader(
          provider: provider,
          artProvider: fg,
          isLandscape: isLandscape,
          onRefresh: onRefresh,
        );
      },
    );
  }
}

/// Control area subtree. Listens to the smallest possible footprint:
/// play/pause state, control ability, track offset, and total duration.
/// Position ticks are handled inside via `currentPositionNotifier` and do
/// not rebuild this Selector.
class _ControlSection extends StatelessWidget {
  final LyricsProvider provider;
  final bool isScrubbing;
  final double scrubValue;
  final Function(double) onScrubChanged;
  final Function(double) onScrubEnd;

  const _ControlSection({
    required this.provider,
    required this.isScrubbing,
    required this.scrubValue,
    required this.onScrubChanged,
    required this.onScrubEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<
      LyricsProvider,
      ({
        bool isPlaying,
        MediaControlAbility ability,
        int offsetMs,
        int durationMs,
      })
    >(
      selector: (_, p) => (
        isPlaying: p.isPlaying,
        ability: p.controlAbility,
        offsetMs: p.trackOffset.inMilliseconds,
        durationMs: p.currentMetadata?.duration.inMilliseconds ?? 0,
      ),
      builder: (context, _, _) {
        return LyricsControlArea(
          provider: provider,
          isScrubbing: isScrubbing,
          scrubValue: scrubValue,
          onScrubChanged: onScrubChanged,
          onScrubEnd: onScrubEnd,
        );
      },
    );
  }
}

/// Permission overlay subtree. Only rebuilds when grant state flips.
class _PermissionOverlaySection extends StatelessWidget {
  final LyricsProvider provider;

  const _PermissionOverlaySection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Selector<LyricsProvider, bool>(
      selector: (_, p) => p.androidPermissionGranted,
      builder: (context, _, _) => PermissionOverlay(provider: provider),
    );
  }
}
