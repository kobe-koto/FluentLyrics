import 'package:fluent_lyrics/constants/app_defaults.dart';
import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:fluent_lyrics/screens/lyrics_screen.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/media_service.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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
    return const Setting(current: 2, defaultValue: 2, changed: false);
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
    return const Setting(current: false, defaultValue: false, changed: false);
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
    return const Setting(current: 42.0, defaultValue: 42.0, changed: false);
  }

  @override
  Future<Setting<double>> getInactiveScale() async {
    return const Setting(current: 1.0, defaultValue: 1.0, changed: false);
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

class _ScreenTestLyricsProvider extends LyricsProvider {
  _ScreenTestLyricsProvider()
    : super(
        mediaService: _FakeMediaService(),
        lyricsService: LyricsService(),
        settingsService: _FakeSettingsService(),
        cacheService: LyricsCacheService(),
      );

  static final List<Lyric> _testLyrics = List.generate(
    20,
    (index) => Lyric(
      startTime: Duration(seconds: index),
      text: 'Line $index',
    ),
  );

  static final LyricsResult _testResult = LyricsResult(
    lyrics: _testLyrics,
    source: '',
    isSynced: true,
  );

  static const Setting<int> _linesBeforeSetting = Setting(
    current: 2,
    defaultValue: 2,
    changed: false,
  );

  static const Setting<double> _fontSizeSetting = Setting(
    current: 42.0,
    defaultValue: 42.0,
    changed: false,
  );

  static const Setting<double> _inactiveScaleSetting = Setting(
    current: 1.0,
    defaultValue: 1.0,
    changed: false,
  );

  static final MediaMetadata _metadata = MediaMetadata(
    title: 'Test Song',
    artist: const ['Test Artist'],
    album: 'Test Album',
    duration: const Duration(minutes: 3),
    artUrl:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9p2Xc6sAAAAASUVORK5CYII=',
  );

  @override
  List<Lyric> get lyrics => _testLyrics;

  @override
  LyricsResult get lyricsResult => _testResult;

  @override
  LyricsResult? get translationResult => null;

  @override
  MediaMetadata? get currentMetadata => _metadata;

  @override
  int get currentIndex => 10;

  @override
  Setting<int> get linesBefore => _linesBeforeSetting;

  @override
  Setting<double> get fontSize => _fontSizeSetting;

  @override
  Setting<double> get inactiveScale => _inactiveScaleSetting;

  @override
  bool get isInterlude => false;

  @override
  bool get isLoading => false;

  @override
  bool get isPlaying => false;

  @override
  Duration get currentPosition => const Duration(seconds: 10);

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

/// Mutable provider that drives the lyrics through a track switch
/// (loading state -> new lyrics), mirroring how [LyricsProvider] notifies
/// its listeners when the media service reports a new track.
class _MutableTrackLyricsProvider extends _ScreenTestLyricsProvider {
  List<Lyric> _lyrics = const [];
  LyricsResult _result = LyricsResult(
    lyrics: const [],
    source: '',
    isSynced: false,
  );
  int _index = -1;
  bool _loading = true;

  @override
  List<Lyric> get lyrics => _lyrics;

  @override
  LyricsResult get lyricsResult => _result;

  @override
  int get currentIndex => _index;

  @override
  bool get isLoading => _loading;

  void setTrack(List<Lyric> lyrics, {int index = 0}) {
    _lyrics = lyrics;
    _result = LyricsResult(lyrics: lyrics, source: '', isSynced: true);
    _index = index;
    _loading = false;
    notifyListeners();
  }

  void beginLoading() {
    _lyrics = const [];
    _result = LyricsResult(lyrics: const [], source: '', isSynced: false);
    _index = -1;
    _loading = true;
    notifyListeners();
  }
}

/// Provider whose landscape leading space can be changed at runtime, so a test
/// can observe how the highlighted row is anchored in landscape.
class _LandscapeSpaceLyricsProvider extends _ScreenTestLyricsProvider {
  _LandscapeSpaceLyricsProvider(this._space);

  int _space;
  List<Lyric> _lyrics = const [];
  int _index = 0;

  @override
  Setting<int> get landscapeLeadingSpace => Setting(
    current: _space,
    defaultValue: AppDefaults.landscapeLeadingSpace,
    changed: _space != AppDefaults.landscapeLeadingSpace,
  );

  @override
  List<Lyric> get lyrics => _lyrics;

  @override
  int get currentIndex => _index;

  void setLandscapeSpace(int percent) => _space = percent;

  void setTrack(List<Lyric> lyrics, {int index = 0}) {
    // A fresh list instance makes the lyrics-reference change detection in
    // LyricsScreen fire, which is what re-anchors the list.
    _lyrics = List<Lyric>.of(lyrics);
    _index = index;
    notifyListeners();
  }
}

Widget _buildHarness(LyricsProvider provider) {
  return TranslationProvider(
    child: ChangeNotifierProvider<LyricsProvider>.value(
      value: provider,
      child: const MaterialApp(home: LyricsScreen()),
    ),
  );
}

bool _isTextVisible(WidgetTester tester, String text, Size surfaceSize) {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return false;
  final rect = tester.getRect(finder.first);
  return rect.bottom > 0 &&
      rect.right > 0 &&
      rect.top < surfaceSize.height &&
      rect.left < surfaceSize.width;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (condition()) return;
    await tester.pump(step);
    elapsed += step;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'resnaps to the current lyric after portrait/landscape branch switches',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      const portraitSize = Size(360, 640);
      const landscapeSize = Size(800, 450);
      final provider = _ScreenTestLyricsProvider();

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        provider.dispose();
      });

      await tester.binding.setSurfaceSize(portraitSize);
      await tester.pumpWidget(_buildHarness(provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(_isTextVisible(tester, 'Line 8', portraitSize), isTrue);
      expect(_isTextVisible(tester, 'Line 10', portraitSize), isTrue);

      await tester.binding.setSurfaceSize(landscapeSize);
      await tester.pump();
      await tester.pump();
      await _pumpUntil(
        tester,
        () => _isTextVisible(tester, 'Line 10', landscapeSize),
      );

      expect(_isTextVisible(tester, 'Line 7', landscapeSize), isFalse);
      expect(_isTextVisible(tester, 'Line 10', landscapeSize), isTrue);
    },
  );

  testWidgets('replaces the lyrics list when switching to a shorter track', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    const size = Size(360, 640);
    final provider = _MutableTrackLyricsProvider();

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      provider.dispose();
    });

    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(_buildHarness(provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    provider.setTrack(
      List.generate(
        60,
        (index) => Lyric(
          startTime: Duration(seconds: index),
          text: 'Old $index',
        ),
      ),
      index: 40,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_isTextVisible(tester, 'Old 40', size), isTrue);

    // A real track switch passes through the loading state, which disposes
    // the ScrollablePositionedList and remounts it for the new track.
    provider.beginLoading();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    provider.setTrack(
      List.generate(
        12,
        (index) => Lyric(
          startTime: Duration(seconds: index),
          text: 'New $index',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // The visible rows must form a contiguous window anchored on the current
    // line. A non-contiguous set means ScrollablePositionedList is stuck
    // mid fade-transition, still rendering rows from the previous scroll
    // offset — the "no lyrics after a track switch" failure.
    final rendered = <int>[];
    for (final element in find.byType(Text).evaluate()) {
      final data = (element.widget as Text).data;
      if (data != null && data.startsWith('New ')) {
        rendered.add(int.parse(data.substring(4)));
      }
    }
    rendered.sort();
    expect(rendered, isNotEmpty);
    expect(
      rendered,
      List.generate(rendered.length, (index) => rendered.first + index),
      reason: 'rendered lyric rows should be contiguous',
    );
    expect(_isTextVisible(tester, 'New 0', size), isTrue);
  });

  testWidgets('landscape leading space follows the user setting', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final provider = _LandscapeSpaceLyricsProvider(
      AppDefaults.landscapeLeadingSpace,
    );

    addTearDown(() {
      tester.view.reset();
      provider.dispose();
    });

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 450);
    await tester.pumpWidget(_buildHarness(provider));
    await tester.pump();

    final lyrics = List.generate(
      30,
      (index) => Lyric(
        startTime: Duration(seconds: index),
        text: 'Line $index',
      ),
    );

    Future<double> measureActiveRow(int spacePercent) async {
      provider.setLandscapeSpace(spacePercent);
      // A new lyrics instance re-anchors the list, applying the new spacing.
      provider.setTrack(lyrics, index: 10);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final viewport = tester.getRect(
        find.byType(ScrollablePositionedList).first,
      );
      final row = tester.getRect(find.text('Line 10'));
      return (row.top - viewport.top) / viewport.height;
    }

    final at30 = await measureActiveRow(30);
    final at0 = await measureActiveRow(0);
    final at50 = await measureActiveRow(50);

    // The active row sits `spacePercent` of the viewport height below the top,
    // so the deltas between settings are the deltas of the setting itself.
    expect(at30 - at0, closeTo(0.30, 0.05));
    expect(at50 - at0, closeTo(0.50, 0.05));
  });
}
