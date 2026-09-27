import 'dart:io';

import 'package:flutter/foundation.dart';

import '../i18n/strings.g.dart';
import 'secret_store.dart';

String secretStoreFailureMessage(SecretStoreFailure failure) {
  final linux = !kIsWeb && Platform.isLinux;
  return switch (failure) {
    SecretStoreFailure.read =>
      linux
          ? t.settings.secureStorageReadFailedLinux
          : t.settings.secureStorageReadFailed,
    SecretStoreFailure.write =>
      linux
          ? t.settings.secureStorageWriteFailedLinux
          : t.settings.secureStorageWriteFailed,
  };
}
