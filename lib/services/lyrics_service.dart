import '../models/lyric_model.dart';
import 'settings_service.dart';
import 'providers/lrclib_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'providers/lyrics_cache_service.dart';

class LyricsService {
  final SettingsService _settingsService = SettingsService();
  // lyrics providers
  final LrclibService _lrclibService = LrclibService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final NeteaseService _neteaseService = NeteaseService();
  final LyricsCacheService _cacheService = LyricsCacheService();

  Stream<LyricsResult> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    bool Function()? isCancelled,
    List<LyricProviderType> trimMetadataProviders = const [],
  }) async* {
    final priority = await _settingsService.getPriority();
    // Always prioritize cache first
    final fullPriority = [LyricProviderType.cache, ...priority];

    LyricsResult? bestResult;

    for (var provider in fullPriority) {
      if (isCancelled?.call() == true) {
        if (bestResult != null) yield bestResult;
        return;
      }

      LyricsResult result = LyricsResult.empty();
      final shouldTrimMetadata = trimMetadataProviders.contains(provider);

      if (provider == LyricProviderType.cache) {
        result = await _cacheService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
        );
      } else if (provider == LyricProviderType.lrclib) {
        result = await _lrclibService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      } else if (provider == LyricProviderType.musixmatch) {
        result = await _musixmatchService.fetchLyrics(
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      } else if (provider == LyricProviderType.netease) {
        result = await _neteaseService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
          trimMetadata: shouldTrimMetadata,
        );
      }

      if (result.lyrics.isNotEmpty ||
          result.artworkUrl != null ||
          result.isPureMusic) {
        // Cache the raw result from other providers
        if (provider != LyricProviderType.cache) {
          final cacheId = _cacheService.generateCacheId(
            title,
            artist,
            album,
            durationSeconds,
          );
          await _cacheService.cacheLyrics(cacheId, result);
        }

        if (bestResult == null) {
          bestResult = result;
        } else {
          // If the new result has lyrics/pureMusic and the current best doesn't,
          // or if the new one is synced and old isn't.
          bool newBetter = false;
          if (result.isPureMusic && !bestResult.isPureMusic) {
            newBetter = true;
          } else if (result.lyrics.isNotEmpty && bestResult.lyrics.isEmpty) {
            newBetter = true;
          } else if (result.lyrics.isNotEmpty &&
              result.isSynced &&
              !bestResult.isSynced) {
            newBetter = true;
          }

          if (newBetter) {
            bestResult = result.copyWith(
              lyrics: result.lyrics,
              source: result.source,
              isSynced: result.isSynced,
              writtenBy: result.writtenBy,
              contributor: result.contributor,
              copyright: result.copyright,
              artworkUrl: result.artworkUrl ?? bestResult.artworkUrl,
              isPureMusic: result.isPureMusic,
            );
          } else {
            // Keep existing lyrics, but take artwork if missing.
            if (bestResult.artworkUrl == null && result.artworkUrl != null) {
              bestResult = bestResult.copyWith(artworkUrl: result.artworkUrl);
            }
          }
        }
        yield bestResult;
      }

      // If we have (synced lyrics OR pure music) AND artwork, we can stop early.
      if (bestResult != null &&
          (bestResult.isPureMusic ||
              (bestResult.lyrics.isNotEmpty && bestResult.isSynced)) &&
          bestResult.artworkUrl != null) {
        return;
      }
    }
  }
}
