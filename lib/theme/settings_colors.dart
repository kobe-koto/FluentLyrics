import 'package:flutter/material.dart';

import '../providers/appearance_controller.dart';

/// Persisted theme choice for the settings and about pages.
enum SettingsThemeMode {
  system,
  light,
  dark;

  static SettingsThemeMode fromName(String? name) {
    return SettingsThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => SettingsThemeMode.dark,
    );
  }
}

/// Neutral color tokens for the settings and about pages.
///
/// Most of the settings UI draws neutrals as a translucent [ink] over
/// [background]: white on dark, black on light. [fg] keeps that model so
/// one alpha reads the same in every variant. Accent colors (switches,
/// provider tags) stay hardcoded at the call site.
@immutable
class SettingsColors extends ThemeExtension<SettingsColors> {
  const SettingsColors({
    required this.brightness,
    required this.background,
    required this.ink,
    required this.onSurface,
    required this.card,
    required this.cardBorder,
    required this.dialog,
    required this.inputFill,
    required this.inkScale,
  });

  /// Default dark, roughly M3 tone 2 background with tone 8 cards.
  static const dark = SettingsColors(
    brightness: Brightness.dark,
    background: Color(0xFF0C0C0C),
    ink: Colors.white,
    onSurface: Colors.white,
    card: Color(0x0DFFFFFF),
    cardBorder: Color(0x0DFFFFFF),
    dialog: Color(0xFF1A1A1A),
    inputFill: Colors.black26,
    inkScale: 1,
  );

  /// OLED dark. Cards get a little more fill so they still separate from
  /// pure black.
  static const pureBlack = SettingsColors(
    brightness: Brightness.dark,
    background: Colors.black,
    ink: Colors.white,
    onSurface: Colors.white,
    card: Color(0x12FFFFFF),
    cardBorder: Color(0x0FFFFFFF),
    dialog: Color(0xFF141414),
    inputFill: Color(0x0AFFFFFF),
    inkScale: 1,
  );

  /// Light. Cards sit darker than the background, like M3 light containers.
  /// Dark ink on light needs more alpha to match the dark variant's contrast.
  static const light = SettingsColors(
    brightness: Brightness.light,
    background: Color(0xFFF7F7F7),
    ink: Colors.black,
    onSurface: Color(0xFF161616),
    card: Color(0x0D000000),
    cardBorder: Color(0x0F000000),
    dialog: Colors.white,
    inputFill: Colors.white,
    inkScale: 1.2,
  );

  static SettingsColors resolve({
    required SettingsThemeMode mode,
    required bool pureBlack,
    required Brightness platformBrightness,
  }) {
    final isDark = switch (mode) {
      SettingsThemeMode.system => platformBrightness == Brightness.dark,
      SettingsThemeMode.light => false,
      SettingsThemeMode.dark => true,
    };
    if (!isDark) return light;
    return pureBlack ? SettingsColors.pureBlack : dark;
  }

  /// Colors from the nearest settings [Theme]. A context above
  /// `SettingsScaffold` (a screen's own build method) has no extension, so it
  /// resolves from [AppearanceScope] instead.
  static SettingsColors of(BuildContext context) {
    final fromTheme = Theme.of(context).extension<SettingsColors>();
    if (fromTheme != null) return fromTheme;
    final controller = AppearanceScope.maybeOf(context);
    if (controller == null) return dark;
    return controller.resolve(MediaQuery.platformBrightnessOf(context));
  }

  final Brightness brightness;
  final Color background;

  /// Base color for translucent neutrals. Use [fg] rather than this directly.
  final Color ink;

  /// Primary text and icons.
  final Color onSurface;
  final Color card;
  final Color cardBorder;

  /// Dialogs, dropdown menus, and other raised surfaces.
  final Color dialog;

  /// Text field fill inside a card.
  final Color inputFill;

  /// Multiplier applied to [fg] alpha.
  final double inkScale;

  bool get isDark => brightness == Brightness.dark;

  /// Translucent neutral at roughly the same contrast as `white` at [alpha]
  /// on the dark variant.
  Color fg(double alpha) {
    return ink.withValues(alpha: (alpha * inkScale).clamp(0.0, 1.0));
  }

  @override
  SettingsColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? ink,
    Color? onSurface,
    Color? card,
    Color? cardBorder,
    Color? dialog,
    Color? inputFill,
    double? inkScale,
  }) {
    return SettingsColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      ink: ink ?? this.ink,
      onSurface: onSurface ?? this.onSurface,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      dialog: dialog ?? this.dialog,
      inputFill: inputFill ?? this.inputFill,
      inkScale: inkScale ?? this.inkScale,
    );
  }

  @override
  SettingsColors lerp(SettingsColors? other, double t) {
    if (other == null) return this;
    return SettingsColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      dialog: Color.lerp(dialog, other.dialog, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inkScale: inkScale + (other.inkScale - inkScale) * t,
    );
  }
}

extension SettingsColorsContext on BuildContext {
  SettingsColors get settingsColors => SettingsColors.of(this);
}
