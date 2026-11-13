import 'dart:io';

import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/providers/lyrics_provider.dart';
import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/media_service.dart';
import 'package:fluent_lyrics/services/opencc/zh_conversion_service.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:fluent_lyrics/utils/lyrics_candidate_helper.dart';
import 'package:fluent_lyrics/widgets/screen/lyrics/lyrics_candidate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simplified source text and its expected Traditional (zh_TW / s2twp) form.
const _simplified = '开放中文转换';
const _traditional = '開放中文轉換';

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

/// Provider stub that exposes a Simplified-Chinese lyrics candidate and a
/// Simplified-Chinese translation candidate, with Traditional conversion on.
class _SheetTestProvider extends LyricsProvider {
  _SheetTestProvider({required this.showTranslation})
    : super(
        mediaService: _FakeMediaService(),
        lyricsService: LyricsService(),
        settingsService: SettingsService(),
        cacheService: LyricsCacheService(),
      );

  final bool showTranslation;

  final _lyricsCandidate = LyricsResult(
    lyrics: [Lyric(startTime: Duration.zero, text: _simplified)],
    source: 'lrclib',
    isSynced: true,
    language: 'zh',
  );

  final _translationCandidate = LyricsResult(
    lyrics: const [],
    source: 'netease',
    translationProvider: 'netease',
    language: 'zh',
    rawTranslation: const [
      {'original': 'open', 'translated': _simplified},
    ],
  );

  final _current = LyricsResult(
    lyrics: [Lyric(startTime: Duration.zero, text: 'current')],
    source: 'current',
    isSynced: true,
  );

  @override
  List<LyricsResult> get candidates => [_lyricsCandidate];
  @override
  List<LyricsResult> get translationCandidates => [_translationCandidate];
  @override
  List<SkippedLyricsSource> get skippedSources => const [];
  @override
  LyricsResult get lyricsResult => _current;
  @override
  LyricsResult? get translationResult => null;
  @override
  List<Lyric> get lyrics => _current.lyrics;
  @override
  bool get isFetching => false;
  @override
  bool get isLoading => false;
  @override
  String get loadingStatus => '';

  @override
  Setting<bool> get translationEnabled => Setting<bool>(
    current: showTranslation,
    defaultValue: showTranslation,
    changed: false,
  );
  @override
  Setting<String> get zhConversionTarget => const Setting<String>(
    current: 'zh_TW',
    defaultValue: 'off',
    changed: true,
  );
  @override
  Setting<List<String>> get zhConversionIgnoredLanguages =>
      const Setting<List<String>>(
        current: ['ja'],
        defaultValue: ['ja'],
        changed: false,
      );
  @override
  Setting<int> get translationAlignmentThreshold =>
      const Setting<int>(current: 70, defaultValue: 70, changed: false);

  // Opening the sheet would normally resume the paused auto-fetch; the stub
  // has no fetch in flight.
  @override
  void setCandidateSheetOpen(bool isOpen) {}
  @override
  void resumeCandidateFetch() {}
}

Future<void> _openSheet(WidgetTester tester, LyricsProvider provider) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showLyricsCandidateSheet(context, provider),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.setLocaleSync(AppLocale.en);

  late Directory openCcDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    openCcDir = Directory.systemTemp.createTempSync('sheet_opencc');
    // The sheet converts previews synchronously, so OpenCC must be ready
    // before the first build.
    await ZhConversionService.instance.ensureInitialized(directory: openCcDir);
  });

  tearDown(() {
    ZhConversionService.instance.reset();
    if (openCcDir.existsSync()) openCcDir.deleteSync(recursive: true);
  });

  testWidgets('lyrics preview is converted to the target script', (
    tester,
  ) async {
    final provider = _SheetTestProvider(showTranslation: false);
    addTearDown(provider.dispose);

    await _openSheet(tester, provider);

    expect(find.textContaining(_traditional), findsWidgets);
    expect(find.textContaining(_simplified), findsNothing);
  });

  testWidgets('translation preview is converted to the target script', (
    tester,
  ) async {
    final provider = _SheetTestProvider(showTranslation: true);
    addTearDown(provider.dispose);

    await _openSheet(tester, provider);
    await tester.tap(find.text(t.candidateSheet.translationTab));
    await tester.pumpAndSettle();

    expect(find.textContaining(_traditional), findsWidgets);
    expect(find.textContaining(_simplified), findsNothing);
  });
}
