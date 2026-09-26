import 'package:fluent_lyrics/constants/app_defaults.dart';
import 'package:fluent_lyrics/providers/lyrics_provider_settings.dart';
import 'package:fluent_lyrics/services/pref_setting.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mirrored settings load from one table', () async {
    SharedPreferences.setMockInitialValues({PrefSettings.fontSize.key: 42.0});
    final settings = await LyricsProviderSettings.load(SettingsService());

    expect(settings.fontSize.current, 42);
    expect(settings.fontSize.changed, isTrue);
    expect(
      settings.translationTargetLanguages.current,
      AppDefaults.translationTargetLanguages,
    );
    expect(settings.cacheEnabled.current, AppDefaults.cacheEnabled);
    expect(settings.llmTimeToFirstTokenSeconds.current, 60);
    expect(
      LyricsProviderSettings.defaults().artworkMinSize.current,
      AppDefaults.artworkMinSize,
    );
  });

  test('empty translation targets are stored as unset', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SettingsService();
    await service.setTranslationTargetLanguages(const []);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(PrefSettings.translationTargetLanguages.key),
      isFalse,
    );
  });
}
