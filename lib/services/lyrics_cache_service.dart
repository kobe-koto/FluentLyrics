import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lyric_model.dart';

class LyricsCacheService {
  static const String _cachePrefix = 'lyrics_cache_';

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

  Future<LyricsResult?> getCachedLyrics(String cacheId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cachePrefix + cacheId);
    if (jsonString == null) return null;

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return LyricsResult.fromJson(jsonMap);
    } catch (e) {
      // If there's an error parsing, clear the corrupted cache
      await clearCache(cacheId);
      return null;
    }
  }

  Future<void> cacheLyrics(String cacheId, LyricsResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(result.toJson());
    await prefs.setString(_cachePrefix + cacheId, jsonString);
  }

  Future<void> clearCache(String cacheId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachePrefix + cacheId);
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();
    int totalSize = 0;
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null) {
        totalSize += value.length; // Approximate size in bytes (UTF-16 chars)
      }
    }
    return {'count': keys.length, 'size': totalSize};
  }
}
