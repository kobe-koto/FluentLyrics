import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lyric_model.dart';
import '../../models/lyric_cache.dart';
import '../../utils/app_logger.dart';

class CacheDatabaseOpenException implements Exception {
  CacheDatabaseOpenException(this.cause);

  final Object cause;

  @override
  String toString() => cause.toString();
}

class LyricsCacheService {
  static const manualTranslationSkipLanguage = '__manual_translation_skip__';
  static const manualTranslationSkipProvider = '__manual_skip__';
  static const manualPureMusicSource = '__manual_pure_music__';

  static Isar? _isar;
  static Future<Isar>? _openFuture;
  static Object? openError;
  static bool unavailable = false;
  static bool rebuildDeclined = false;
  static bool promptPending = false;
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  static void declineRebuild() {
    rebuildDeclined = true;
    promptPending = false;
    _notify();
  }

  static Future<void> rebuild() async {
    rebuildDeclined = false;
    unavailable = false;
    promptPending = false;
    openError = null;
    _openFuture = null;
    final instance = _isar ?? Isar.getInstance('lyrics_cache');
    _isar = null;
    if (instance != null) {
      await instance.close(deleteFromDisk: true);
    }
    final dir = await getApplicationSupportDirectory();
    for (final name in ['lyrics_cache.isar', 'lyrics_cache.isar.lock']) {
      final file = File('${dir.path}/$name');
      if (await file.exists()) await file.delete();
    }
    try {
      await LyricsCacheService()._db;
    } on CacheDatabaseOpenException {
      // Open already recorded the error and asked the user again.
    }
  }

  Future<Isar> get _db async {
    if (_isar != null) return _isar!;
    if (unavailable) {
      throw CacheDatabaseOpenException(
        openError ?? 'cache database unavailable',
      );
    }
    if (_openFuture != null) return _openFuture!;
    _openFuture = _initDb();
    try {
      return await _openFuture!;
    } catch (e) {
      _openFuture = null;
      rethrow;
    }
  }

  Future<Isar?> _openedDb() async {
    if (unavailable) return null;
    try {
      return await _db;
    } on CacheDatabaseOpenException {
      return null;
    }
  }

  static const List<CollectionSchema<dynamic>> _schemas = [
    LyricCacheSchema,
    TranslationCacheSchema,
    ReadingCacheSchema,
    ReadingCandidateCacheSchema,
  ];

  Future<Isar> _initDb() async {
    final dir = await getApplicationSupportDirectory();
    _isar = Isar.getInstance('lyrics_cache');
    if (_isar != null) return _isar!;

    try {
      _isar = await Isar.open(
        _schemas,
        directory: dir.path,
        name: 'lyrics_cache',
      );
      unavailable = false;
      openError = null;
      promptPending = false;
    } catch (e) {
      _isar = null;
      unavailable = true;
      openError = e;
      promptPending = !rebuildDeclined;
      AppLogger.debug('[LyricsCacheService] Cache database failed to open: $e');
      _notify();
      throw CacheDatabaseOpenException(e);
    }
    return _isar!;
  }

  String generateCacheId(
    String title,
    List<String> artist,
    String? album,
    int durationSeconds, {
    bool isRichSync = false,
  }) {
    final input = '$title|${artist.join(', ')}|${album ?? ''}|$durationSeconds';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}_${isRichSync ? 'rich' : 'std'}';
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required String? album,
    required int durationSeconds,
  }) async {
    // Try rich sync first
    final richCacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: true,
    );
    final richCached = await getCachedLyrics(richCacheId);
    if (richCached != null && richCached.lyrics.isNotEmpty) {
      return (await _withCachedReading(
        richCached,
        richCacheId,
      )).copyWith(source: '${richCached.source} (cached)');
    }

    // Fallback to standard sync
    final stdCacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: false,
    );
    final stdCached = await getCachedLyrics(stdCacheId);
    if (stdCached != null &&
        (stdCached.lyrics.isNotEmpty || stdCached.isPureMusic)) {
      return (await _withCachedReading(
        stdCached,
        stdCacheId,
      )).copyWith(source: '${stdCached.source} (cached)');
    }

    return LyricsResult.empty();
  }

  Future<LyricsResult?> getCachedLyrics(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return null;
    final cached = await isar.lyricCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findFirst();
    if (cached == null) return null;

    try {
      return cached.toLyricsResult();
    } catch (e) {
      await clearCache(cacheId);
      return null;
    }
  }

  Future<void> cacheLyrics(
    String title,
    List<String> artist,
    String? album,
    int durationSeconds,
    LyricsResult result,
  ) async {
    final cacheId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: result.isRichSync,
    );
    if (result.isFailure) return;
    final isar = await _openedDb();
    if (isar == null) return;
    final cache = LyricCache.fromLyricsResult(cacheId, result);
    await isar.writeTxn(() async {
      await isar.lyricCaches.put(cache);
    });
  }

  Future<void> clearCache(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.lyricCaches.filter().cacheIdEqualTo(cacheId).deleteAll();
    });
  }

  Future<void> clearTrackCache(
    String title,
    List<String> artist,
    String? album,
    int durationSeconds,
  ) async {
    final richId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: true,
    );
    final stdId = generateCacheId(
      title,
      artist,
      album,
      durationSeconds,
      isRichSync: false,
    );
    final isar = await _openedDb();
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.lyricCaches
          .filter()
          .cacheIdEqualTo(richId)
          .or()
          .cacheIdEqualTo(stdId)
          .deleteAll();
      for (final cacheId in [richId, stdId]) {
        await isar.readingCaches.filter().cacheIdEqualTo(cacheId).deleteAll();
        await isar.readingCandidateCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
      }
    });
  }

  Future<void> clearAllCache() async {
    final isar = await _openedDb();
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.lyricCaches.clear();
      await isar.translationCaches.clear();
      await isar.readingCaches.clear();
      await isar.readingCandidateCaches.clear();
    });
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final isar = await _openedDb();
    if (isar == null) {
      return {'count': 0, 'readingCount': 0, 'size': 0};
    }
    final count = await isar.lyricCaches.count();
    final readingCount =
        await isar.readingCaches.count() +
        await isar.readingCandidateCaches.count();
    final size = await isar.getSize();
    return {'count': count, 'readingCount': readingCount, 'size': size};
  }

  // Translation Caching
  Future<LyricsResult?> getCachedTranslation(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return null;
    final cached = await isar.translationCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findFirst();

    if (cached == null) return null;

    try {
      return cached.toLyricsResult();
    } catch (e) {
      await isar.writeTxn(() async {
        await isar.translationCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
      });
      return null;
    }
  }

  Future<void> cacheTranslation(String cacheId, LyricsResult result) async {
    if (result.isFailure) return;
    final isar = await _openedDb();
    if (isar == null) return;
    final cache = TranslationCache.fromLyricsResult(cacheId, result);
    await isar.writeTxn(() async {
      await isar.translationCaches.put(cache);
    });
  }

  Future<void> clearTranslationCache(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.translationCaches.filter().cacheIdEqualTo(cacheId).deleteAll();
    });
  }

  String generateTranslationCacheId(
    String title,
    List<String> artist,
    String language,
  ) {
    final input = '$title|${artist.join(', ')}|$language';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Reading track (kanji/kana annotation) caching. The selected reading and
  // the candidate readings are separate collections so a candidate can never
  // overwrite the selection.
  Future<LyricsReading?> getCachedReading(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return null;
    final cached = await isar.readingCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findFirst();
    return cached?.toReading();
  }

  /// Attaches the persisted reading track (if any) to [result].
  Future<LyricsResult> _withCachedReading(
    LyricsResult result,
    String cacheId,
  ) async {
    if (result.reading != null) return result;
    final reading = await getCachedReading(cacheId);
    if (reading == null || reading.isEmpty) return result;
    return result.copyWith(reading: reading);
  }

  Future<void> cacheReading(
    String cacheId,
    LyricsReading reading, {
    String? source,
    String? sourceProvider,
  }) async {
    final isar = await _openedDb();
    if (isar == null) return;
    final cache = ReadingCache.fromReading(
      cacheId,
      reading,
      source: source,
      sourceProvider: sourceProvider,
    );
    await isar.writeTxn(() async {
      await isar.readingCaches.put(cache);
    });
  }

  Future<List<LyricsReading>> getCachedReadingCandidates(String cacheId) async {
    final isar = await _openedDb();
    if (isar == null) return const [];
    final cached = await isar.readingCandidateCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findAll();
    return cached.map((c) => c.toReading()).toList();
  }

  Future<void> cacheReadingCandidate(
    String cacheId,
    LyricsReading reading, {
    String? source,
    String? sourceProvider,
  }) async {
    final isar = await _openedDb();
    if (isar == null) return;
    final cache = ReadingCandidateCache.fromReading(
      cacheId,
      reading,
      source: source,
      sourceProvider: sourceProvider,
    );
    final existing = await isar.readingCandidateCaches
        .filter()
        .cacheIdEqualTo(cacheId)
        .findAll();
    final isDuplicate = existing.any(
      (c) =>
          c.lineType == cache.lineType &&
          c.kanaRaw == cache.kanaRaw &&
          c.lines.length == cache.lines.length,
    );
    if (isDuplicate) return;
    await isar.writeTxn(() async {
      await isar.readingCandidateCaches.put(cache);
    });
  }
}
