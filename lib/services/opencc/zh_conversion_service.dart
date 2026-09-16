import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/lyric_model.dart';
import 'zh_conversion.dart';
import 'zh_converter.dart';

/// Owns the OpenCC data shipped as Flutter assets and the native converters
/// opened from it.
///
/// Assets cannot be loaded by OpenCC directly (it needs real files), so the
/// `assets/opencc` directory is extracted once per bundled OpenCC version into
/// the app support directory and reused from there.
class ZhConversionService {
  ZhConversionService._();

  static final ZhConversionService instance = ZhConversionService._();

  static const String assetDirectory = 'assets/opencc';
  static const String licenseAsset = '$assetDirectory/LICENSE';
  static const String noticeAsset = '$assetDirectory/NOTICE';
  static const String authorsAsset = '$assetDirectory/AUTHORS';
  static const String versionAsset = '$assetDirectory/version.txt';

  final Map<ZhConfig, ZhConverter> _converters = {};
  String? _dataDirectory;
  Future<void>? _initialization;

  /// Whether the OpenCC data is extracted and converters can be opened.
  bool get isReady => _dataDirectory != null;

  /// Extracts the bundled OpenCC data if needed. Safe to call repeatedly.
  ///
  /// [directory] overrides the extraction target; tests use it to reuse a
  /// `tool/build_opencc.sh` output directory instead of the plugin-backed app
  /// support directory.
  Future<void> ensureInitialized({Directory? directory}) {
    return _initialization ??= _initialize(directory);
  }

  Future<void> _initialize(Directory? directory) async {
    final version = (await rootBundle.loadString(versionAsset)).trim();
    final target =
        directory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/opencc/$version',
        );
    final marker = File('${target.path}/version.txt');

    if (!marker.existsSync() || marker.readAsStringSync().trim() != version) {
      target.createSync(recursive: true);
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (!asset.startsWith('$assetDirectory/')) continue;
        final name = asset.substring(assetDirectory.length + 1);
        if (name.contains('/')) continue;
        final data = await rootBundle.load(asset);
        File('${target.path}/$name').writeAsBytesSync(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
    }

    _dataDirectory = target.path;
  }

  /// Converts [lyrics] for [target], or returns them unchanged.
  ///
  /// Nothing happens while the data is still being extracted or when
  /// [target] disables conversion; the next provider notification picks the
  /// conversion up.
  List<Lyric> convertLyrics(
    List<Lyric> lyrics, {
    required ZhConversionTarget target,
    required List<String> ignoredLanguages,
    String? languageHint,
  }) {
    final config = target.config;
    if (config == null || lyrics.isEmpty) return lyrics;
    if (ZhConversion.shouldSkip(
      lyrics: lyrics,
      ignoredLanguages: ignoredLanguages,
      languageHint: languageHint,
    )) {
      return lyrics;
    }
    final converter = _converterFor(config);
    if (converter == null) return lyrics;
    return ZhConversion.convert(lyrics, converter: converter);
  }

  ZhConverter? _converterFor(ZhConfig config) {
    final dataDirectory = _dataDirectory;
    if (dataDirectory == null) return null;
    return _converters.putIfAbsent(
      config,
      () => ZhConverter.open(config, dataDirectory: dataDirectory),
    );
  }

  /// Registers the bundled OpenCC license and attribution for the Flutter
  /// license page, which only collects licenses of pub dependencies
  /// automatically. OpenCC is vendored as a submodule, so its Apache-2.0
  /// license would otherwise not show up.
  static void registerLicense() {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(const [
        'OpenCC',
      ], await rootBundle.loadString(licenseAsset));
      final attribution = [
        await rootBundle.loadString(noticeAsset),
        await rootBundle.loadString(authorsAsset),
      ].join('\n');
      yield LicenseEntryWithLineBreaks(const ['OpenCC'], attribution);
    });
  }

  @visibleForTesting
  void reset() {
    for (final converter in _converters.values) {
      converter.dispose();
    }
    _converters.clear();
    _dataDirectory = null;
    _initialization = null;
  }
}
