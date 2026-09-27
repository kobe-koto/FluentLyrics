import 'package:fluent_lyrics/constants/app_defaults.dart';
import 'package:fluent_lyrics/services/pref_setting.dart';
import 'package:fluent_lyrics/services/secret_store.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a plaintext API key migrates and is then deleted', () async {
    SharedPreferences.setMockInitialValues({
      PrefSettings.llmApiKey.key: 'sk-live',
    });
    final store = MemorySecretStore();
    final service = SettingsService(secretStore: store);

    final setting = await service.getLlmApiKey();

    expect(setting.current, 'sk-live');
    expect(setting.changed, isTrue);
    expect(store.values[PrefSettings.llmApiKey.key], 'sk-live');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(PrefSettings.llmApiKey.key), isFalse);
  });

  test('the dummy API key is not written to secure storage', () async {
    SharedPreferences.setMockInitialValues({
      PrefSettings.llmApiKey.key: AppDefaults.llmApiKey,
    });
    final store = MemorySecretStore();
    final service = SettingsService(secretStore: store);

    final setting = await service.getLlmApiKey();

    expect(setting.current, AppDefaults.llmApiKey);
    expect(setting.changed, isFalse);
    expect(store.values, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(PrefSettings.llmApiKey.key), isFalse);
  });

  test('a failed open does not return or erase the plaintext key', () async {
    SharedPreferences.setMockInitialValues({
      PrefSettings.llmApiKey.key: 'sk-live',
      PrefSettings.musixmatchToken.key: 'mxm-token',
    });
    final service = SettingsService(secretStore: _FailingSecretStore());

    await expectLater(
      service.getLlmApiKey(),
      throwsA(isA<SecretStoreException>()),
    );
    final mirrored = await service.readSetting(PrefSettings.llmApiKey);
    expect(mirrored.current, AppDefaults.llmApiKey);
    expect(service.secretStoreFailure, SecretStoreFailure.read);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrefSettings.llmApiKey.key), 'sk-live');
    expect(prefs.getString(PrefSettings.musixmatchToken.key), 'mxm-token');
  });

  test('clearing a loaded token removes it from secure storage', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MemorySecretStore({PrefSettings.musixmatchToken.key: 'mxm'});
    final service = SettingsService(secretStore: store);

    await service.setMusixmatchToken('');

    expect(store.values.containsKey(PrefSettings.musixmatchToken.key), isFalse);
    final setting = await service.getMusixmatchToken();
    expect(setting.current, isNull);
  });

  test('a placeholder save does not erase an unread plaintext token', () async {
    SharedPreferences.setMockInitialValues({
      PrefSettings.musixmatchToken.key: 'mxm-token',
    });
    final store = MemorySecretStore();
    final service = SettingsService(secretStore: store);

    await service.setMusixmatchToken('');

    expect(store.values, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrefSettings.musixmatchToken.key), 'mxm-token');
  });

  test(
    'saving a new key replaces plaintext after the store accepts it',
    () async {
      SharedPreferences.setMockInitialValues({
        PrefSettings.llmApiKey.key: 'sk-old',
      });
      final store = MemorySecretStore();
      final service = SettingsService(secretStore: store);

      await service.setLlmApiKey('sk-new');

      expect(store.values[PrefSettings.llmApiKey.key], 'sk-new');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(PrefSettings.llmApiKey.key), isFalse);
      expect((await service.getLlmApiKey()).current, 'sk-new');
    },
  );

  test('a failed migration write leaves the plaintext key in place', () async {
    SharedPreferences.setMockInitialValues({
      PrefSettings.llmApiKey.key: 'sk-live',
    });
    final service = SettingsService(secretStore: _WriteFailingSecretStore());

    await expectLater(
      service.getLlmApiKey(),
      throwsA(isA<SecretStoreException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrefSettings.llmApiKey.key), 'sk-live');
  });
}

class _WriteFailingSecretStore implements SecretStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {
    throw const SecretStoreException(SecretStoreFailure.write);
  }
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
