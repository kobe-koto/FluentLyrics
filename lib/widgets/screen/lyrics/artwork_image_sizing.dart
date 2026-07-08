import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ArtworkImageSizing {
  static const int portraitThumbLogicalSize = 64;

  /// Stable decode-size buckets for foreground album art.
  ///
  /// Snapping to these buckets avoids creating a new [ResizeImage] cache key
  /// for every intermediate window size while the user drags the window.
  static const List<int> foregroundCacheSizes = [
    64,
    128,
    256,
    512,
    768,
    1024,
    1536,
  ];

  static int foregroundCacheSizeForConstraints(
    BoxConstraints constraints, {
    required double devicePixelRatio,
    required bool large,
  }) {
    final logicalSide = large
        ? _finiteSideFor(constraints)
        : portraitThumbLogicalSize.toDouble();
    final targetPhysicalSize = logicalSide * devicePixelRatio;
    return _ceilToPreset(targetPhysicalSize);
  }

  static List<ImageProvider> foregroundPrecacheProviders(
    ImageProvider provider, {
    int? intrinsicWidth,
    int? intrinsicHeight,
  }) {
    return [
      for (final size in foregroundPrecacheSizes(
        intrinsicWidth: intrinsicWidth,
        intrinsicHeight: intrinsicHeight,
      ))
        ResizeImage(provider, width: size, height: size),
    ];
  }

  static List<int> foregroundPrecacheSizes({
    int? intrinsicWidth,
    int? intrinsicHeight,
  }) {
    if (intrinsicWidth == null ||
        intrinsicHeight == null ||
        intrinsicWidth <= 0 ||
        intrinsicHeight <= 0) {
      return foregroundCacheSizes;
    }

    final maxUsefulSize = math.max(intrinsicWidth, intrinsicHeight);
    final sizes = <int>[];

    for (final size in foregroundCacheSizes) {
      sizes.add(size);
      if (size >= maxUsefulSize) break;
    }

    return sizes;
  }

  static double _finiteSideFor(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight;

    if (maxWidth.isFinite && maxHeight.isFinite) {
      return math.min(maxWidth, maxHeight);
    }
    if (maxWidth.isFinite) return maxWidth;
    if (maxHeight.isFinite) return maxHeight;

    return portraitThumbLogicalSize.toDouble();
  }

  static int _ceilToPreset(double targetPhysicalSize) {
    final target = targetPhysicalSize.isFinite && targetPhysicalSize > 0
        ? targetPhysicalSize.ceil()
        : foregroundCacheSizes.first;

    for (final size in foregroundCacheSizes) {
      if (size >= target) return size;
    }

    return foregroundCacheSizes.last;
  }
}
