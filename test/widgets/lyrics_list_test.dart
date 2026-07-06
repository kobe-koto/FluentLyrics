import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/media_service.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:fluent_lyrics/widgets/screen/lyrics/lyrics_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final _controller = _FakeMediaController();

  @override
  MediaMetadata? get metadata => null;

  @override
  MediaPlaybackStatus get status => MediaPlaybackStatus.empty();

  @override
  MediaControlAbility get controlAbility => MediaControlAbility.none();

  @override
  MediaController get controller => _controller;

  @override
  void startPolling() {}

  @override
  void stopPolling() {}
}

class _FakeSettingsService extends SettingsService {
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
    return const Setting(current: false, defaultValue: false, changed: false);
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
  Future<Setting<int>> getTranslationBias() async {
    return const Setting(current: 0, defaultValue: 0, changed: false);
  }

  @override
  Future<Setting<int>> getTranslationAlignmentThreshold() async {
    return const Setting(current: 300, defaultValue: 300, changed: false);
  }

  @override
  Future<Setting<int>> getTranslationCoverageThreshold() async {
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
    return const Setting(current: '', defaultValue: '', changed: false);
  }

  @override
  Future<Setting<bool>> getKeepScreenOn() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<bool>> getBackgroundMotionEnabled() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<bool>> getExperimentalRichInlineFontSizeGlitching() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<bool>> getTrayEnabled() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<bool>> getHideToTrayOnClose() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<String>> getLyricsStreamPath() async {
    return const Setting(current: '', defaultValue: '', changed: false);
  }

  @override
  Future<Setting<String>> getTranslationStreamPath() async {
    return const Setting(current: '', defaultValue: '', changed: false);
  }
}

class _TestLyricsProvider extends LyricsProvider {
  _TestLyricsProvider()
    : super(
        mediaService: _FakeMediaService(),
        lyricsService: LyricsService(),
        settingsService: _FakeSettingsService(),
        cacheService: LyricsCacheService(),
      );

  static final List<Lyric> _testLyrics = [
    Lyric(startTime: Duration.zero, text: 'One line'),
  ];

  static final LyricsResult _testResult = LyricsResult(
    lyrics: _testLyrics,
    source: '',
    isSynced: true,
  );

  @override
  List<Lyric> get lyrics => _testLyrics;

  @override
  LyricsResult get lyricsResult => _testResult;

  @override
  LyricsResult? get translationResult => null;

  @override
  int get currentIndex => 0;

  @override
  bool get isInterlude => false;

  @override
  bool get isLoading => false;

  @override
  bool get isPlaying => false;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Duration get globalOffset => Duration.zero;

  @override
  Duration get trackOffset => Duration.zero;

  @override
  double interludeProgressForPosition(Duration position) => 0.0;

  @override
  Duration get interludeDuration => Duration.zero;

  @override
  Future<void> seek(Duration position) async {}
}

Widget _buildHarness({
  required LyricsProvider provider,
  required double width,
  required double height,
  required VoidCallback onViewportResized,
}) {
  return TranslationProvider(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: LyricsList(
              provider: provider,
              itemScrollController: ItemScrollController(),
              itemPositionsListener: ItemPositionsListener.create(),
              isManualScrolling: false,
              onUserInteraction: (_) {},
              onViewportResized: onViewportResized,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'debounces viewport resnaps and ignores repeated same-size layouts',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      final provider = _TestLyricsProvider();
      var resizeCount = 0;

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          onViewportResized: () {
            resizeCount++;
          },
        ),
      );
      await tester.pump();

      expect(resizeCount, 0);

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          onViewportResized: () {
            resizeCount++;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      expect(resizeCount, 0);

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 260,
          height: 320,
          onViewportResized: () {
            resizeCount++;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 49));

      expect(resizeCount, 0);

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 300,
          height: 320,
          onViewportResized: () {
            resizeCount++;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 49));

      expect(resizeCount, 0);

      await tester.pump(const Duration(milliseconds: 1));

      expect(resizeCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      provider.dispose();
    },
  );
}
