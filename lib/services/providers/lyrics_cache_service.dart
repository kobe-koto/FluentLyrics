import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lyric_model.dart';
import '../../models/lyric_cache.dart';

class LyricsCacheService {
  static Isar? _isar;

  Future<Isar> get _db async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationSupportDirectory();
    _isar ??=
        Isar.getInstance() ??
        await Isar.open(
          [LyricCacheSchema],
          directory: dir.path,
          name: "lyrics_cache",
        );
    return _isar!;
  }

  String generateCacheId(
    String title,
    String artist,
    String? album,
    int durationSeconds,
  ) {
    final input = '$title|$artist|${album ?? ''}|$durationSeconds';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String? album,
    required int durationSeconds,
  }) async {
    final cacheId = generateCacheId(title, artist, album, durationSeconds);
    final cached = await getCachedLyrics(cacheId);
    if (cached != null) {
      return cached.copyWith(source: '${cached.source} (cached)');
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

  Future<void> cacheLyrics(String cacheId, LyricsResult result) async {
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

  Future<void> clearAllCache() async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.lyricCaches.clear();
    });
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final isar = await _db;
    final count = await isar.lyricCaches.count();
    final size = await isar.getSize();
    return {'count': count, 'size': size};
  }
}
