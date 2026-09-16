import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Asset id of the libopencc built by `hook/build.dart`. The last path segment
/// must match the `name` passed to `CodeAsset` in the build hook.
const String openCcAssetId =
    'package:fluent_lyrics/services/opencc/opencc_bindings.dart';

// Stable C API from src/opencc.h, resolved from the bundled native asset.
// Keep the signatures in sync with the OpenCC version pinned in
// third_party/opencc.
@Native<Pointer<Void> Function(Pointer<Utf8>)>(
  assetId: openCcAssetId,
  symbol: 'opencc_open',
)
external Pointer<Void> _openccOpen(Pointer<Utf8> configFileName);

@Native<Int32 Function(Pointer<Void>)>(
  assetId: openCcAssetId,
  symbol: 'opencc_close',
)
external int _openccClose(Pointer<Void> opencc);

@Native<Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, IntPtr)>(
  assetId: openCcAssetId,
  symbol: 'opencc_convert_utf8',
)
external Pointer<Utf8> _openccConvertUtf8(
  Pointer<Void> opencc,
  Pointer<Utf8> input,
  int length,
);

@Native<Void Function(Pointer<Utf8>)>(
  assetId: openCcAssetId,
  symbol: 'opencc_convert_utf8_free',
)
external void _openccConvertUtf8Free(Pointer<Utf8> str);

@Native<Pointer<Utf8> Function()>(
  assetId: openCcAssetId,
  symbol: 'opencc_error',
)
external Pointer<Utf8> _openccError();

typedef OpenccOpenNative = Pointer<Void> Function(Pointer<Utf8> configFileName);
typedef OpenccOpenDart = Pointer<Void> Function(Pointer<Utf8> configFileName);

typedef OpenccCloseNative = Int32 Function(Pointer<Void> opencc);
typedef OpenccCloseDart = int Function(Pointer<Void> opencc);

typedef OpenccConvertUtf8Native =
    Pointer<Utf8> Function(
      Pointer<Void> opencc,
      Pointer<Utf8> input,
      IntPtr length,
    );
typedef OpenccConvertUtf8Dart =
    Pointer<Utf8> Function(
      Pointer<Void> opencc,
      Pointer<Utf8> input,
      int length,
    );

typedef OpenccConvertUtf8FreeNative = Void Function(Pointer<Utf8> str);
typedef OpenccConvertUtf8FreeDart = void Function(Pointer<Utf8> str);

typedef OpenccErrorNative = Pointer<Utf8> Function();
typedef OpenccErrorDart = Pointer<Utf8> Function();

/// The subset of the OpenCC C API the app uses.
abstract interface class OpenCcBindings {
  Pointer<Void> open(Pointer<Utf8> configFileName);
  int close(Pointer<Void> opencc);
  Pointer<Utf8> convertUtf8(
    Pointer<Void> opencc,
    Pointer<Utf8> input,
    int length,
  );
  void convertUtf8Free(Pointer<Utf8> str);
  Pointer<Utf8> error();
}

/// Uses the libopencc bundled as a native asset, which is how app builds get
/// the library on Android/Linux/macOS.
final class NativeAssetOpenCcBindings implements OpenCcBindings {
  const NativeAssetOpenCcBindings();

  @override
  Pointer<Void> open(Pointer<Utf8> configFileName) =>
      _openccOpen(configFileName);

  @override
  int close(Pointer<Void> opencc) => _openccClose(opencc);

  @override
  Pointer<Utf8> convertUtf8(
    Pointer<Void> opencc,
    Pointer<Utf8> input,
    int length,
  ) => _openccConvertUtf8(opencc, input, length);

  @override
  void convertUtf8Free(Pointer<Utf8> str) => _openccConvertUtf8Free(str);

  @override
  Pointer<Utf8> error() => _openccError();
}

/// Uses an explicitly loaded library, for tests and hosts that ship their own
/// copy (see `tool/build_opencc.sh`).
final class DynamicLibraryOpenCcBindings implements OpenCcBindings {
  DynamicLibraryOpenCcBindings(this.library);

  final DynamicLibrary library;

  late final OpenccOpenDart _open = library
      .lookupFunction<OpenccOpenNative, OpenccOpenDart>('opencc_open');
  late final OpenccCloseDart _close = library
      .lookupFunction<OpenccCloseNative, OpenccCloseDart>('opencc_close');
  late final OpenccConvertUtf8Dart _convertUtf8 = library
      .lookupFunction<OpenccConvertUtf8Native, OpenccConvertUtf8Dart>(
        'opencc_convert_utf8',
      );
  late final OpenccConvertUtf8FreeDart _convertUtf8Free = library
      .lookupFunction<OpenccConvertUtf8FreeNative, OpenccConvertUtf8FreeDart>(
        'opencc_convert_utf8_free',
      );
  late final OpenccErrorDart _error = library
      .lookupFunction<OpenccErrorNative, OpenccErrorDart>('opencc_error');

  @override
  Pointer<Void> open(Pointer<Utf8> configFileName) => _open(configFileName);

  @override
  int close(Pointer<Void> opencc) => _close(opencc);

  @override
  Pointer<Utf8> convertUtf8(
    Pointer<Void> opencc,
    Pointer<Utf8> input,
    int length,
  ) => _convertUtf8(opencc, input, length);

  @override
  void convertUtf8Free(Pointer<Utf8> str) => _convertUtf8Free(str);

  @override
  Pointer<Utf8> error() => _error();
}
