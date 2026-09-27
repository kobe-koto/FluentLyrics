import 'package:fluent_lyrics/services/secret_migration.dart';
import 'package:fluent_lyrics/services/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const placeholders = {'sk-dummy'};

  test('a stored secret wins and plaintext is deleted', () {
    final plan = planSecretMigration(
      secure: const SecureSecretSnapshot(present: true, value: 'sk-live'),
      plain: const PlaintextSecret(present: true, value: 'sk-old'),
      placeholders: placeholders,
    );

    expect(plan.value, 'sk-live');
    expect(plan.writeToSecure, isFalse);
    expect(plan.deletePlaintext, isTrue);
    expect(plan.deleteSecure, isFalse);
    expect(plan.unavailable, isFalse);
  });

  test('plaintext migrates when secure storage is empty', () {
    final plan = planSecretMigration(
      secure: const SecureSecretSnapshot(present: false),
      plain: const PlaintextSecret(present: true, value: 'sk-live'),
      placeholders: placeholders,
    );

    expect(plan.value, 'sk-live');
    expect(plan.writeToSecure, isTrue);
    expect(plan.deletePlaintext, isTrue);
    expect(plan.unavailable, isFalse);
  });

  test('placeholder plaintext is dropped and not stored', () {
    final plan = planSecretMigration(
      secure: const SecureSecretSnapshot(present: false),
      plain: const PlaintextSecret(present: true, value: 'sk-dummy'),
      placeholders: placeholders,
    );

    expect(plan.value, isNull);
    expect(plan.writeToSecure, isFalse);
    expect(plan.deletePlaintext, isTrue);
    expect(plan.deleteSecure, isFalse);
  });

  test('an unavailable store does not expose or erase plaintext', () {
    final plan = planSecretMigration(
      secure: null,
      plain: const PlaintextSecret(present: true, value: 'sk-live'),
      placeholders: placeholders,
    );

    expect(plan.value, isNull);
    expect(plan.writeToSecure, isFalse);
    expect(plan.deletePlaintext, isFalse);
    expect(plan.deleteSecure, isFalse);
    expect(plan.unavailable, isTrue);
  });

  test('empty and whitespace values are not secrets', () {
    expect(isRealSecret(null, placeholders), isFalse);
    expect(isRealSecret('', placeholders), isFalse);
    expect(isRealSecret('   ', placeholders), isFalse);
    expect(isRealSecret(' sk-dummy ', placeholders), isFalse);
    expect(isRealSecret('sk-live', placeholders), isTrue);
  });

  test('scrubSecret removes the secret before a log line', () {
    expect(
      scrubSecret('write failed for sk-live token', 'sk-live'),
      'write failed for [redacted] token',
    );
    expect(scrubSecret('locked keyring', null), 'locked keyring');
  });
}
