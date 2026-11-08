import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:fluent_lyrics/utils/app_locale_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(String?, String?)> readWith(String? saved) async {
    SharedPreferences.setMockInitialValues({'app_locale': ?saved});
    final code = await SettingsService().getLocale();
    final prefs = await SharedPreferences.getInstance();
    return (code, prefs.getString('app_locale'));
  }

  test(
    'legacy region codes migrate to script codes and are rewritten',
    () async {
      for (final (legacy, migrated) in const [
        ('zh-CN', 'zh_Hans'),
        ('zh_CN', 'zh_Hans'),
        ('zh-TW', 'zh_Hant'),
        ('zh_TW', 'zh_Hant'),
      ]) {
        expect(await readWith(legacy), (migrated, migrated), reason: legacy);
      }
    },
  );

  test('current codes, unknown values, and unset are left alone', () async {
    for (final saved in const ['en', 'zh_Hans', 'zh_Hant', 'fr']) {
      expect(await readWith(saved), (saved, saved), reason: saved);
    }
    expect(await readWith(null), (null, null));
  });

  test('every locale round-trips through its saved code', () {
    for (final locale in AppLocale.values) {
      expect(appLocaleFromCode(appLocaleCode(locale)), locale);
    }
    expect(appLocaleCode(AppLocale.zhCn), 'zh_Hans');
    expect(appLocaleCode(AppLocale.zhTw), 'zh_Hant');
    expect(appLocaleFromCode('zh-CN'), isNull);
  });
}
