import '../utils/app_logger.dart';
import 'secret_migration.dart';
import 'secret_store.dart';

class SecretSettings {
  SecretSettings(this._store);

  final SecretStore _store;
  static final Map<String, Future<void>> _tails = {};

  Future<SecretMigrationPlan> resolve({
    required String key,
    required PlaintextSecret plain,
    required Set<String> placeholders,
    bool Function(String value)? placeholderWhen,
    required Future<void> Function() deletePlaintext,
  }) {
    return _locked(key, () async {
      final SecureSecretSnapshot? secure;
      try {
        final stored = await _store.read(key);
        secure = SecureSecretSnapshot(present: stored != null, value: stored);
      } on SecretStoreException {
        return planSecretMigration(
          secure: null,
          plain: plain,
          placeholders: placeholders,
          placeholderWhen: placeholderWhen,
        );
      }

      final plan = planSecretMigration(
        secure: secure,
        plain: plain,
        placeholders: placeholders,
        placeholderWhen: placeholderWhen,
      );
      if (plan.writeToSecure) {
        try {
          await _store.write(key, plan.value!);
        } on SecretStoreException {
          return planSecretMigration(
            secure: null,
            plain: plain,
            placeholders: placeholders,
            placeholderWhen: placeholderWhen,
          );
        }
      } else if (plan.deleteSecure) {
        await _store.delete(key);
      }
      if (plan.deletePlaintext) {
        await _dropPlaintext(key, deletePlaintext);
      }
      return plan;
    });
  }

  /// Writes [value], or deletes it when it is empty or a placeholder.
  ///
  /// Plaintext is removed only after the secure store accepts the write, or
  /// when a clear can see that the secure store no longer holds the secret.
  /// A placeholder save does not erase a plaintext copy the caller was unable
  /// to load.
  Future<void> save({
    required String key,
    required String? value,
    required PlaintextSecret plain,
    required Set<String> placeholders,
    bool Function(String value)? placeholderWhen,
    required Future<void> Function() deletePlaintext,
  }) {
    return _locked(key, () async {
      if (isRealSecret(value, placeholders, placeholderWhen: placeholderWhen)) {
        await _store.write(key, value!);
        await _dropPlaintext(key, deletePlaintext);
        return;
      }

      final existing = await _store.read(key);
      final secureWasReal = isRealSecret(
        existing,
        placeholders,
        placeholderWhen: placeholderWhen,
      );
      final plainIsReal =
          plain.present &&
          isRealSecret(
            plain.value,
            placeholders,
            placeholderWhen: placeholderWhen,
          );
      if (!secureWasReal && plainIsReal) {
        return;
      }
      await _store.delete(key);
      await _dropPlaintext(key, deletePlaintext);
    });
  }

  Future<void> _dropPlaintext(
    String key,
    Future<void> Function() deletePlaintext,
  ) async {
    try {
      await deletePlaintext();
    } catch (error) {
      AppLogger.debug(
        '[SecretStore] plaintext cleanup failed for $key: ${error.runtimeType}',
      );
    }
  }

  Future<T> _locked<T>(String key, Future<T> Function() action) {
    final previous = _tails[key] ?? Future<void>.value();
    final gate = previous.then((_) => action());
    _tails[key] = gate.then((_) {}, onError: (_) {});
    return gate;
  }
}
