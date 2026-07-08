import 'package:fluent_lyrics/widgets/screen/lyrics/artwork_image_sizing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snaps foreground album art cache dimensions to stable presets', () {
    expect(
      ArtworkImageSizing.foregroundCacheSizeForConstraints(
        const BoxConstraints.tightFor(width: 64, height: 64),
        devicePixelRatio: 1,
        large: false,
      ),
      64,
    );

    expect(
      ArtworkImageSizing.foregroundCacheSizeForConstraints(
        const BoxConstraints.tightFor(width: 64, height: 64),
        devicePixelRatio: 3,
        large: false,
      ),
      256,
    );

    expect(
      ArtworkImageSizing.foregroundCacheSizeForConstraints(
        const BoxConstraints.tightFor(width: 350, height: 350),
        devicePixelRatio: 1,
        large: true,
      ),
      512,
    );

    expect(
      ArtworkImageSizing.foregroundCacheSizeForConstraints(
        const BoxConstraints.tightFor(width: 700, height: 700),
        devicePixelRatio: 2,
        large: true,
      ),
      1536,
    );
  });

  test('limits foreground precache presets to the intrinsic image size', () {
    expect(
      ArtworkImageSizing.foregroundPrecacheSizes(
        intrinsicWidth: 500,
        intrinsicHeight: 500,
      ),
      [64, 128, 256, 512],
    );

    expect(
      ArtworkImageSizing.foregroundPrecacheSizes(
        intrinsicWidth: 32,
        intrinsicHeight: 32,
      ),
      [64],
    );

    expect(
      ArtworkImageSizing.foregroundPrecacheSizes(
        intrinsicWidth: 1000,
        intrinsicHeight: 500,
      ),
      [64, 128, 256, 512, 768, 1024],
    );

    expect(
      ArtworkImageSizing.foregroundPrecacheSizes(),
      ArtworkImageSizing.foregroundCacheSizes,
    );
  });
}
