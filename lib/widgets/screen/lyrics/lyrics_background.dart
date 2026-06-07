import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LyricsBackground extends StatelessWidget {
  final ImageProvider artProvider;
  final bool motionEnabled;
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
          ? _LiquidFlowBackground(
              key: ValueKey(('liquid', artProvider)),
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

class _StaticBackground extends StatefulWidget {
  final ImageProvider artProvider;

  const _StaticBackground({super.key, required this.artProvider});

  @override
  State<_StaticBackground> createState() => _StaticBackgroundState();
}

class _StaticBackgroundState extends State<_StaticBackground> {
  late ImageProvider _resizedArtProvider;
  late List<_FlowLayer> _layers;

  @override
  void initState() {
    super.initState();
    _refreshScene();
  }

  @override
  void didUpdateWidget(covariant _StaticBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artProvider != widget.artProvider) {
      _refreshScene();
    }
  }

  void _refreshScene() {
    _resizedArtProvider = _createResizedArtProvider(widget.artProvider);
    _layers = _generateFlowLayers(widget.artProvider);
  }

  @override
  Widget build(BuildContext context) {
    return _LiquidBackgroundScene(
      artProvider: _resizedArtProvider,
      layers: _layers,
      elapsed: Duration.zero,
      motionStrength: 0,
    );
  }
}

class _LiquidFlowBackground extends StatefulWidget {
  final ImageProvider artProvider;
  final bool animate;

  const _LiquidFlowBackground({
    super.key,
    required this.artProvider,
    required this.animate,
  });

  @override
  State<_LiquidFlowBackground> createState() => _LiquidFlowBackgroundState();
}

class _LiquidFlowBackgroundState extends State<_LiquidFlowBackground>
    with SingleTickerProviderStateMixin {
  /// Background animation runs at ~30 fps instead of the display refresh rate.
  /// The visual motion is intentionally slow (sub-Hz sine frequencies in
  /// _generateFlowLayers), so 30 fps is indistinguishable from 60 fps to the
  /// eye but halves CPU/GPU work for the four blurred + shader-masked layers.
  static const Duration _frameInterval = Duration(milliseconds: 33);

  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _elapsedOffset = Duration.zero;
  Duration _lastTickElapsed = Duration.zero;
  late ImageProvider _resizedArtProvider;
  late List<_FlowLayer> _layers;

  @override
  void initState() {
    super.initState();
    _refreshScene();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (elapsed - _lastTickElapsed < _frameInterval) return;
      _lastTickElapsed = elapsed;
      setState(() {
        _elapsed = _elapsedOffset + elapsed;
      });
    });
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ticker.muted = !TickerMode.valuesOf(context).enabled;
  }

  @override
  void didUpdateWidget(covariant _LiquidFlowBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artProvider != widget.artProvider) {
      _refreshScene();
    }
    if (oldWidget.animate != widget.animate) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    if (widget.animate) {
      _elapsedOffset = _elapsed;
      // The ticker's `elapsed` counter restarts from zero on every start(),
      // so the throttle baseline must restart too. Without this, the first
      // post-resume tick is compared against the pre-pause value and the
      // background can stay frozen for the duration of the pause before
      // the throttle gate opens again.
      _lastTickElapsed = Duration.zero;
      _ticker.start();
      return;
    }

    _ticker.stop();
  }

  void _refreshScene() {
    _resizedArtProvider = _createResizedArtProvider(widget.artProvider);
    _layers = _generateFlowLayers(widget.artProvider);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LiquidBackgroundScene(
      artProvider: _resizedArtProvider,
      layers: _layers,
      elapsed: _elapsed,
      motionStrength: 1,
    );
  }
}

class _LiquidBackgroundScene extends StatelessWidget {
  final ImageProvider artProvider;
  final List<_FlowLayer> layers;
  final Duration elapsed;
  final double motionStrength;

  const _LiquidBackgroundScene({
    required this.artProvider,
    required this.layers,
    required this.elapsed,
    required this.motionStrength,
  });

  double get _timeSeconds =>
      elapsed.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            _BaseTextureLayer(
              artProvider: artProvider,
              timeSeconds: _timeSeconds,
              motionStrength: motionStrength,
            ),
            for (final layer in layers)
              _LiquidMaterialLayer(
                artProvider: artProvider,
                layer: layer,
                timeSeconds: _timeSeconds,
                motionStrength: motionStrength,
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.46),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.08),
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.20)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseTextureLayer extends StatelessWidget {
  final ImageProvider artProvider;
  final double timeSeconds;
  final double motionStrength;

  const _BaseTextureLayer({
    required this.artProvider,
    required this.timeSeconds,
    required this.motionStrength,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(
      motionStrength *
          (0.045 * sin(timeSeconds * 0.061) +
              0.022 * sin(timeSeconds * 0.113 + 1.1)),
      motionStrength *
          (0.038 * cos(timeSeconds * 0.047 + 0.7) +
              0.026 * sin(timeSeconds * 0.089 + 2.4)),
    );
    final scale =
        1.22 +
        motionStrength *
            (0.055 * sin(timeSeconds * 0.031 + 0.4) +
                0.028 * cos(timeSeconds * 0.067 + 1.8));

    // Wrap the per-frame painting in its own RepaintBoundary so the four
    // _LiquidMaterialLayers above are composited from cached layers rather
    // than re-rasterized together. `Transform.scale` is used instead of
    // FractionallySizedBox(widthFactor: scale) so that scale changes do not
    // invalidate this subtree's layout every frame -- only paint.
    return Positioned.fill(
      child: RepaintBoundary(
        child: Align(
          alignment: alignment,
          child: Transform.scale(
            scale: scale,
            child: SizedBox.expand(
              child: Opacity(
                opacity: 0.56,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                  child: Image(
                    image: artProvider,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidMaterialLayer extends StatelessWidget {
  final ImageProvider artProvider;
  final _FlowLayer layer;
  final double timeSeconds;
  final double motionStrength;

  const _LiquidMaterialLayer({
    required this.artProvider,
    required this.layer,
    required this.timeSeconds,
    required this.motionStrength,
  });

  @override
  Widget build(BuildContext context) {
    final motionX =
        layer.driftX * sin(timeSeconds * layer.speedX + layer.phaseX) +
        layer.secondaryDriftX *
            sin(timeSeconds * layer.secondarySpeedX + layer.phaseY);
    final motionY =
        layer.driftY * cos(timeSeconds * layer.speedY + layer.phaseY) +
        layer.secondaryDriftY *
            sin(timeSeconds * layer.secondarySpeedY + layer.phaseX);
    final scale =
        layer.baseScale +
        motionStrength *
            (layer.scaleDrift *
                    sin(timeSeconds * layer.scaleSpeed + layer.phaseScale) +
                layer.scaleDrift *
                    0.45 *
                    cos(
                      timeSeconds * layer.secondaryScaleSpeed + layer.phaseX,
                    ));
    final rotation =
        layer.rotation +
        motionStrength *
            layer.rotationDrift *
            sin(timeSeconds * layer.rotationSpeed + layer.phaseRotation);

    return Positioned.fill(
      child: RepaintBoundary(
        child: Align(
          alignment: Alignment(
            layer.baseX + motionStrength * motionX,
            layer.baseY + motionStrength * motionY,
          ),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              // Use Transform.scale rather than FractionallySizedBox so the
              // per-frame scale changes only re-paint this layer, never
              // bubbling layout work up the tree.
              scaleX: layer.widthFactor * scale,
              scaleY: layer.heightFactor * scale,
              child: SizedBox.expand(
                child: Opacity(
                  opacity: layer.opacity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: layer.blurSigma,
                      sigmaY: layer.blurSigma,
                    ),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return RadialGradient(
                          center: Alignment(
                            layer.maskCenterX,
                            layer.maskCenterY,
                          ),
                          radius: layer.maskRadius,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white.withValues(alpha: 0.84),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.34, 0.72, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image(
                        image: artProvider,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, _, _) => const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ImageProvider _createResizedArtProvider(ImageProvider artProvider) {
  return ResizeImage(artProvider, width: 192, height: 192);
}

List<_FlowLayer> _generateFlowLayers(ImageProvider artProvider) {
  final motionSpeed = 3.5;
  final motionDrift = 4.5;
  final rng = Random();

  return List.generate(4, (index) {
    return _FlowLayer(
      widthFactor: 0.90 + rng.nextDouble() * 0.75,
      heightFactor: 0.88 + rng.nextDouble() * 0.72,
      baseX: _randomSignedRange(rng, 0.9),
      baseY: _randomSignedRange(rng, 0.8),
      driftX: motionDrift * (0.08 + rng.nextDouble() * 0.12),
      driftY: motionDrift * (0.07 + rng.nextDouble() * 0.11),
      secondaryDriftX: motionDrift * (0.03 + rng.nextDouble() * 0.08),
      secondaryDriftY: motionDrift * (0.03 + rng.nextDouble() * 0.07),
      rotation: rng.nextDouble() * pi * 2,
      rotationDrift: motionDrift * (0.05 + rng.nextDouble() * 0.10),
      baseScale: 0.94 + rng.nextDouble() * 0.18,
      scaleDrift: motionDrift * (0.05 + rng.nextDouble() * 0.06),
      opacity: 0.17 + rng.nextDouble() * 0.11,
      blurSigma: 24 + rng.nextDouble() * 18,
      maskRadius: 0.76 + rng.nextDouble() * 0.30,
      maskCenterX: _randomSignedRange(rng, 0.95),
      maskCenterY: _randomSignedRange(rng, 0.95),
      phaseX: rng.nextDouble() * pi * 2,
      phaseY: rng.nextDouble() * pi * 2,
      phaseScale: rng.nextDouble() * pi * 2,
      phaseRotation: rng.nextDouble() * pi * 2,
      speedX: 0.032 + rng.nextDouble() * 0.040,
      speedY: 0.029 + rng.nextDouble() * 0.042,
      secondarySpeedX: motionSpeed * (0.070 + rng.nextDouble() * 0.060),
      secondarySpeedY: motionSpeed * (0.066 + rng.nextDouble() * 0.058),
      scaleSpeed: motionSpeed * (0.020 + rng.nextDouble() * 0.020),
      secondaryScaleSpeed: motionSpeed * (0.044 + rng.nextDouble() * 0.030),
      rotationSpeed: motionSpeed * (0.018 + rng.nextDouble() * 0.028),
    );
  });
}

double _randomSignedRange(Random rng, double range) {
  return rng.nextDouble() * (range * 2) - range;
}

class _FlowLayer {
  final double widthFactor;
  final double heightFactor;
  final double baseX;
  final double baseY;
  final double driftX;
  final double driftY;
  final double secondaryDriftX;
  final double secondaryDriftY;
  final double rotation;
  final double rotationDrift;
  final double baseScale;
  final double scaleDrift;
  final double opacity;
  final double blurSigma;
  final double maskRadius;
  final double maskCenterX;
  final double maskCenterY;
  final double phaseX;
  final double phaseY;
  final double phaseScale;
  final double phaseRotation;
  final double speedX;
  final double speedY;
  final double secondarySpeedX;
  final double secondarySpeedY;
  final double scaleSpeed;
  final double secondaryScaleSpeed;
  final double rotationSpeed;

  const _FlowLayer({
    required this.widthFactor,
    required this.heightFactor,
    required this.baseX,
    required this.baseY,
    required this.driftX,
    required this.driftY,
    required this.secondaryDriftX,
    required this.secondaryDriftY,
    required this.rotation,
    required this.rotationDrift,
    required this.baseScale,
    required this.scaleDrift,
    required this.opacity,
    required this.blurSigma,
    required this.maskRadius,
    required this.maskCenterX,
    required this.maskCenterY,
    required this.phaseX,
    required this.phaseY,
    required this.phaseScale,
    required this.phaseRotation,
    required this.speedX,
    required this.speedY,
    required this.secondarySpeedX,
    required this.secondarySpeedY,
    required this.scaleSpeed,
    required this.secondaryScaleSpeed,
    required this.rotationSpeed,
  });
}
