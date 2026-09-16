import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'opencc_bindings.dart';

/// OpenCC conversion configs. The id is the config file name, e.g. `s2t` maps
/// to `s2t.json` in the OpenCC data directory.
enum ZhConfig {
  s2t('s2t'),
  t2s('t2s'),
  s2tw('s2tw'),
  tw2s('tw2s'),
  s2twp('s2twp'),
  tw2sp('tw2sp'),
  s2hk('s2hk'),
  hk2s('hk2s'),
  t2tw('t2tw'),
  tw2t('tw2t'),
  t2hk('t2hk'),
  hk2t('hk2t');

  const ZhConfig(this.id);

  final String id;

  String get fileName => '$id.json';
}

class OpenCcException implements Exception {
  OpenCcException(this.message);

  final String message;

  @override
  String toString() => 'OpenCcException: $message';
}

/// Loads libopencc from an explicit [path], used by tests and hosts that ship
/// their own copy (see `tool/build_opencc.sh`). App builds get the library from
/// the native asset built by `hook/build.dart` instead.
DynamicLibrary loadOpenCcLibrary({required String path}) =>
    DynamicLibrary.open(path);

/// A loaded OpenCC conversion config.
///
/// OpenCC resolves the dictionaries referenced by a config relative to the
/// config file, so [dataDirectory] must contain `<config>.json` plus the
/// dictionary files it refers to. Call [dispose] to release the native handle.
class ZhConverter {
  ZhConverter._(this._bindings, this.config, this._handle);

  final OpenCcBindings _bindings;
  final ZhConfig config;
  Pointer<Void> _handle;
  bool _disposed = false;

  /// Opens [config] using the config/dictionary files in [dataDirectory].
  ///
  /// [libraryPath] loads a specific libopencc (tests, host builds); without it
  /// the library bundled as a native asset is used.
  factory ZhConverter.open(
    ZhConfig config, {
    required String dataDirectory,
    String? libraryPath,
  }) {
    final bindings = libraryPath == null
        ? const NativeAssetOpenCcBindings()
        : DynamicLibraryOpenCcBindings(loadOpenCcLibrary(path: libraryPath));
    final configPath =
        '${dataDirectory.replaceAll(RegExp(r'[\\/]+\$'), '')}/${config.fileName}';
    final namePtr = configPath.toNativeUtf8();
    try {
      final handle = bindings.open(namePtr);
      if (handle == nullptr) {
        throw OpenCcException(
          'Failed to open ${config.fileName}: ${bindings.error().toDartString()}',
        );
      }
      return ZhConverter._(bindings, config, handle);
    } finally {
      malloc.free(namePtr);
    }
  }

  /// Converts [text], passing non-Chinese content through unchanged.
  String convert(String text) {
    if (_disposed) throw StateError('ZhConverter for ${config.id} is disposed');
    if (text.isEmpty) return text;

    final inputPtr = text.toNativeUtf8();
    Pointer<Utf8> outputPtr = nullptr;
    try {
      outputPtr = _bindings.convertUtf8(_handle, inputPtr, inputPtr.length);
      if (outputPtr == nullptr) {
        throw OpenCcException(
          'Conversion failed for ${config.id}: ${_bindings.error().toDartString()}',
        );
      }
      return outputPtr.toDartString();
    } finally {
      malloc.free(inputPtr);
      if (outputPtr != nullptr) _bindings.convertUtf8Free(outputPtr);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _bindings.close(_handle);
    _handle = nullptr;
  }
}
