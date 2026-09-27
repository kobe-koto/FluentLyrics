import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_logger.dart';

enum SecretStoreFailure { read, write }

/// A secure-storage failure. [toString] is safe to show: it never includes
/// the secret or the raw platform error.
class SecretStoreException implements Exception {
  const SecretStoreException(this.failure);

  final SecretStoreFailure failure;

  @override
  String toString() {
    return switch (failure) {
      SecretStoreFailure.read =>
        'Secure storage could not be read. The saved secret was not used.',
      SecretStoreFailure.write =>
        'Secure storage could not be written. The secret was not saved.',
    };
  }
}

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

/// Android Keystore, macOS login keychain, and Linux libsecret.
///
/// macOS uses the legacy keychain so a build does not need Keychain Sharing
/// or a provisioning profile. Android does not wipe stored secrets on a
/// cipher error; the caller surfaces the failure instead.
class FlutterSecureSecretStore implements SecretStore {
  FlutterSecureSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? defaultStorage;

  static const FlutterSecureStorage defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    lOptions: LinuxOptions(),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) {
    return _guard(
      key,
      () => _storage.delete(key: key),
      SecretStoreFailure.write,
    );
  }

  @override
  Future<String?> read(String key) {
    return _guard(key, () => _storage.read(key: key), SecretStoreFailure.read);
  }

  @override
  Future<void> write(String key, String value) {
    return _guard(
      key,
      () => _storage.write(key: key, value: value),
      SecretStoreFailure.write,
      secret: value,
    );
  }
}

Future<T> _guard<T>(
  String key,
  Future<T> Function() action,
  SecretStoreFailure failure, {
  String? secret,
}) async {
  try {
    return await action();
  } on SecretStoreException {
    rethrow;
  } catch (error) {
    AppLogger.debug(
      '[SecretStore] $failure failed for $key: ${scrubSecret(error.toString(), secret)}',
    );
    throw SecretStoreException(failure);
  }
}

/// Removes a secret from a platform error before it is logged.
String scrubSecret(String text, String? secret) {
  var scrubbed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (secret != null && secret.isNotEmpty) {
    scrubbed = scrubbed.replaceAll(secret, '[redacted]');
  }
  if (scrubbed.length > 180) {
    scrubbed = '${scrubbed.substring(0, 180)}…';
  }
  return scrubbed;
}
