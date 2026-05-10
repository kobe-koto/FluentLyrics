import 'package:fluent_lyrics/models/lyric_model.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/models/setting.dart';
import 'package:fluent_lyrics/services/lyrics_service.dart';
import 'package:fluent_lyrics/services/lyrics_source_registry.dart';
import 'package:fluent_lyrics/services/providers/lyrics_cache_service.dart';
import 'package:fluent_lyrics/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({
    this.cacheEnabled = false,
    this.targetLanguages = const ['zht'],
    this.priority = const [
      LyricProviderType.musixmatch,
      LyricProviderType.netease,
    ],
  });

  final bool cacheEnabled;
  final List<String> targetLanguages;
  final List<LyricProviderType> priority;

  @override
  Future<Setting<bool>> getCacheEnabled() async {
    return Setting(
      current: cacheEnabled,
      defaultValue: cacheEnabled,
      changed: false,
    );
  }

  @override
  Future<Setting<List<String>>> getTranslationTargetLanguages() async {
    return Setting(
      current: targetLanguages,
      defaultValue: targetLanguages,
      changed: false,
    );
  }

  @override
  Future<Setting<List<String>>> getTranslationIgnoredLanguages() async {
    return const Setting(current: [], defaultValue: [], changed: false);
  }

  @override
  Future<Setting<int>> getTranslationBias() async {
    return const Setting(current: 50, defaultValue: 50, changed: false);
  }

  @override
  Future<List<LyricProviderType>> getPriority() async => priority;
}

class _FakeLyricsCacheService extends LyricsCacheService {
  _FakeLyricsCacheService(this.cachedTranslations);

  final Map<String, LyricsResult> cachedTranslations;
  final List<String> requestedCacheIds = [];

  @override
  String generateTranslationCacheId(
    String title,
    List<String> artist,
    String language,
  ) {
    return language;
  }

  @override
  Future<LyricsResult?> getCachedTranslation(String cacheId) async {
    requestedCacheIds.add(cacheId);
    return cachedTranslations[cacheId];
  }

  @override
  Future<void> cacheTranslation(String cacheId, LyricsResult result) async {
    cachedTranslations[cacheId] = result;
  }
}

class _FakeTranslationSource extends LyricsSource {
  _FakeTranslationSource(
    this.type,
    this.providerName, {
    List<String>? requestedLanguages,
  }) : requestedLanguages = requestedLanguages ?? [];

  @override
  final LyricProviderType type;
  final String providerName;
  final List<String> requestedLanguages;

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) async {
    return LyricsResult.empty();
  }

  @override
  bool checkTranslationSupport(String language) => true;

  @override
  Future<LyricsResult> fetchTranslation(
    LyricsTranslationRequest request,
  ) async {
    requestedLanguages.add(request.targetLanguage);
    return LyricsResult(
      lyrics: const [],
      source: providerName,
      translation: true,
      language: request.targetLanguage,
      translationProvider: providerName,
      rawTranslation: [
        {'original': 'hello', 'translated': providerName},
      ],
    );
  }
}

void main() {
  Lyric lyric(String text, int seconds) {
    return Lyric(
      startTime: Duration(seconds: seconds),
      text: text,
    );
  }

  test('fetchTranslation yields only the first online result', () async {
    final service = LyricsService(
      settingsService: _FakeSettingsService(),
      sourceRegistry: LyricsSourceRegistry(
        sources: [
          _FakeTranslationSource(LyricProviderType.musixmatch, 'Musixmatch'),
          _FakeTranslationSource(LyricProviderType.netease, 'Netease Music'),
        ],
      ),
    );
    final candidates = <String>[];

    final results = await service
        .fetchTranslation(
          bestResult: LyricsResult(
            lyrics: [lyric('hello', 1)],
            source: 'lyrics',
          ),
          title: 'Song',
          artist: const ['Artist'],
          album: 'Album',
          durationSeconds: 120,
          onTranslationCandidate: (candidate) {
            candidates.add(candidate.translationProvider!);
          },
        )
        .toList();

    expect(results, hasLength(1));
    expect(results.single.translationProvider, 'Musixmatch');
    expect(candidates, ['Musixmatch', 'Netease Music']);
  });

  test(
    'fetchTranslation keeps target language priority with partial cache',
    () async {
      final cacheService = _FakeLyricsCacheService({
        'zh_CN': LyricsResult(
          lyrics: const [],
          source: 'Cache',
          translation: true,
          language: 'zh_CN',
          translationProvider: 'Cache',
          rawTranslation: const [
            {'original': 'hello', 'translated': '你好'},
          ],
        ),
      });
      final onlineRequestedLanguages = <String>[];
      final candidates = <String>[];
      final service = LyricsService(
        settingsService: _FakeSettingsService(
          cacheEnabled: true,
          targetLanguages: const ['zht', 'zh_CN'],
          priority: const [LyricProviderType.musixmatch],
        ),
        cacheService: cacheService,
        sourceRegistry: LyricsSourceRegistry(
          sources: [
            _FakeTranslationSource(
              LyricProviderType.musixmatch,
              'Musixmatch',
              requestedLanguages: onlineRequestedLanguages,
            ),
          ],
        ),
      );

      final results = await service
          .fetchTranslation(
            bestResult: LyricsResult(
              lyrics: [lyric('hello', 1)],
              source: 'lyrics',
            ),
            title: 'Song',
            artist: const ['Artist'],
            album: 'Album',
            durationSeconds: 120,
            onTranslationCandidate: (candidate) {
              candidates.add(candidate.translationProvider!);
            },
          )
          .toList();

      expect(cacheService.requestedCacheIds, ['zht', 'zh_CN']);
      expect(onlineRequestedLanguages, ['zht']);
      expect(candidates, ['Musixmatch', 'Cache (cached)']);
      expect(results, hasLength(1));
      expect(results.single.translationProvider, 'Musixmatch');
    },
  );
}
