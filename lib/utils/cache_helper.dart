import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';

class CacheHelper {
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<Map<String, int>> getArtworkCacheStats() async {
    try {
      int totalSize = 0;
      int count = 0;
      final cacheDir = await getApplicationCacheDirectory();
      final appCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (appCacheDir.existsSync()) {
        await for (var file in appCacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            totalSize += await file.length();
            count++;
          }
        }
      }

      return {'count': count, 'size': totalSize};
    } catch (e) {
      AppLogger.debug('Error getting artwork cache stats: $e');
      return {'count': 0, 'size': 0};
    }
  }

  static Future<void> clearArtworkCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final appCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (appCacheDir.existsSync()) {
        await appCacheDir.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.debug('Error clearing artwork cache: $e');
    }
  }
}
