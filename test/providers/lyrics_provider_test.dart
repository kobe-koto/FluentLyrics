import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/media_service.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMediaController implements MediaController {
  @override
  Future<void> nextTrack() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playPause() async {}

  @override
  Future<void> previousTrack() async {}

  @override
  Future<void> seek(Duration position) async {}
}

class _FakeMediaService extends MediaService {
  _FakeMediaService(this._metadata);

  final MediaMetadata? _metadata;
  final _controller = _FakeMediaController();

  @override
  MediaMetadata? get metadata => _metadata;

  @override
  MediaPlaybackStatus get status => MediaPlaybackStatus.empty();

  @override
  MediaControlAbility get controlAbility => MediaControlAbility.none();

  @override
  MediaController get controller => _controller;

  @override
  void startPolling() {}

  void emitChange() {
    notifyListeners();
  }

  @override
  void stopPolling() {}
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService();

  List<String>? persistedTranslationTargetLanguages;
  List<String>? persistedTranslationIgnoredLanguages;

  @override
  Future<Setting<List<LyricProviderType>>> getAllProvidersOrdered() async {
    return const Setting(
      current: [LyricProviderType.lrclib],
      defaultValue: [LyricProviderType.lrclib],
      changed: false,
    );
  }

  @override
  Future<Setting<int>> getEnabledCount() async {
    return const Setting(current: 1, defaultValue: 1, changed: false);
  }

  @override
  Future<Setting<bool>> getCacheEnabled() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<List<LyricProviderType>> getPriority() async {
    return const [LyricProviderType.lrclib];
  }

  @override
  Future<Setting<int>> getLinesBefore() async {
    return const Setting(current: 1, defaultValue: 1, changed: false);
  }

  @override
  Future<Setting<int>> getGlobalOffset() async {
    return const Setting(current: 0, defaultValue: 0, changed: false);
  }

  @override
  Future<Setting<int>> getScrollAutoResumeDelay() async {
    return const Setting(current: 5, defaultValue: 5, changed: false);
  }

  @override
  Future<Setting<bool>> getBlurEnabled() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<bool>> getRichSyncEnabled() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<List<LyricProviderType>>> getTrimMetadataProviders() async {
    return const Setting(current: [], defaultValue: [], changed: false);
  }

  @override
  Future<Setting<double>> getFontSize() async {
    return const Setting(current: 36.0, defaultValue: 36.0, changed: false);
  }

  @override
  Future<Setting<double>> getInactiveScale() async {
    return const Setting(current: 0.85, defaultValue: 0.85, changed: false);
  }

  @override
  Future<Setting<bool>> getTranslationHighlightOnly() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<bool>> getTranslationEnabled() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<List<String>>> getTranslationTargetLanguages() async {
    return const Setting(
      current: ['zht'],
      defaultValue: ['zht'],
      changed: false,
    );
  }

  @override
  Future<Setting<List<String>>> getTranslationIgnoredLanguages() async {
    return const Setting(current: [], defaultValue: [], changed: false);
  }

  @override
  Future<void> setTranslationTargetLanguages(List<String> languages) async {
    persistedTranslationTargetLanguages = languages;
  }

  @override
  Future<void> setTranslationIgnoredLanguages(List<String> languages) async {
    persistedTranslationIgnoredLanguages = languages;
  }

  @override
  Future<Setting<int>> getTranslationBias() async {
    return const Setting(current: 50, defaultValue: 50, changed: false);
  }

  @override
  Future<Setting<int>> getTranslationAlignmentThreshold() async {
    return const Setting(current: 80, defaultValue: 80, changed: false);
  }

  @override
  Future<Setting<String>> getLlmApiEndpoint() async {
    return const Setting(current: '', defaultValue: '', changed: false);
  }

  @override
  Future<Setting<String>> getLlmApiKey() async {
    return const Setting(current: '', defaultValue: '', changed: false);
  }

  @override
  Future<Setting<String>> getLlmModel() async {
    return const Setting(current: '', defaultValue: '', changed: false);
  }

  @override
  Future<Setting<String>> getLlmReasoningEffort() async {
    return const Setting(current: 'auto', defaultValue: 'auto', changed: false);
  }

  @override
  Future<Setting<bool>> getKeepScreenOn() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<bool>> getBackgroundMotionEnabled() async {
    return const Setting(current: true, defaultValue: true, changed: false);
  }

  @override
  Future<Setting<bool>> getExperimentalRichInlineFontSizeGlitching() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }
}

class _FakeLyricsService extends LyricsService {
  _FakeLyricsService();

  int translationFetchCount = 0;
  List<String> lastTranslationLyrics = [];

  @override
  Stream<LyricsResult> fetchLyrics({
    required String title,
    required List<String> artist,
    required String album,
    required int durationSeconds,
    Function(String)? onStatusUpdate,
    Function(bool)? onFetchStatusUpdate,
    bool Function()? isCancelled,
    required List<LyricProviderType> trimMetadataProviders,
    required bool richSyncEnabled,
    Function(LyricsResult)? onTranslation,
    void Function(LyricsResult)? onCandidate,
    Future<bool> Function()? onPauseForCandidates,
  }) async* {
    final result = LyricsResult(
      lyrics: [lyric('old line', 1)],
      source: 'Initial',
    );
    onTranslation?.call(
      LyricsResult(
        lyrics: const [],
        source: 'Initial Translation',
        translation: true,
        language: 'zht',
        translationProvider: 'Initial Translation',
        rawTranslation: const [
          {'original': 'old line', 'translated': '旧'},
        ],
      ),
    );
    yield result;
  }

  @override
  Stream<LyricsResult> fetchTranslation({
    required LyricsResult bestResult,
    required String title,
    required List<String> artist,
    required String album,
    required int durationSeconds,
    bool Function()? isCancelled,
    void Function(LyricsResult)? onTranslationCandidate,
  }) async* {
    translationFetchCount++;
    lastTranslationLyrics = bestResult.lyrics.map((line) => line.text).toList();
    yield LyricsResult(
      lyrics: const [],
      source: 'Refetched Translation',
      translation: true,
      language: 'zht',
      translationProvider: 'Refetched Translation',
      rawTranslation: const [
        {'original': 'new line', 'translated': '新'},
      ],
    );
  }
}

class _FakeLyricsCacheService extends LyricsCacheService {
  @override
  Future<void> cacheLyrics(
    String title,
    List<String> artist,
    String? album,
    int durationSeconds,
    LyricsResult result,
  ) async {}
}

Lyric lyric(String text, int seconds) {
  return Lyric(
    startTime: Duration(seconds: seconds),
    text: text,
  );
}

void main() {
  test(
    'selectCandidate clears stale translation and refetches for new lyrics',
    () async {
      final lyricsService = _FakeLyricsService();
      final mediaService = _FakeMediaService(
        MediaMetadata(
          title: 'Song',
          artist: const ['Artist'],
          album: 'Album',
          duration: const Duration(seconds: 120),
          artUrl: 'fallback',
        ),
      );
      final provider = LyricsProvider(
        mediaService: mediaService,
        lyricsService: lyricsService,
        settingsService: _FakeSettingsService(),
        cacheService: _FakeLyricsCacheService(),
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      mediaService.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(
        provider.translationResult?.translationProvider,
        'Initial Translation',
      );

      await provider.selectCandidate(
        LyricsResult(lyrics: [lyric('new line', 2)], source: 'Candidate'),
      );

      expect(lyricsService.translationFetchCount, 1);
      expect(lyricsService.lastTranslationLyrics, ['new line']);
      expect(
        provider.translationResult?.translationProvider,
        'Refetched Translation',
      );

      provider.dispose();
    },
  );

  test(
    'changing translation target languages refreshes current translation',
    () async {
      final lyricsService = _FakeLyricsService();
      final mediaService = _FakeMediaService(
        MediaMetadata(
          title: 'Song',
          artist: const ['Artist'],
          album: 'Album',
          duration: const Duration(seconds: 120),
          artUrl: 'fallback',
        ),
      );
      final provider = LyricsProvider(
        mediaService: mediaService,
        lyricsService: lyricsService,
        settingsService: _FakeSettingsService(),
        cacheService: _FakeLyricsCacheService(),
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      mediaService.emitChange();
      await Future<void>.delayed(Duration.zero);

      expect(
        provider.translationResult?.translationProvider,
        'Initial Translation',
      );

      provider.setTranslationTargetLanguages(['ja']);
      await Future<void>.delayed(Duration.zero);

      expect(lyricsService.translationFetchCount, 1);
      expect(
        provider.translationResult?.translationProvider,
        'Refetched Translation',
      );

      provider.dispose();
    },
  );
}
