import 'dart:io';

import 'package:fluent_lyrics/services/opencc/zh_converter.dart';
import 'package:flutter_test/flutter_test.dart';

/// libopencc built by `tool/build_opencc.sh`, used as the host test fixture.
/// Android/Linux/macOS app builds bundle their own copy.
String? _hostLibraryPath() {
  final name = Platform.isLinux
      ? 'libopencc.so'
      : Platform.isMacOS
      ? 'libopencc.dylib'
      : null;
  if (name == null) return null;
  final file = File('build/opencc/out/lib/$name');
  return file.existsSync() ? file.absolute.path : null;
}

const String _hostDataDirectory = 'build/opencc/out/share/opencc';

void main() {
  final libraryPath = _hostLibraryPath();
  final dataDirectoryExists = Directory(_hostDataDirectory).existsSync();
  final skipReason = libraryPath == null || !dataDirectoryExists
      ? 'run tool/build_opencc.sh first'
      : null;
  // The dictionaries are not shipped as Flutter assets yet, so the native
  // asset test still reads the host build's data directory.
  final assetSkipReason = dataDirectoryExists
      ? null
      : 'run tool/build_opencc.sh first';

  ZhConverter open(ZhConfig config) => ZhConverter.open(
    config,
    dataDirectory: _hostDataDirectory,
    libraryPath: libraryPath,
  );

  group('ZhConverter', () {
    test('converts simplified to traditional', () {
      final converter = open(ZhConfig.s2t);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
    }, skip: skipReason);

    test('converts traditional to simplified', () {
      final converter = open(ZhConfig.t2s);
      addTearDown(converter.dispose);

      expect(converter.convert('繁體中文'), '繁体中文');
    }, skip: skipReason);

    test('applies Taiwan variants and idioms for s2twp', () {
      final converter = open(ZhConfig.s2twp);
      addTearDown(converter.dispose);

      expect(converter.convert('里面'), '裡面');
      expect(converter.convert('软件'), '軟體');
    }, skip: skipReason);

    test('keeps non-Chinese content untouched', () {
      final converter = open(ZhConfig.s2t);
      addTearDown(converter.dispose);

      expect(converter.convert('hello 123, 汉字! 🎵'), 'hello 123, 漢字! 🎵');
    }, skip: skipReason);

    test('loads libopencc from the native asset built by hook/build.dart', () {
      // No libraryPath: the OpenCC C functions resolve via the assetId declared
      // in opencc_bindings.dart, which the build hook provides.
      final converter = ZhConverter.open(
        ZhConfig.s2t,
        dataDirectory: _hostDataDirectory,
      );
      addTearDown(converter.dispose);

      expect(converter.convert('简体中文'), '簡體中文');
    }, skip: assetSkipReason);

    test('converts repeatedly and throws once disposed', () {
      final converter = open(ZhConfig.s2t);

      expect(converter.convert('简体'), '簡體');
      expect(converter.convert('简体'), '簡體');

      converter.dispose();
      expect(() => converter.convert('简体'), throwsStateError);
    }, skip: skipReason);
  });
}
