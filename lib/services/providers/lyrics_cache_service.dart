import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lyric_model.dart';
import '../../models/lyric_cache.dart';

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

  Future<Isar> _initDb() async {
    final dir = await getApplicationSupportDirectory();
    _isar =
        Isar.getInstance('lyrics_cache') ??
        await Isar.open(
          [LyricCacheSchema, TranslationCacheSchema],
          directory: dir.path,
          name: 'lyrics_cache',
        );
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
      return richCached.copyWith(source: '${richCached.source} (cached)');
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
      return stdCached.copyWith(source: '${stdCached.source} (cached)');
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
    });
  }

  Future<void> clearAllCache() async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches.clear();
      await isar.translationCaches.clear();
    });
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final isar = await _db;
    final count = await isar.lyricCaches.count();
    final size = await isar.getSize();
    return {'count': count, 'size': size};
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
}
