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
    this.translationAlignmentThreshold = 80,
    this.translationCoverageThreshold = 80,
  });

  final bool cacheEnabled;
  final List<String> targetLanguages;
  final List<LyricProviderType> priority;
  final int translationAlignmentThreshold;
  final int translationCoverageThreshold;

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
  Future<Setting<int>> getTranslationAlignmentThreshold() async {
    return Setting(
      current: translationAlignmentThreshold,
      defaultValue: translationAlignmentThreshold,
      changed: false,
    );
  }

  @override
  Future<Setting<int>> getTranslationCoverageThreshold() async {
    return Setting(
      current: translationCoverageThreshold,
      defaultValue: translationCoverageThreshold,
      changed: false,
    );
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

      expect(cacheService.requestedCacheIds, [
        LyricsCacheService.manualTranslationSkipLanguage,
        'zht',
        'zh_CN',
      ]);
      expect(onlineRequestedLanguages, ['zht']);
      expect(candidates, ['Musixmatch', 'Cache (cached)']);
      expect(results, hasLength(1));
      expect(results.single.translationProvider, 'Musixmatch');
    },
  );

  test(
    'fetchTranslation skips only the matching source language target',
    () async {
      final onlineRequestedLanguages = <String>[];
      final service = LyricsService(
        settingsService: _FakeSettingsService(
          targetLanguages: const ['zht', 'zh_CN'],
          priority: const [LyricProviderType.musixmatch],
        ),
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
              language: 'zh_CN',
            ),
            title: 'Song',
            artist: const ['Artist'],
            album: 'Album',
            durationSeconds: 120,
          )
          .toList();

      expect(onlineRequestedLanguages, ['zht']);
      expect(results, hasLength(1));
      expect(results.single.language, 'zht');
    },
  );

  test(
    'fetchTranslation refetches cached translation below coverage threshold',
    () async {
      final cacheService = _FakeLyricsCacheService({
        'zht': LyricsResult(
          lyrics: const [],
          source: 'Cache',
          translation: true,
          translationInvalidatable: true,
          language: 'zht',
          translationProvider: 'Cache',
          rawTranslation: const [
            {'original': 'hello', 'translated': '你好'},
          ],
        ),
      });
      final onlineRequestedLanguages = <String>[];
      final service = LyricsService(
        settingsService: _FakeSettingsService(
          cacheEnabled: true,
          translationAlignmentThreshold: 80,
          translationCoverageThreshold: 100,
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
              lyrics: [lyric('hello', 1), lyric('world', 2)],
              source: 'lyrics',
            ),
            title: 'Song',
            artist: const ['Artist'],
            album: 'Album',
            durationSeconds: 120,
          )
          .toList();

      expect(cacheService.requestedCacheIds, [
        LyricsCacheService.manualTranslationSkipLanguage,
        'zht',
      ]);
      expect(onlineRequestedLanguages, ['zht']);
      expect(results, hasLength(1));
      expect(results.single.translationProvider, 'Musixmatch');
    },
  );

  test(
    'fetchTranslation reuses non-invalidatable cached translation without coverage check',
    () async {
      final cacheService = _FakeLyricsCacheService({
        'zht': LyricsResult(
          lyrics: const [],
          source: 'Cache',
          translation: true,
          language: 'zht',
          translationProvider: 'Cache',
          rawTranslation: const [
            {'original': 'different lyrics', 'translated': '你好'},
          ],
        ),
      });
      final onlineRequestedLanguages = <String>[];
      final service = LyricsService(
        settingsService: _FakeSettingsService(
          cacheEnabled: true,
          translationCoverageThreshold: 100,
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
              lyrics: [lyric('hello', 1), lyric('world', 2)],
              source: 'lyrics',
            ),
            title: 'Song',
            artist: const ['Artist'],
            album: 'Album',
            durationSeconds: 120,
          )
          .toList();

      expect(cacheService.requestedCacheIds, [
        LyricsCacheService.manualTranslationSkipLanguage,
        'zht',
      ]);
      expect(onlineRequestedLanguages, isEmpty);
      expect(results, hasLength(1));
      expect(results.single.translationProvider, 'Cache (cached)');
    },
  );

  test('fetchTranslation uses manual skip cache before providers', () async {
    final cacheService = _FakeLyricsCacheService({
      LyricsCacheService.manualTranslationSkipLanguage: LyricsResult(
        lyrics: const [],
        source: 'SKIPPED',
        translation: false,
        language: LyricsCacheService.manualTranslationSkipLanguage,
        translationProvider: LyricsCacheService.manualTranslationSkipProvider,
      ),
    });
    final onlineRequestedLanguages = <String>[];
    final service = LyricsService(
      settingsService: _FakeSettingsService(
        cacheEnabled: true,
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
        )
        .toList();

    expect(cacheService.requestedCacheIds, [
      LyricsCacheService.manualTranslationSkipLanguage,
    ]);
    expect(onlineRequestedLanguages, isEmpty);
    expect(results, hasLength(1));
    expect(results.single.source, 'SKIPPED');
    expect(
      results.single.translationProvider,
      LyricsCacheService.manualTranslationSkipProvider,
    );
  });

  test('fetchTranslation reuses provider skipped cache', () async {
    final cacheService = _FakeLyricsCacheService({
      'zht': LyricsResult(
        lyrics: [lyric('hello', 1)],
        source: 'SKIPPED',
        translation: false,
        translationInvalidatable: true,
        language: 'zht',
        translationProvider: 'LLM Translation',
      ),
    });
    final onlineRequestedLanguages = <String>[];
    final service = LyricsService(
      settingsService: _FakeSettingsService(
        cacheEnabled: true,
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
        )
        .toList();

    expect(cacheService.requestedCacheIds, [
      LyricsCacheService.manualTranslationSkipLanguage,
      'zht',
    ]);
    expect(onlineRequestedLanguages, isEmpty);
    expect(results, hasLength(1));
    expect(results.single.source, 'SKIPPED');
    expect(results.single.translationProvider, 'LLM Translation (cached)');
  });
}
