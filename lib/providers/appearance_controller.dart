import 'package:flutter/widgets.dart';

import '../services/pref_setting.dart';
import '../services/settings_service.dart';
import '../theme/settings_colors.dart';

/// Theme choice for settings and about pages. Kept out of [LyricsProvider]
/// so playback notifications do not rebuild the app theme.
class AppearanceController extends ChangeNotifier {
  AppearanceController({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  SettingsThemeMode _themeMode = SettingsThemeMode.fromName(
    PrefSettings.settingsThemeMode.defaultValue,
  );
  bool _pureBlack = PrefSettings.settingsPureBlack.defaultValue;

  SettingsThemeMode get themeMode => _themeMode;
  bool get pureBlack => _pureBlack;

  Future<void> load() async {
    final mode = await _settingsService.readSetting(
      PrefSettings.settingsThemeMode,
    );
    final pureBlack = await _settingsService.readSetting(
      PrefSettings.settingsPureBlack,
    );
    _themeMode = SettingsThemeMode.fromName(mode.current);
    _pureBlack = pureBlack.current;
    notifyListeners();
  }

  Future<void> setThemeMode(SettingsThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _settingsService.writeSetting(
      PrefSettings.settingsThemeMode,
      mode.name,
    );
  }

  Future<void> setPureBlack(bool enabled) async {
    if (enabled == _pureBlack) return;
    _pureBlack = enabled;
    notifyListeners();
    await _settingsService.writeSetting(
      PrefSettings.settingsPureBlack,
      enabled,
    );
  }

  SettingsColors resolve(Brightness platformBrightness) {
    return SettingsColors.resolve(
      mode: _themeMode,
      pureBlack: _pureBlack,
      platformBrightness: platformBrightness,
    );
  }
}

/// Exposes the [AppearanceController] to settings pages. Pages built without
/// one (tests, previews) fall back to the default dark colors.
class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppearanceController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppearanceScope>()
        ?.notifier;
  }
}
