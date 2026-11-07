import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/lyric_provider_type.dart';

/// Square provider logo from `assets/provider_logos/`. Monochrome marks (LLM)
/// sit on a tinted disc in the provider color; the rest are full-color brand
/// marks drawn as shipped. [enabled] false renders the logo in grayscale.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    required this.type,
    this.size = 40,
    this.enabled = true,
  });

  final LyricProviderType type;
  final double size;
  final bool enabled;

  static const String noticeAsset = 'assets/provider_logos/NOTICE';

  /// Adds the logo sources, trademark notes, and the Font Awesome and thesvg
  /// licenses to the Flutter license page. The logos are bundled assets, so
  /// they would not show up there on their own.
  static void registerLicense() {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(const <String>[
        'Provider logos',
        'Font Awesome Free',
        'thesvg',
      ], await rootBundle.loadString(noticeAsset));
    });
  }

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final color = type.metadata['color'] as Color;
    final asset = type.logoAsset;
    final Widget logo;
    if (asset == null || type == LyricProviderType.llm) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: asset == null
            ? Icon(Icons.library_music, size: size * 0.5, color: color)
            : SvgPicture.asset(
                asset,
                width: size * 0.5,
                height: size * 0.5,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                excludeFromSemantics: true,
              ),
      );
    } else {
      logo = SvgPicture.asset(
        asset,
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: enabled
          ? logo
          : ColorFiltered(colorFilter: _grayscale, child: logo),
    );
  }
}
