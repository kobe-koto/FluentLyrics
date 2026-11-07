import 'package:flutter/material.dart';

import 'settings_colors.dart';

/// App-wide [ThemeData]. The lyrics screen always uses the dark variant.
ThemeData buildAppTheme({Brightness brightness = Brightness.dark}) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? Colors.black
        : Colors.white,
    fontFamily: 'Outfit',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontVariations: <FontVariation>[FontVariation('wght', 500)],
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w500,
        fontVariations: <FontVariation>[FontVariation('wght', 500)],
      ),
    ),
    fontFamilyFallback: const ['sans-serif'],
  );
}

/// Theme for settings and about pages, following the user's appearance
/// choice. Dialogs and menus opened from these pages inherit it.
ThemeData buildSettingsTheme(SettingsColors colors) {
  final base = buildAppTheme(brightness: colors.brightness);
  // Blue matches the hardcoded accent on switches, sliders, and checks.
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: colors.brightness,
  );
  final inputRadius = BorderRadius.circular(10);
  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.dialog,
    dialogTheme: DialogThemeData(backgroundColor: colors.dialog),
    popupMenuTheme: PopupMenuThemeData(color: colors.dialog),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.dialog),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.blue,
      selectionColor: Colors.blue.withValues(alpha: 0.3),
      selectionHandleColor: Colors.blue,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputFill,
      hoverColor: colors.fg(0.03),
      labelStyle: TextStyle(color: colors.fg(0.54)),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.focused)
              ? Colors.blue
              : colors.fg(0.54),
        );
      }),
      hintStyle: TextStyle(color: colors.fg(0.24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder(colors.fg(0.08)),
      enabledBorder: inputBorder(colors.fg(0.08)),
      disabledBorder: inputBorder(colors.fg(0.04)),
      focusedBorder: inputBorder(Colors.blue, 1.5),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 1.5),
    ),
    extensions: <ThemeExtension<dynamic>>[colors],
  );
}
