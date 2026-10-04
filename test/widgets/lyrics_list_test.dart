import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/media_service.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:fluent_lyrics/widgets/lyric_line.dart';
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
  Future<Setting<bool>> getExperimentalAnnotationFontSizeGlitching() async {
    return const Setting(current: false, defaultValue: false, changed: false);
  }

  @override
  Future<Setting<bool>> getExperimentalStripTimestampsBeforeRender() async {
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
  bool isManualScrolling = false,
}) {
  return TranslationProvider(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ListenableBuilder(
              listenable: provider,
              builder: (context, _) => LyricsList(
                provider: provider,
                itemScrollController: ItemScrollController(),
                itemPositionsListener: ItemPositionsListener.create(),
                isManualScrolling: isManualScrolling,
                onUserInteraction: (_) {},
                onViewportResized: onViewportResized,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _UnsyncedListProvider extends _TestLyricsProvider {
  _UnsyncedListProvider(this.lines, {this.metadata, this.playing = false})
    : result = LyricsResult(lyrics: lines, source: 'Plain', isSynced: false);

  List<Lyric> lines;
  MediaMetadata? metadata;
  late LyricsResult result;
  int seekCount = 0;
  bool playing;

  static const Setting<double> fontSizeSetting = Setting(
    current: 36,
    defaultValue: 36,
    changed: false,
  );

  @override
  List<Lyric> get lyrics => lines;

  @override
  LyricsResult get lyricsResult => result;

  @override
  MediaMetadata? get currentMetadata => metadata;

  @override
  int get currentIndex => lines.length - 1;

  @override
  bool get isPlaying => playing;

  @override
  Setting<double> get fontSize => fontSizeSetting;

  @override
  Duration get globalOffset => const Duration(seconds: 30);

  @override
  Duration get trackOffset => const Duration(seconds: 30);

  @override
  MediaControlAbility get controlAbility => MediaControlAbility(
    canPlayPause: true,
    canGoNext: false,
    canGoPrevious: false,
    canSeek: true,
  );

  @override
  Future<void> seek(Duration position) async {
    seekCount++;
  }

  void replaceLines(List<Lyric> next) {
    lines = next;
    result = LyricsResult(lyrics: next, source: 'Plain', isSynced: false);
    notifyListeners();
  }
}

ScrollPosition _scrollOffset(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable)).position;
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

  testWidgets(
    'unsynced lyrics scroll with the track and skip highlight effects',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      const duration = Duration(minutes: 3);
      final lines = List<Lyric>.generate(
        80,
        (index) => Lyric(
          startTime: Duration.zero,
          text: 'Line $index',
          translation: index == 0 ? '译文' : null,
        ),
      );
      final provider = _UnsyncedListProvider(
        lines,
        metadata: MediaMetadata(
          title: 'Song',
          artist: const ['Artist'],
          album: 'Album',
          duration: duration,
          artUrl: 'fallback',
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          onViewportResized: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LyricLine), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.byType(ScrollablePositionedList), findsNothing);
      expect(find.text('译文'), findsOneWidget);

      final line = tester.widget<Text>(find.text('Line 0'));
      expect(line.style?.fontFamily, 'Outfit');
      expect(line.style?.fontSize, 36);
      expect(line.style?.color, Colors.white);

      for (final element in find.byType(GestureDetector).evaluate()) {
        expect((element.widget as GestureDetector).onDoubleTap, isNull);
      }

      await tester.tap(find.text('Line 0'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Line 0'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(provider.seekCount, 0);
      expect(_scrollOffset(tester).pixels, 0);

      provider.currentPositionNotifier.value = duration ~/ 2;
      await tester.pumpAndSettle();

      final halfway = _scrollOffset(tester);
      expect(halfway.pixels, closeTo(halfway.maxScrollExtent * 0.5, 1));

      provider.dispose();
    },
  );

  testWidgets('unsynced position ticks do not rebuild the list', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    const duration = Duration(minutes: 3);
    final provider = _UnsyncedListProvider(
      List<Lyric>.generate(
        40,
        (index) => Lyric(startTime: Duration.zero, text: 'Line $index'),
      ),
      metadata: MediaMetadata(
        title: 'Song',
        artist: const ['Artist'],
        album: 'Album',
        duration: duration,
        artUrl: 'fallback',
      ),
    );

    Future<void> pumpList() {
      return tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          onViewportResized: () {},
        ),
      );
    }

    await pumpList();
    await tester.pumpAndSettle();

    final lineElement = find.text('Line 0').evaluate().single;
    final lineWidget = lineElement.widget;
    final listElement = find.byType(ListView).evaluate().single;

    provider.currentPositionNotifier.value = const Duration(seconds: 1);
    await tester.pumpAndSettle();

    expect(
      identical(find.text('Line 0').evaluate().single, lineElement),
      isTrue,
    );
    expect(identical(lineElement.widget, lineWidget), isTrue);
    expect(
      identical(find.byType(ListView).evaluate().single, listElement),
      isTrue,
    );
    expect(_scrollOffset(tester).pixels, greaterThan(0));

    await pumpList();
    await tester.pump();

    expect(
      identical(find.text('Line 0').evaluate().single, lineElement),
      isTrue,
    );
    expect(identical(lineElement.widget, lineWidget), isTrue);

    provider.replaceLines(
      List<Lyric>.generate(
        8,
        (index) => Lyric(startTime: Duration.zero, text: 'Next $index'),
      ),
    );
    await tester.pump();

    expect(find.text('Line 0'), findsNothing);
    expect(find.text('Next 0'), findsOneWidget);

    provider.dispose();
  });

  testWidgets('unsynced lyrics do not scroll without a track duration', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final lines = List<Lyric>.generate(
      40,
      (index) => Lyric(startTime: Duration.zero, text: 'Line $index'),
    );
    final provider = _UnsyncedListProvider(
      lines,
      metadata: MediaMetadata(
        title: 'Song',
        artist: const ['Artist'],
        album: 'Album',
        duration: Duration.zero,
        artUrl: 'fallback',
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        provider: provider,
        width: 240,
        height: 320,
        onViewportResized: () {},
      ),
    );
    await tester.pump();

    provider.currentPositionNotifier.value = const Duration(seconds: 30);
    await tester.pump();
    expect(_scrollOffset(tester).pixels, 0);

    provider.metadata = null;
    provider.notifyListeners();
    provider.currentPositionNotifier.value = const Duration(seconds: 90);
    await tester.pump();
    expect(_scrollOffset(tester).pixels, 0);

    provider.dispose();
  });

  testWidgets('manual scrolling pauses unsynced progress follow', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    const duration = Duration(minutes: 3);
    final provider = _UnsyncedListProvider(
      List<Lyric>.generate(
        40,
        (index) => Lyric(startTime: Duration.zero, text: 'Line $index'),
      ),
      metadata: MediaMetadata(
        title: 'Song',
        artist: const ['Artist'],
        album: 'Album',
        duration: duration,
        artUrl: 'fallback',
      ),
    );

    Future<void> pumpList({required bool manual}) {
      return tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          isManualScrolling: manual,
          onViewportResized: () {},
        ),
      );
    }

    await pumpList(manual: true);
    await tester.pumpAndSettle();
    provider.currentPositionNotifier.value = duration ~/ 2;
    await tester.pumpAndSettle();
    expect(_scrollOffset(tester).pixels, 0);

    await pumpList(manual: false);
    await tester.pumpAndSettle();
    final position = _scrollOffset(tester);
    expect(position.pixels, closeTo(position.maxScrollExtent * 0.5, 1));

    provider.dispose();
  });

  testWidgets(
    'playing unsynced lyrics advance at a constant rate and ignore small corrections',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      const duration = Duration(seconds: 60);
      final provider = _UnsyncedListProvider(
        List<Lyric>.generate(
          40,
          (index) => Lyric(startTime: Duration.zero, text: 'Line $index'),
        ),
        playing: true,
        metadata: MediaMetadata(
          title: 'Song',
          artist: const ['Artist'],
          album: 'Album',
          duration: duration,
          artUrl: 'fallback',
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          provider: provider,
          width: 240,
          height: 320,
          onViewportResized: () {},
        ),
      );
      await tester.pump();

      final extent = _scrollOffset(tester).maxScrollExtent;
      final perSecond = extent / duration.inSeconds;
      final start = _scrollOffset(tester).pixels;

      await tester.pump(const Duration(seconds: 1));
      final afterOne = _scrollOffset(tester).pixels;
      expect(_scrollOffset(tester).maxScrollExtent, closeTo(extent, 0.5));
      await tester.pump(const Duration(seconds: 1));
      final afterTwo = _scrollOffset(tester).pixels;

      expect(afterOne - start, closeTo(perSecond, 1.5));
      expect(afterTwo - afterOne, closeTo(perSecond, 1.5));
      expect(afterOne, greaterThan(start));
      expect(afterTwo, greaterThan(afterOne));

      // 2s of playback versus a 1s sample is inside the seek snap window.
      // The linear run must keep its speed instead of restarting behind.
      provider.currentPositionNotifier.value = const Duration(seconds: 1);
      expect(_scrollOffset(tester).pixels, closeTo(afterTwo, 1));
      await tester.pump(const Duration(seconds: 1));
      final afterThree = _scrollOffset(tester).pixels;
      expect(afterThree - afterTwo, closeTo(perSecond, 1.5));
      expect(afterThree, greaterThan(afterTwo));

      provider.currentPositionNotifier.value = const Duration(seconds: 30);
      expect(_scrollOffset(tester).pixels, closeTo(extent * 0.5, 1.5));

      provider.currentPositionNotifier.value = const Duration(seconds: 10);
      expect(_scrollOffset(tester).pixels, closeTo(extent * 10 / 60, 1.5));

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
}
