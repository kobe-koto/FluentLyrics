import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/providers/appearance_controller.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:fluent_lyrics/theme/settings_colors.dart';
import 'package:fluent_lyrics/widgets/settings_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('defaults to dark without pure black', () {
    final controller = AppearanceController(settingsService: SettingsService());
    expect(controller.themeMode, SettingsThemeMode.dark);
    expect(controller.pureBlack, isFalse);
    expect(controller.resolve(Brightness.light), SettingsColors.dark);
  });

  test('persists theme mode and pure black across loads', () async {
    final first = AppearanceController(settingsService: SettingsService());
    await first.setThemeMode(SettingsThemeMode.light);
    await first.setPureBlack(true);

    final second = AppearanceController(settingsService: SettingsService());
    await second.load();
    expect(second.themeMode, SettingsThemeMode.light);
    expect(second.pureBlack, isTrue);
  });

  test('unknown stored mode falls back to dark', () async {
    SharedPreferences.setMockInitialValues({'settings_theme_mode': 'sepia'});
    final controller = AppearanceController(settingsService: SettingsService());
    await controller.load();
    expect(controller.themeMode, SettingsThemeMode.dark);
  });

  test('resolve follows platform brightness and pure black', () {
    SettingsColors resolve(SettingsThemeMode mode, bool black, Brightness b) {
      return SettingsColors.resolve(
        mode: mode,
        pureBlack: black,
        platformBrightness: b,
      );
    }

    expect(
      resolve(SettingsThemeMode.system, false, Brightness.light),
      SettingsColors.light,
    );
    expect(
      resolve(SettingsThemeMode.system, true, Brightness.dark),
      SettingsColors.pureBlack,
    );
    expect(
      resolve(SettingsThemeMode.dark, false, Brightness.dark),
      SettingsColors.dark,
    );
    // Pure black only applies to dark.
    expect(
      resolve(SettingsThemeMode.light, true, Brightness.dark),
      SettingsColors.light,
    );
  });

  testWidgets('settings scaffold follows the controller', (tester) async {
    final controller = AppearanceController(settingsService: SettingsService());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppearanceScope(
        controller: controller,
        child: const MaterialApp(
          home: SettingsScaffold(title: 'Settings', child: SizedBox()),
        ),
      ),
    );

    Color background() {
      return tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;
    }

    expect(background(), SettingsColors.dark.background);

    await controller.setThemeMode(SettingsThemeMode.light);
    await tester.pumpAndSettle();
    expect(background(), SettingsColors.light.background);

    await controller.setThemeMode(SettingsThemeMode.dark);
    await controller.setPureBlack(true);
    await tester.pumpAndSettle();
    expect(background(), Colors.black);
  });
}
