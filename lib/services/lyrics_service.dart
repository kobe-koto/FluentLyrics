import '../models/lyric_model.dart';
import 'providers/lrclib_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'settings_service.dart';

class LyricsService {
  final LrclibService _lrclibService = LrclibService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final NeteaseService _neteaseService = NeteaseService();
  final SettingsService _settingsService = SettingsService();

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
    LyricsResult? bestResult;

    for (var provider in priority) {
      if (isCancelled?.call() == true) {
        if (bestResult != null) yield bestResult;
        return;
      }

      LyricsResult result = LyricsResult.empty();
      final shouldTrimMetadata = trimMetadataProviders.contains(provider);
      
      if (provider == LyricProviderType.lrclib) {
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

      if (result.lyrics.isNotEmpty || result.artworkUrl != null) {
        if (bestResult == null) {
          bestResult = result;
        } else {
          // If the new result has lyrics and the current best doesn't, or if the new one is synced and old isn't.
          if (result.lyrics.isNotEmpty &&
              (bestResult.lyrics.isEmpty ||
                  (result.isSynced && !bestResult.isSynced))) {
            bestResult = result.copyWith(
              lyrics: result.lyrics,
              source: result.source,
              isSynced: result.isSynced,
              writtenBy: result.writtenBy,
              contributor: result.contributor,
              copyright: result.copyright,
              artworkUrl: result.artworkUrl ?? bestResult.artworkUrl,
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

      // If we have synced lyrics AND artwork, we can stop early.
      if (bestResult != null &&
          bestResult.lyrics.isNotEmpty &&
          bestResult.isSynced &&
          bestResult.artworkUrl != null) {
        return;
      }
    }
  }
}
