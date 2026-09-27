import 'package:fluent_lyrics/constants/app_defaults.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider_settings.dart';
import 'package:fluent_lyrics/services/pref_setting.dart';
import 'package:fluent_lyrics/services/secret_store.dart';
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

  test('mirrored secure settings keep a concrete Setting type', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemorySecretStore({PrefSettings.llmApiKey.key: 'sk-live'});
    final service = SettingsService(secretStore: store);
    final dynamicSpec = PrefSettings.mirrored.firstWhere(
      (spec) => spec.key == PrefSettings.llmApiKey.key,
    );

    final read = await service.readSetting(dynamicSpec);
    expect(read, isA<Setting<String>>());
    expect(read.current, 'sk-live');

    final settings = await LyricsProviderSettings.load(service);
    expect(settings.llmApiKey, isA<Setting<String>>());
    expect(settings.llmApiKey.current, 'sk-live');
    expect(settings.llmApiKey.changed, isTrue);
  });

  test(
    'a failed secure read returns a concrete setting and keeps plaintext',
    () async {
      SharedPreferences.setMockInitialValues({
        PrefSettings.llmApiKey.key: 'sk-live',
      });
      final service = SettingsService(secretStore: _FailingSecretStore());

      final settings = await LyricsProviderSettings.load(service);

      expect(settings.llmApiKey, isA<Setting<String>>());
      expect(settings.llmApiKey.current, AppDefaults.llmApiKey);
      expect(settings.llmApiKey.changed, isFalse);
      expect(service.secretStoreFailure, SecretStoreFailure.read);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefSettings.llmApiKey.key), 'sk-live');
    },
  );

  test('secret settings keep their row type when the caller erased T', () {
    final PrefSetting<dynamic> apiKey = PrefSettings.llmApiKey;
    final live = apiKey.settingFromSecret('sk-live');
    expect(live, isA<Setting<String>>());
    expect(live.current, 'sk-live');
    expect(live.changed, isTrue);

    final unset = apiKey.settingFromSecret(null);
    expect(unset, isA<Setting<String>>());
    expect(unset.current, AppDefaults.llmApiKey);
    expect(unset.changed, isFalse);

    final PrefSetting<dynamic> token = PrefSettings.musixmatchToken;
    final empty = token.settingFromSecret(null);
    expect(empty, isA<Setting<String?>>());
    expect(empty.current, isNull);
    expect(empty.changed, isFalse);
  });
}

class _FailingSecretStore implements SecretStore {
  @override
  Future<void> delete(String key) async {
    throw const SecretStoreException(SecretStoreFailure.write);
  }

  @override
  Future<String?> read(String key) async {
    throw const SecretStoreException(SecretStoreFailure.read);
  }

  @override
  Future<void> write(String key, String value) async {
    throw const SecretStoreException(SecretStoreFailure.write);
  }
}
