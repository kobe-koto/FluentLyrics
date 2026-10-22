import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import '../utils/kanji_reading_splitter.dart';
import '../utils/kanji_readings_converter.dart';

/// Owns the single-kanji reading dictionary and the [KanjiReadingSplitter]
/// built from it.
///
/// The data is a trimmed, reformatted subset of KANJIDIC2 (readings only),
/// produced before the build by `tool/sync_kanji_readings.sh` and shipped as a
/// Flutter asset. Like OpenCC, the bundled copy is extracted once into the app
/// support directory and read from there, so it can be managed (reloaded,
/// cleared) at runtime from the cache screen. On launch the bundled version is
/// compared with the extracted one and the bundled copy wins only when it is
/// newer — an app update refreshes the dictionary, a manual copy is kept
/// otherwise.
class KanjiReadingDictionary {
  KanjiReadingDictionary._();

  static final KanjiReadingDictionary instance = KanjiReadingDictionary._();

  static const String assetDirectory = 'assets/kanji_readings';
  static const String dataAsset = '$assetDirectory/kanji_readings.json';
  static const String versionAsset = '$assetDirectory/version.txt';
  static const String licenseAsset = '$assetDirectory/LICENSE';
  static const String noticeAsset = '$assetDirectory/NOTICE';

  static const String _dirName = 'kanji_readings';
  static const String _dataFileName = 'kanji_readings.json';
  static const String _versionFileName = 'version.txt';

  /// The KANJIDIC2 source for the in-app "download latest" action. Matches the
  /// URL in `tool/sync_kanji_readings.sh`. EDRDG serves the current gzipped
  /// XML at this stable URL.
  static const String kanjidic2Url =
      'https://www.edrdg.org/kanjidic/kanjidic2.xml.gz';

  KanjiReadingSplitter? _splitter;
  Future<KanjiReadingSplitter?>? _loading;
  String? _installedVersion;
  int? _installedSizeBytes;

  /// Overridable for tests; defaults to a plain HTTP GET returning the bytes.
  @visibleForTesting
  Future<List<int>> Function(Uri uri) httpGetBytes = _defaultGetBytes;

  static Future<List<int>> _defaultGetBytes(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'KANJIDIC2 download failed: HTTP ${response.statusCode}',
        uri,
      );
    }
    return response.bodyBytes;
  }

  /// The version of the extracted dictionary, or null when none is extracted.
  String? get installedVersion => _installedVersion;

  /// The on-disk size of the extracted dictionary in bytes, or null.
  int? get installedSizeBytes => _installedSizeBytes;

  /// The splitter built from the extracted dictionary, extracting it on first
  /// use. Returns null when the asset is missing or malformed, so callers fall
  /// back to the whole-run annotation.
  Future<KanjiReadingSplitter?> splitter({Directory? directory}) {
    if (_splitter != null) return Future.value(_splitter);
    return _loading ??= _load(directory);
  }

  Future<KanjiReadingSplitter?> _load(Directory? directory) async {
    try {
      final dataFile = await _ensureExtracted(directory);
      if (dataFile == null) return null;
      final splitter = _parse(dataFile.readAsStringSync());
      _splitter = splitter;
      return splitter;
    } catch (error) {
      // Missing or malformed data is not fatal: per-kanji splitting stays off
      // and whole-run readings are shown.
      if (kDebugMode) {
        debugPrint('[KanjiReadingDictionary] load failed: $error');
      }
      return null;
    }
  }

  /// Extracts the bundled dictionary when it is newer than (or absent from) the
  /// app support copy, then returns the data file. [directory] overrides the
  /// target so tests do not depend on `path_provider`.
  Future<File?> _ensureExtracted(Directory? directory) async {
    final bundledVersion = (await rootBundle.loadString(versionAsset)).trim();
    final target =
        directory ??
        Directory('${(await getApplicationSupportDirectory()).path}/$_dirName');
    final marker = File('${target.path}/$_versionFileName');
    final dataFile = File('${target.path}/$_dataFileName');

    final storedVersion = marker.existsSync()
        ? marker.readAsStringSync().trim()
        : null;

    if (!dataFile.existsSync() || isNewer(bundledVersion, storedVersion)) {
      target.createSync(recursive: true);
      final data = await rootBundle.loadString(dataAsset);
      dataFile.writeAsStringSync(data);
      marker.writeAsStringSync('$bundledVersion\n');
      _installedVersion = bundledVersion;
    } else {
      _installedVersion = storedVersion;
    }

    _installedSizeBytes = dataFile.existsSync() ? dataFile.lengthSync() : null;
    return dataFile.existsSync() ? dataFile : null;
  }

  /// Whether [bundled] should overwrite [stored]. Both the asset and the marker
  /// hold a KANJIDIC2 `date_of_creation` (`YYYY-MM-DD`), compared as dates; when
  /// either is not a plain date, any difference lets the bundled copy win,
  /// since it only changes with an app update.
  @visibleForTesting
  static bool isNewer(String bundled, String? stored) {
    if (stored == null) return true;
    final isDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isDate.hasMatch(bundled) && isDate.hasMatch(stored)) {
      return bundled.compareTo(stored) > 0;
    }
    return bundled != stored;
  }

  static KanjiReadingSplitter _parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final dictionary = <String, List<String>>{
      for (final entry in decoded.entries)
        entry.key: [
          for (final reading in entry.value as List) reading as String,
        ],
    };
    return KanjiReadingSplitter(dictionary);
  }

  /// Re-extracts the bundled dictionary, replacing the app support copy, and
  /// reloads the splitter. Returns the new version, or null on failure.
  Future<String?> reloadFromBundle({Directory? directory}) async {
    _splitter = null;
    _loading = null;
    try {
      final target =
          directory ??
          Directory(
            '${(await getApplicationSupportDirectory()).path}/$_dirName',
          );
      if (target.existsSync()) target.deleteSync(recursive: true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[KanjiReadingDictionary] clear before reload failed: '
          '$error',
        );
      }
    }
    await splitter(directory: directory);
    return _installedVersion;
  }

  /// Deletes the extracted dictionary. The next load re-extracts the bundled
  /// copy, so this is a reset rather than a permanent removal.
  Future<void> deleteExtracted({Directory? directory}) async {
    _splitter = null;
    _loading = null;
    _installedVersion = null;
    _installedSizeBytes = null;
    final target =
        directory ??
        Directory('${(await getApplicationSupportDirectory()).path}/$_dirName');
    if (target.existsSync()) target.deleteSync(recursive: true);
  }

  /// Downloads the latest KANJIDIC2 from EDRDG, converts it on-device to the
  /// same trimmed form as the bundled asset, and installs it as the extracted
  /// copy. Returns the installed version on success, or null on failure (the
  /// previous copy is left untouched).
  ///
  /// The download replaces the extracted copy but not the bundled asset, so the
  /// launch-time check still refreshes it when a newer app bundle appears
  /// (by [isNewer]'s date comparison).
  Future<String?> downloadFromEdrdg({Directory? directory}) async {
    try {
      final bytes = await httpGetBytes(Uri.parse(kanjidic2Url));
      // EDRDG serves gzipped XML; decode in memory, then stream-parse.
      final xml = utf8.decode(gzip.decode(bytes));
      final converted = KanjiReadingConverter.convert(xml);

      final target =
          directory ??
          Directory(
            '${(await getApplicationSupportDirectory()).path}/$_dirName',
          );
      target.createSync(recursive: true);
      final dataFile = File('${target.path}/$_dataFileName');
      final marker = File('${target.path}/$_versionFileName');
      // Write to a temp name first so a crash mid-write cannot leave a
      // truncated dictionary that later loads as malformed.
      final temp = File('${dataFile.path}.tmp');
      temp.writeAsStringSync(converted.json);
      temp.renameSync(dataFile.path);
      marker.writeAsStringSync('${converted.version}\n');

      _splitter = _parse(converted.json);
      _loading = Future.value(_splitter);
      _installedVersion = converted.version;
      _installedSizeBytes = dataFile.lengthSync();
      AppLogger.debug(
        '[KanjiReadingDictionary] downloaded ${converted.version} '
        '($_installedSizeBytes bytes)',
      );
      return converted.version;
    } catch (error) {
      AppLogger.debug('[KanjiReadingDictionary] download failed: $error');
      return null;
    }
  }

  /// Registers the bundled dictionary's license and attribution for the Flutter
  /// license page, which only collects pub dependency licenses automatically.
  static void registerLicense() {
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(licenseAsset);
      yield LicenseEntryWithLineBreaks(const ['KANJIDIC2'], license);
      final notice = await rootBundle.loadString(noticeAsset);
      yield LicenseEntryWithLineBreaks(const ['KANJIDIC2'], notice);
    });
  }

  @visibleForTesting
  void overrideForTest(KanjiReadingSplitter? splitter) {
    _splitter = splitter;
    _loading = Future.value(splitter);
  }

  @visibleForTesting
  void reset() {
    _splitter = null;
    _loading = null;
    _installedVersion = null;
    _installedSizeBytes = null;
  }
}
