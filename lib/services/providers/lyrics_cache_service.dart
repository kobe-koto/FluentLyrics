import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lyric_model.dart';
import '../../models/lyric_cache.dart';
import '../../utils/app_logger.dart';

class LyricsCacheService {
  static const manualTranslationSkipLanguage = '__manual_translation_skip__';
  static const manualTranslationSkipProvider = '__manual_skip__';
  static const manualPureMusicSource = '__manual_pure_music__';

  static Isar? _isar;
  static Future<Isar>? _openFuture;

  Future<Isar> get _db async {
    if (_isar != null) return _isar!;

    if (_openFuture != null) return _openFuture!;

    _openFuture = _initDb();
    return _openFuture!;
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
    } catch (e) {
      // The database is a disposable cache: when its schema no longer matches
      // (a release added or changed collections) drop it and start over
      // instead of failing to launch.
      AppLogger.debug('[LyricsCacheService] Recreating cache database: $e');
      await Isar.getInstance('lyrics_cache')?.close(deleteFromDisk: true);
      _isar = await Isar.open(
        _schemas,
        directory: dir.path,
        name: 'lyrics_cache',
      );
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
      return (await _withCachedReading(richCached, richCacheId)).copyWith(
        source: '${richCached.source} (cached)',
      );
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
      return (await _withCachedReading(stdCached, stdCacheId)).copyWith(
        source: '${stdCached.source} (cached)',
      );
    }

    return LyricsResult.empty();
  }

  Future<LyricsResult?> getCachedLyrics(String cacheId) async {
    final isar = await _db;
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
    final isar = await _db;
    final cache = LyricCache.fromLyricsResult(cacheId, result);
    await isar.writeTxn(() async {
      await isar.lyricCaches.put(cache);
    });
  }

  Future<void> clearCache(String cacheId) async {
    final isar = await _db;
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
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches
          .filter()
          .cacheIdEqualTo(richId)
          .or()
          .cacheIdEqualTo(stdId)
          .deleteAll();
      for (final cacheId in [richId, stdId]) {
        await isar.readingCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
        await isar.readingCandidateCaches
            .filter()
            .cacheIdEqualTo(cacheId)
            .deleteAll();
      }
    });
  }

  Future<void> clearAllCache() async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches.clear();
      await isar.translationCaches.clear();
      await isar.readingCaches.clear();
      await isar.readingCandidateCaches.clear();
    });
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final isar = await _db;
    final count = await isar.lyricCaches.count();
    final readingCount =
        await isar.readingCaches.count() +
        await isar.readingCandidateCaches.count();
    final size = await isar.getSize();
    return {'count': count, 'readingCount': readingCount, 'size': size};
  }

  // Translation Caching
  Future<LyricsResult?> getCachedTranslation(String cacheId) async {
    final isar = await _db;
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
    final isar = await _db;
    final cache = TranslationCache.fromLyricsResult(cacheId, result);
    await isar.writeTxn(() async {
      await isar.translationCaches.put(cache);
    });
  }

  Future<void> clearTranslationCache(String cacheId) async {
    final isar = await _db;
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
    final isar = await _db;
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
    final isar = await _db;
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

  Future<List<LyricsReading>> getCachedReadingCandidates(
    String cacheId,
  ) async {
    final isar = await _db;
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
    final isar = await _db;
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
