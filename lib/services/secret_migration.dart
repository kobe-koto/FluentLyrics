class PlaintextSecret {
  const PlaintextSecret({required this.present, this.value});

  final bool present;
  final String? value;
}

class SecureSecretSnapshot {
  const SecureSecretSnapshot({required this.present, this.value});

  final bool present;
  final String? value;
}

class SecretMigrationPlan {
  const SecretMigrationPlan({
    required this.value,
    required this.writeToSecure,
    required this.deletePlaintext,
    required this.deleteSecure,
    required this.unavailable,
  });

  /// Secret to expose. Null means unset. Never a placeholder.
  final String? value;
  final bool writeToSecure;
  final bool deletePlaintext;
  final bool deleteSecure;
  final bool unavailable;
}

bool isRealSecret(String? value, Set<String> placeholders) {
  if (value == null) return false;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  return !placeholders.contains(value) && !placeholders.contains(trimmed);
}

/// Decides how to move one secret out of plaintext preferences.
///
/// A null [secure] snapshot means the store could not be opened. In that
/// case the plaintext copy is left untouched and must not be treated as a
/// successful read.
SecretMigrationPlan planSecretMigration({
  required SecureSecretSnapshot? secure,
  required PlaintextSecret plain,
  required Set<String> placeholders,
}) {
  if (secure == null) {
    return const SecretMigrationPlan(
      value: null,
      writeToSecure: false,
      deletePlaintext: false,
      deleteSecure: false,
      unavailable: true,
    );
  }

  if (secure.present && isRealSecret(secure.value, placeholders)) {
    return SecretMigrationPlan(
      value: secure.value,
      writeToSecure: false,
      deletePlaintext: plain.present,
      deleteSecure: false,
      unavailable: false,
    );
  }

  if (isRealSecret(plain.value, placeholders)) {
    return SecretMigrationPlan(
      value: plain.value,
      writeToSecure: true,
      deletePlaintext: true,
      deleteSecure: false,
      unavailable: false,
    );
  }

  return SecretMigrationPlan(
    value: null,
    writeToSecure: false,
    deletePlaintext: plain.present,
    deleteSecure: secure.present,
    unavailable: false,
  );
}
