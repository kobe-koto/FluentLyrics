import 'package:flutter/material.dart';

import '../theme/settings_colors.dart';

/// Accent for a tinted settings action button.
enum SettingsButtonTone {
  positive(Colors.green, Colors.greenAccent, Color(0xFF2E7D32)),
  info(Colors.blue, Colors.blueAccent, Color(0xFF1976D2)),
  warning(Colors.orange, Colors.orange, Color(0xFFE65100)),
  danger(Colors.red, Colors.redAccent, Color(0xFFD32F2F));

  const SettingsButtonTone(
    this.fill,
    this.darkForeground,
    this.lightForeground,
  );

  final Color fill;
  final Color darkForeground;

  /// Darker shade so the label keeps contrast on a light tint.
  final Color lightForeground;
}

/// Flat tinted button style used by settings actions. Elevation stays 0 in
/// every state so hover does not lift a shadow or surface tint.
ButtonStyle settingsTonalButtonStyle(
  BuildContext context,
  SettingsButtonTone tone,
) {
  final colors = context.settingsColors;
  return ElevatedButton.styleFrom(
    backgroundColor: tone.fill.withValues(alpha: colors.isDark ? 0.2 : 0.14),
    foregroundColor: colors.isDark ? tone.darkForeground : tone.lightForeground,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ).copyWith(elevation: const WidgetStatePropertyAll<double>(0));
}
