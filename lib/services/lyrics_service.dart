import '../models/lyric_model.dart';
import 'providers/lrclib_service.dart';
import 'providers/musixmatch_service.dart';
import 'settings_service.dart';

class LyricsService {
  final LrclibService _lrclibService = LrclibService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final SettingsService _settingsService = SettingsService();

  Future<List<Lyric>> fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
  }) async {
    final priority = await _settingsService.getPriority();

    for (var provider in priority) {
      List<Lyric> lyrics = [];
      if (provider == LyricProviderType.lrclib) {
        lyrics = await _lrclibService.fetchLyrics(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      } else if (provider == LyricProviderType.musixmatch) {
        lyrics = await _musixmatchService.fetchLyrics(
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          onStatusUpdate: onStatusUpdate,
        );
      }

      if (lyrics.isNotEmpty) {
        return lyrics;
      }
    }

    return [];
  }
}
