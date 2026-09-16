import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Relative path (inside `lib/`) of the Dart file whose `@Native` declarations
/// resolve to the library emitted by this hook. Keep in sync with
/// `openCcAssetId` in lib/services/opencc/opencc_bindings.dart.
const String _assetName = 'services/opencc/opencc_bindings.dart';

/// Builds libopencc from the pinned submodule in `third_party/opencc` and
/// exposes it as a native asset.
///
/// The same CMake flags are used by tool/build_opencc.sh (host builds used by
/// `flutter test` and local runs); keep the two in sync when bumping OpenCC.
void main(List<String> args) async {
  await build(args, (input, output) async {
    final code = input.config.code;
    if (code.linkModePreference == LinkModePreference.static) {
      throw UnsupportedError(
        'libopencc is loaded at runtime, so it must be built as a dynamic '
        'library (got LinkModePreference.static).',
      );
    }

    final assetsDirectory = input.packageRoot
        .resolve('assets/opencc/')
        .toFilePath();
    if (!File('$assetsDirectory/version.txt').existsSync()) {
      throw StateError(
        'assets/opencc is missing. The OpenCC configs and dictionaries are '
        'generated, not committed: run tool/sync_opencc_assets.sh before '
        'building.',
      );
    }

    final sourceDirectory = input.packageRoot.resolve('third_party/opencc/');
    if (!File.fromUri(sourceDirectory.resolve('CMakeLists.txt')).existsSync()) {
      throw StateError(
        'third_party/opencc is missing or not checked out. '
        'Run tool/prepare_opencc.sh first.',
      );
    }

    final outputPath = input.outputDirectory.toFilePath();
    final buildDirectory = Directory('$outputPath/opencc-build');
    final libraryName = _libraryNameFor(code.targetOS);

    final configureArguments = <String>[
      '-S',
      sourceDirectory.toFilePath(),
      '-B',
      buildDirectory.path,
      if (_hasNinja()) ...['-G', 'Ninja'],
      '-DCMAKE_BUILD_TYPE=Release',
      '-DBUILD_SHARED_LIBS=ON',
      // Build for size: the library carries a statically linked C++ standard
      // library, so dead-code elimination matters more than peak throughput
      // (a song is converted once, and the result is cached upstream).
      '-DCMAKE_C_FLAGS_RELEASE=-Oz -DNDEBUG -ffunction-sections -fdata-sections',
      '-DCMAKE_CXX_FLAGS_RELEASE=-Oz -DNDEBUG -ffunction-sections -fdata-sections',
      // Link-time optimization removes the code the converter never calls
      // (OpenCC ships several dictionary readers, a segmentation plugin API,
      // and the whole static libc++).
      '-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON',
      if (code.targetOS == OS.linux || code.targetOS == OS.android) ...[
        // Drop unreferenced sections and hide symbols that come from the
        // static archives (marisa, libc++), which also lets the linker
        // garbage collect more.
        '-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--gc-sections -Wl,--exclude-libs,ALL -Wl,-s',
      ] else if (code.targetOS == OS.macOS) ...[
        '-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-dead_strip',
      ],
      // Only the converter library is needed. OpenCC's install/dictionary
      // targets execute the freshly built command line tools, which cannot run
      // when cross compiling for Android.
      '-DOPENCC_ENABLE_INSTALL=OFF',
      if (code.targetOS == OS.linux || code.targetOS == OS.android)
        '-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON',
      // Plain text dictionaries: the app loads them from Flutter assets and the
      // build does not need to generate .ocd2 files.
      '-DOPENCC_DICT_FORMAT=text',
      '-DENABLE_GTEST=OFF',
      '-DENABLE_BENCHMARK=OFF',
      '-DBUILD_DOCUMENTATION=OFF',
      '-DBUILD_PYTHON=OFF',
      '-DBUILD_OPENCC_JIEBA_PLUGIN=OFF',
      ..._toolchainArguments(code),
    ];

    await _run('cmake', configureArguments);
    await _run('cmake', [
      '--build',
      buildDirectory.path,
      '--config',
      'Release',
      '--target',
      'libopencc',
    ]);

    // The build tree contains versioned names and symlinks; the app bundle
    // gets a single unversioned file with the library contents.
    final built = File(
      buildDirectory.uri.resolve('src/$libraryName').toFilePath(),
    );
    if (!built.existsSync()) {
      throw StateError('CMake did not produce ${built.path}');
    }
    final bundled = File('$outputPath/$libraryName');
    File(built.resolveSymbolicLinksSync()).copySync(bundled.path);

    output.dependencies
      ..add(sourceDirectory.resolve('CMakeLists.txt'))
      ..add(sourceDirectory.resolve('src/'))
      ..add(sourceDirectory.resolve('data/'))
      ..add(sourceDirectory.resolve('deps/'))
      ..add(input.packageRoot.resolve('hook/build.dart'));

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: bundled.uri,
      ),
    );
  });
}

Future<void> _run(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '$executable failed with exit code $exitCode',
      exitCode,
    );
  }
}

bool _hasNinja() {
  try {
    return Process.runSync('ninja', ['--version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

String _libraryNameFor(OS targetOS) {
  if (targetOS == OS.macOS) return 'libopencc.dylib';
  if (targetOS == OS.linux || targetOS == OS.android) return 'libopencc.so';
  throw UnsupportedError('libopencc is not wired up for $targetOS yet.');
}

List<String> _toolchainArguments(CodeConfig code) {
  final targetOS = code.targetOS;
  if (targetOS == OS.macOS) {
    return [
      '-DCMAKE_OSX_ARCHITECTURES=${_macOSArchitecture(code.targetArchitecture)}',
      '-DCMAKE_OSX_DEPLOYMENT_TARGET=${code.macOS.targetVersion}',
    ];
  }
  if (targetOS == OS.linux) {
    return [
      if (code.cCompiler case final compiler?)
        '-DCMAKE_C_COMPILER=${compiler.compiler.toFilePath()}',
    ];
  }
  if (targetOS == OS.android) {
    final ndk = _findAndroidNdk();
    if (ndk == null) {
      throw StateError(
        'Android NDK not found. Set ANDROID_NDK_HOME or ANDROID_HOME '
        '(looked under <sdk>/ndk).',
      );
    }
    return [
      '-DCMAKE_TOOLCHAIN_FILE=$ndk/build/cmake/android.toolchain.cmake',
      '-DANDROID_ABI=${_androidAbi(code.targetArchitecture)}',
      '-DANDROID_PLATFORM=android-${code.android.targetNdkApi}',
      // Statically link the C++ standard library: the app has no other
      // provider of libc++_shared.so, and a self-contained libopencc.so also
      // avoids shipping a second shared library per ABI.
      '-DANDROID_STL=c++_static',
    ];
  }
  throw UnsupportedError('libopencc is not wired up for $targetOS yet.');
}

String _macOSArchitecture(Architecture architecture) {
  if (architecture == Architecture.arm64) return 'arm64';
  if (architecture == Architecture.x64) return 'x86_64';
  throw UnsupportedError('Unsupported macOS architecture: $architecture');
}

String _androidAbi(Architecture architecture) {
  if (architecture == Architecture.arm64) return 'arm64-v8a';
  if (architecture == Architecture.arm) return 'armeabi-v7a';
  if (architecture == Architecture.x64) return 'x86_64';
  if (architecture == Architecture.ia32) return 'x86';
  throw UnsupportedError('Unsupported Android architecture: $architecture');
}

String? _findAndroidNdk() {
  for (final key in ['ANDROID_NDK_HOME', 'ANDROID_NDK_ROOT']) {
    final value = Platform.environment[key];
    if (value != null && value.isNotEmpty) return value;
  }
  for (final key in ['ANDROID_HOME', 'ANDROID_SDK_ROOT']) {
    final sdk = Platform.environment[key];
    if (sdk == null || sdk.isEmpty) continue;
    final ndkDirectory = Directory('$sdk/ndk');
    if (!ndkDirectory.existsSync()) continue;
    final versions = ndkDirectory.listSync().whereType<Directory>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    if (versions.isNotEmpty) return versions.first.path;
  }
  return null;
}
