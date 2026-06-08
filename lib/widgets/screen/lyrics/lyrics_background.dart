import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LyricsBackground extends StatelessWidget {
  final ImageProvider artProvider;
  final bool motionEnabled;

  /// Whether the fragmented motion is currently advancing. When false the
  /// fragment layout freezes at its current position instead of falling back
  /// to the static background – the controller is simply stopped while the
  /// last frame remains on screen. Has no effect when [motionEnabled] is
  /// false.
  final bool animate;

  const LyricsBackground({
    super.key,
    required this.artProvider,
    this.motionEnabled = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: motionEnabled
          ? _FragmentedBackground(
              key: ValueKey(('fragmented', artProvider)),
              artProvider: artProvider,
              animate: animate,
            )
          : _StaticBackground(
              key: ValueKey(('static', artProvider)),
              artProvider: artProvider,
            ),
    );
  }
}

/// Original static blurred background. Unchanged from the pre-motion
/// implementation – kept here so toggling the setting still has the cheap
/// path.
class _StaticBackground extends StatefulWidget {
  final ImageProvider artProvider;

  const _StaticBackground({super.key, required this.artProvider});

  @override
  State<_StaticBackground> createState() => _StaticBackgroundState();
}

class _StaticBackgroundState extends State<_StaticBackground> {
  late ImageProvider _resizedArtProvider;

  @override
  void initState() {
    super.initState();
    _resizedArtProvider = _createResizedArtProvider(widget.artProvider);
  }

  @override
  void didUpdateWidget(covariant _StaticBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artProvider != widget.artProvider) {
      _resizedArtProvider = _createResizedArtProvider(widget.artProvider);
    }
  }

  ImageProvider _createResizedArtProvider(ImageProvider artProvider) {
    return ResizeImage(artProvider, width: 128, height: 128);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: _resizedArtProvider, fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.black.withAlpha(136)),
      ),
    );
  }
}

/// Fragmented background with slow drifting motion.
///
/// Performance model:
/// - The expensive parts (resize + heavy blur + per-fragment opacity) are
///   baked into a single [ui.Image] once per artwork via [_bakeFragment].
/// - Every animation frame draws that pre-baked image six times through a
///   [CustomPainter]. No `saveLayer`, no `BackdropFilter`, no per-frame blur.
/// - The top scrim is a static [Container]; it does not need saveLayer either
///   because it is a fully opaque-coloured rectangle with alpha < 255 painted
///   directly over the canvas.
class _FragmentedBackground extends StatefulWidget {
  final ImageProvider artProvider;
  final bool animate;

  const _FragmentedBackground({
    super.key,
    required this.artProvider,
    required this.animate,
  });

  @override
  State<_FragmentedBackground> createState() => _FragmentedBackgroundState();
}

class _FragmentedBackgroundState extends State<_FragmentedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Fragment> _fragments;

  /// Pre-baked texture: source art -> resize -> heavy blur -> 0.7 opacity,
  /// flattened into a single [ui.Image]. `null` until baking finishes.
  ui.Image? _bakedFragment;

  /// Guards against late completions from a stale art provider overwriting
  /// the current one.
  int _bakeGeneration = 0;

  // Pre-baked texture dimensions. The source is drawn into the centre
  // `_bakeSrcSize × _bakeSrcSize` region; the surrounding `_bakeBleed` ring
  // is empty canvas that the blur is allowed to fade into. Without that
  // bleed, `ImageFilter.blur(tileMode: decal)` would still bleed alpha out
  // to transparent, but anything beyond the bake canvas itself is clipped
  // hard – producing visible square edges when fragments overlap.
  //
  // Sized for σ=24 (≈3σ = 72px of meaningful spread). 64px bleed captures
  // ~99% of the gaussian energy; the rest fades to alpha well under 1/255.
  static const int _bakeSrcSize = 256;
  static const int _bakeBleed = 64;
  static const int _bakeSize = _bakeSrcSize + 2 * _bakeBleed; // 384

  /// Compensates fragment size for the bleed ring around the baked texture.
  /// The src content only occupies `_bakeSrcSize / _bakeSize` of the image,
  /// so drawing the whole texture at fragment scale `s` would make the
  /// content portion visibly smaller than the pre-bake implementation.
  /// The painter multiplies `s` by this ratio so the on-screen content
  /// footprint matches the old code, with the bleed ring extending past it.
  static const double _fragmentBleedFactor =
      _bakeSize / _bakeSrcSize; // 384/256 = 1.5

  static const int _fragmentCount = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    if (widget.animate) _controller.repeat();
    _fragments = _generateFragments();
    _scheduleBake(widget.artProvider);
  }

  @override
  void didUpdateWidget(covariant _FragmentedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artProvider != widget.artProvider) {
      _fragments = _generateFragments();
      _scheduleBake(widget.artProvider);
    }
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        // Resume from the current `_controller.value`, so the fragment
        // layout picks up exactly where it froze instead of jumping.
        _controller.repeat();
      } else {
        // `stop()` halts the ticker; `_controller.value` is preserved, so
        // the painter keeps drawing the last computed frame.
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bakedFragment?.dispose();
    _bakedFragment = null;
    _bakeGeneration++; // invalidate any in-flight bake completion
    super.dispose();
  }

  List<_Fragment> _generateFragments() {
    final rng = math.Random(widget.artProvider.hashCode);
    return List.generate(_fragmentCount, (i) {
      return _Fragment(
        baseX: rng.nextDouble() * 1.4 - 0.2,
        baseY: rng.nextDouble() * 1.4 - 0.2,
        scale: 0.7 + rng.nextDouble() * 0.6,
        driftX: (rng.nextDouble() - 0.5) * 0.08,
        driftY: (rng.nextDouble() - 0.5) * 0.06,
        rotation: rng.nextDouble() * 2 * math.pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.3,
        phase: rng.nextDouble() * 2 * math.pi,
      );
    });
  }

  /// Kick off a one-shot pre-render of the current art into [_bakedFragment].
  void _scheduleBake(ImageProvider provider) {
    final generation = ++_bakeGeneration;
    // Drop the previous texture immediately so we don't keep both around
    // while the new one bakes. The Stack will fall back to the dark base
    // layer in the meantime, which is what the old code briefly showed too.
    _bakedFragment?.dispose();
    _bakedFragment = null;

    unawaited(
      _bakeFragment(provider)
          .then((image) {
            if (!mounted || generation != _bakeGeneration) {
              // We were disposed or a newer bake started – drop this result.
              image.dispose();
              return;
            }
            setState(() {
              _bakedFragment = image;
            });
          })
          .catchError((Object _) {
            // Swallow: the original code also fell back to a blank fragment via
            // Image.errorBuilder when the art failed to load.
          }),
    );
  }

  /// Resolves [provider] to a [ui.Image], then paints it onto a
  /// `_bakeSize × _bakeSize` canvas applying the heavy blur + 0.7 opacity
  /// scrim that used to run every frame.
  ///
  /// The source occupies only the centre `_bakeSrcSize × _bakeSrcSize`
  /// region. The `_bakeBleed` ring around it is empty canvas, present so
  /// that the gaussian blur has somewhere to fade out into instead of being
  /// clipped hard against the canvas border. Without that ring, overlapping
  /// fragments at runtime show visible square edges where the blur stops.
  Future<ui.Image> _bakeFragment(ImageProvider provider) async {
    final source = await _resolveImage(provider);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, _bakeSize.toDouble(), _bakeSize.toDouble()),
      );

      // BoxFit.cover into the centred `_bakeSrcSize` square. Scale by the
      // smaller side ratio so the source fully covers that inner box, then
      // centre-crop.
      final srcW = source.width.toDouble();
      final srcH = source.height.toDouble();
      final scale = _bakeSrcSize / math.min(srcW, srcH);
      final dstW = srcW * scale;
      final dstH = srcH * scale;
      final dstRect = Rect.fromLTWH(
        (_bakeSize - dstW) / 2,
        (_bakeSize - dstH) / 2,
        dstW,
        dstH,
      );

      // Heavy blur baked in via ImageFilter on the paint. Plus alpha-0.7 so
      // overlap blending at runtime matches the original Opacity(0.7).
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
          tileMode: TileMode.decal,
        )
        ..color = const Color.fromRGBO(255, 255, 255, 0.7);
      canvas.drawImageRect(
        source,
        Rect.fromLTWH(0, 0, srcW, srcH),
        dstRect,
        paint,
      );

      final picture = recorder.endRecording();
      try {
        return await picture.toImage(_bakeSize, _bakeSize);
      } finally {
        picture.dispose();
      }
    } finally {
      source.dispose();
    }
  }

  /// Resolves an [ImageProvider] (after a [ResizeImage] step matching the
  /// pre-bake input size) into a concrete [ui.Image].
  Future<ui.Image> _resolveImage(ImageProvider provider) {
    final resized = ResizeImage(provider, width: 256, height: 256);
    final stream = resized.resolve(const ImageConfiguration());
    final completer = Completer<ui.Image>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        // Clone so we own a handle independent of the cache's lifecycle.
        final clone = info.image.clone();
        info.image.dispose();
        if (!completer.isCompleted) completer.complete(clone);
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base dark layer – also acts as the visible canvas while the
            // first bake is in flight.
            Container(color: Colors.black),

            // Animated fragments. Painted by a single CustomPainter so
            // there are no per-fragment widgets / saveLayers in the tree.
            if (_bakedFragment != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FragmentsPainter(
                    image: _bakedFragment!,
                    fragments: _fragments,
                    progress: _controller,
                    sizeMultiplier: _fragmentBleedFactor,
                  ),
                ),
              ),

            // Top scrim. Cheap: a single rect of alpha-136 black drawn over
            // the canvas. Replaces the old BackdropFilter+scrim combo whose
            // blur was the dominant per-frame cost.
            IgnorePointer(child: Container(color: Colors.black.withAlpha(136))),
          ],
        ),
      ),
    );
  }
}

class _Fragment {
  final double baseX;
  final double baseY;
  final double scale;
  final double driftX;
  final double driftY;
  final double rotation;
  final double rotationSpeed;
  final double phase;

  const _Fragment({
    required this.baseX,
    required this.baseY,
    required this.scale,
    required this.driftX,
    required this.driftY,
    required this.rotation,
    required this.rotationSpeed,
    required this.phase,
  });
}

/// Paints all fragments in one go. Listens to the animation controller so
/// only the painter's `paint` runs per frame – not a widget rebuild.
class _FragmentsPainter extends CustomPainter {
  final ui.Image image;
  final List<_Fragment> fragments;
  final Animation<double> progress;

  /// Multiplier applied to each fragment's `scale` to compensate for the
  /// bleed ring baked around the source content. Pass `1.0` if the texture
  /// has no bleed ring.
  final double sizeMultiplier;

  _FragmentsPainter({
    required this.image,
    required this.fragments,
    required this.progress,
    this.sizeMultiplier = 1.0,
  }) : super(repaint: progress);

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final angle = t * 2 * math.pi;
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    for (final frag in fragments) {
      final dx = frag.driftX * math.sin(angle + frag.phase);
      final dy = frag.driftY * math.cos(angle + frag.phase);
      final rot =
          frag.rotation + frag.rotationSpeed * math.sin(angle + frag.phase);

      // Fragment occupies a square the size of the smaller viewport side so
      // its scale 0.7..1.3 maps to ~70-130% of the screen, matching the
      // FractionalTranslation + BoxFit.cover behaviour of the old code.
      // Multiplied by `sizeMultiplier` so the actual content (which lives
      // inside the bleed ring) ends up at the intended on-screen size.
      final side =
          math.min(size.width, size.height) * frag.scale * sizeMultiplier;
      final cx = frag.baseX * size.width;
      final cy = frag.baseY * size.height;

      canvas.save();
      canvas.translate(cx + dx * size.width, cy + dy * size.height);
      canvas.rotate(rot);
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: side,
        height: side,
      );
      canvas.drawImageRect(image, srcRect, dstRect, _paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FragmentsPainter oldDelegate) {
    return oldDelegate.image != image ||
        !identical(oldDelegate.fragments, fragments) ||
        oldDelegate.progress != progress ||
        oldDelegate.sizeMultiplier != sizeMultiplier;
  }
}
