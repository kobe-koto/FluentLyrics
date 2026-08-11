import '../models/lyric_model.dart';
import '../models/lyric_provider_type.dart';
import '../models/general_translation_request_data.dart';
import 'settings_service.dart';
import 'providers/lrclib_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'providers/qqmusic_service.dart';
import 'providers/lyrics_cache_service.dart';
import 'providers/llm_translation_service.dart';
import '../utils/app_logger.dart';
import '../utils/translation_helper.dart';
import 'lyrics_source_registry.dart';
import 'winner_selector.dart';

class LyricsService {
  final SettingsService _settingsService;
  // lyrics providers
  final LrclibService _lrclibService;
  final MusixmatchService _musixmatchService;
  final NeteaseService _neteaseService;
  final QQMusicService _qqMusicService;
  final LlmTranslationService _llmService;
  final LyricsCacheService _cacheService;
  final LyricsSourceRegistry? _sourceRegistryOverride;
  late final LyricsSourceRegistry _sourceRegistry =
      _sourceRegistryOverride ??
      LyricsSourceRegistry.fromServices(
        lrclibService: _lrclibService,
        musixmatchService: _musixmatchService,
        neteaseService: _neteaseService,
        qqMusicService: _qqMusicService,
        llmService: _llmService,
        cacheService: _cacheService,
      );

  LyricsService({
    SettingsService? settingsService,
    LrclibService? lrclibService,
    MusixmatchService? musixmatchService,
    NeteaseService? neteaseService,
    QQMusicService? qqMusicService,
    LlmTranslationService? llmService,
    LyricsCacheService? cacheService,
    LyricsSourceRegistry? sourceRegistry,
  }) : this._(
         settingsService: settingsService ?? SettingsService(),
         lrclibService: lrclibService,
         musixmatchService: musixmatchService,
         neteaseService: neteaseService,
         qqMusicService: qqMusicService,
         llmService: llmService,
         cacheService: cacheService,
         sourceRegistry: sourceRegistry,
       );

  LyricsService._({
    required SettingsService settingsService,
    LrclibService? lrclibService,
    MusixmatchService? musixmatchService,
    NeteaseService? neteaseService,
    QQMusicService? qqMusicService,
    LlmTranslationService? llmService,
    LyricsCacheService? cacheService,
    LyricsSourceRegistry? sourceRegistry,
  }) : _settingsService = settingsService,
       _lrclibService = lrclibService ?? LrclibService(),
       _musixmatchService = musixmatchService ?? MusixmatchService(),
       _neteaseService = neteaseService ?? NeteaseService(),
       _qqMusicService = qqMusicService ?? QQMusicService(),
       _llmService = llmService ?? LlmTranslationService(settingsService),
       _cacheService = cacheService ?? LyricsCacheService(),
       _sourceRegistryOverride = sourceRegistry;

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

    /// Called for every provider result that has lyrics (not only the current best).
    void Function(LyricsResult)? onCandidate,

    /// Called once when we would normally break early (good-enough result found).
    /// Awaited: return true to continue fetching remaining providers, false to stop.
    Future<bool> Function()? onPauseForCandidates,
  }) async* {
    AppLogger.debug(
      '[LyricsService.fetchLyrics] Fetching lyrics for $title - ${artist.join(', ')}',
    );
    final priority = await _settingsService.getPriority();
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;
    final translationEnabled =
        (await _settingsService.getTranslationEnabled()).current;

    final translationBias =
        (await _settingsService.getTranslationBias()).current;

    bool translationReceived = false;

    LyricsResult? bestResult;
    for (var provider in priority) {
      AppLogger.debug(
        '[LyricsService.fetchLyrics]   ==> Fetching from $provider',
      );
      if (isCancelled?.call() == true) {
        if (bestResult != null) yield bestResult;
        return;
      }

      LyricsResult result = LyricsResult.empty();
      final shouldTrimMetadata = trimMetadataProviders.contains(provider);

      List<String> accumulatedArtworkUrls = [];
      void onArtworkUrl(String url) {
        if (url.isNotEmpty && !accumulatedArtworkUrls.contains(url)) {
          AppLogger.debug(
            '[LyricsService.fetchLyrics]     ==> Received new artwork url: $url',
          );
          accumulatedArtworkUrls.add(url);
        }
      }

      final source = _sourceRegistry.sourceFor(provider);
      if (source == null) {
        AppLogger.debug(
          '[LyricsService.fetchLyrics]     ==> [!] Unsupported provider: $provider',
        );
        continue;
      }

      LyricsResult onTranslationWrapper(LyricsResult result) {
        final taggedResult = result.copyWith(sourceProvider: provider);
        if (translationEnabled &&
            taggedResult.translation &&
            taggedResult.rawTranslation!.isNotEmpty) {
          translationReceived = true;
          onTranslation?.call(taggedResult);
        }
        return taggedResult;
      }

      result = await source.fetchLyrics(
        LyricsFetchRequest(
          title: title,
          artist: artist,
          album: album,
          durationSeconds: durationSeconds,
          shouldTrimMetadata: shouldTrimMetadata,
          onStatusUpdate: onStatusUpdate,
          onArtworkUrl: onArtworkUrl,
          translationBias: translationBias,
          onTranslation: onTranslationWrapper,
        ),
      );

      result = result.copyWith(
        sourceProvider: provider == LyricProviderType.cache
            ? result.sourceProvider ??
                  lyricProviderTypeFromSource(result.source)
            : provider,
      );

      if (accumulatedArtworkUrls.isNotEmpty) {
        result = result.copyWith(artworkUrls: accumulatedArtworkUrls);
      }

      if (result.lyrics.isNotEmpty || result.isPureMusic) {
        // Report every provider result as a candidate (not just the best).
        onCandidate?.call(result);

        final nextBest = selectBetterCandidate(
          result,
          bestResult,
          richSyncEnabled,
        );

        if (nextBest != null && nextBest != bestResult) {
          bestResult = nextBest;

          AppLogger.debug(
            '[LyricsService.fetchLyrics]     ==> Yielding new best result',
          );
          yield nextBest;

          // Cached? break
          if (provider == LyricProviderType.cache) {
            AppLogger.debug(
              '[LyricsService.fetchLyrics]     ==> This LyricsResult is cached, breaking loop',
            );
            break;
          }
          // Cache the raw result from other providers
          if (cacheEnabled &&
              provider != LyricProviderType.cache &&
              (nextBest.lyrics.isNotEmpty || nextBest.isPureMusic)) {
            await _cacheService
                .cacheLyrics(title, artist, album, durationSeconds, nextBest)
                .then((_) {
                  AppLogger.debug(
                    '[LyricsService.fetchLyrics]     ==> newBetter lyrics cached',
                  );
                });
          }
        }
      }

      // Early-exit when we already have a high-quality result.
      // If onPauseForCandidates is provided, pause here (once) so the user can
      // open the candidates panel; resolving true continues remaining providers.
      final bool isGoodEnough = hasGoodEnoughLyricsResult(
        bestResult,
        richSyncEnabled,
        translationEnabled,
        translationReceived,
      );

      if (isGoodEnough) {
        if (onPauseForCandidates != null) {
          AppLogger.debug(
            '[LyricsService.fetchLyrics]     ==> Good result found; pausing for candidate selection',
          );
          onFetchStatusUpdate?.call(false);
          final shouldContinue = await onPauseForCandidates();
          // Only pause once; clear callback effect by treating this as done.
          onPauseForCandidates = null;
          onFetchStatusUpdate?.call(true);
          if (!shouldContinue) {
            break;
          }
          AppLogger.debug(
            '[LyricsService.fetchLyrics]     ==> Resuming fetch for remaining providers',
          );
        } else {
          break;
        }
      }
    }
    onFetchStatusUpdate?.call(false);
  }

  Stream<LyricsResult> fetchTranslation({
    required LyricsResult bestResult,
    required String title,
    required List<String> artist,
    required String album,
    required int durationSeconds,
    bool Function()? isCancelled,
    Map<LyricProviderType, Set<String>>? refetchTargets,
    bool skipCacheLookup = false,

    /// Called for every provider that returns a valid translation (not just the
    /// first winner). Used to populate the translation candidate list.
    void Function(LyricsResult)? onTranslationCandidate,
  }) async* {
    AppLogger.debug(
      '[LyricsService.fetchTranslation] Fetching translation for $title - ${artist.join(', ')}',
    );
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;

    final configuredTargetLanguages =
        (await _settingsService.getTranslationTargetLanguages()).current;
    final targetLanguages = refetchTargets == null
        ? configuredTargetLanguages
        : refetchTargets.values.expand((languages) => languages).toSet();
    final ignoredLanguages =
        (await _settingsService.getTranslationIgnoredLanguages()).current;
    final translationBias =
        (await _settingsService.getTranslationBias()).current;
    final translationAlignmentThreshold =
        (await _settingsService.getTranslationAlignmentThreshold()).current;
    final translationCoverageThreshold =
        (await _settingsService.getTranslationCoverageThreshold()).current;
    final priority = await _settingsService.getPriority();

    if (targetLanguages.isEmpty ||
        bestResult.lyrics.isEmpty ||
        (bestResult.language != null &&
            ignoredLanguages.contains(bestResult.language))) {
      return;
    }
    // Prepare request with LRC formatted content to preserve timestamps for LLM
    final requestData = GeneralTranslationRequestData(
      title: title,
      artist: artist,
      album: album,
      durationSeconds: durationSeconds,
      content: bestResult.lyrics
          .map((l) {
            final m = l.startTime.inMinutes
                .remainder(60)
                .toString()
                .padLeft(2, '0');
            final s = l.startTime.inSeconds
                .remainder(60)
                .toString()
                .padLeft(2, '0');
            final ms = (l.startTime.inMilliseconds % 1000 ~/ 10)
                .toString()
                .padLeft(2, '0');
            return '[$m:$s.$ms]${l.text}';
          })
          .join('\n'),
    );
    final originalSourceProvider = bestResult.sourceProvider;

    // start searching
    bool isYielded = false;

    if (cacheEnabled && !skipCacheLookup && refetchTargets == null) {
      final skipCacheId = _cacheService.generateTranslationCacheId(
        title,
        artist,
        LyricsCacheService.manualTranslationSkipLanguage,
      );
      final skippedTranslation = await _cacheService.getCachedTranslation(
        skipCacheId,
      );
      if (_isSkippedTranslation(skippedTranslation)) {
        yield skippedTranslation!;
        return;
      }
    }

    final translationProviders = refetchTargets == null
        ? priority
        : refetchTargets.keys;

    // Provider priority is the outer loop. Cache is inserted first by
    // SettingsService and acts as a short-circuit: one valid cached result
    // ends this request, while a complete cache miss falls through to the
    // next provider.
    for (var tProvider in translationProviders) {
      if (isCancelled?.call() == true) return;

      AppLogger.debug(
        '[LyricsService.fetchTranslation]   ==> Processing provider ${tProvider.metadata['name']}',
      );

      if (tProvider == LyricProviderType.cache) {
        if (!cacheEnabled || skipCacheLookup || refetchTargets != null) {
          continue;
        }

        for (var targetLanguage in targetLanguages) {
          if (bestResult.language == targetLanguage) {
            AppLogger.debug(
              '[LyricsService.fetchTranslation]     ==> Target language matches source language, skipping $targetLanguage',
            );
            continue;
          }

          if (isCancelled?.call() == true) return;

          AppLogger.debug(
            '[LyricsService.fetchTranslation]     ==> Checking cache for $targetLanguage',
          );
          final cacheId = _cacheService.generateTranslationCacheId(
            title,
            artist,
            targetLanguage,
          );
          var transResult = await _cacheService.getCachedTranslation(cacheId);
          if (transResult == null) continue;

          if (_isSkippedTranslation(transResult)) {
            AppLogger.debug(
              '[LyricsService.fetchTranslation]       ==> Found cached skipped $targetLanguage',
            );
          } else if (!_matchesCurrentLyrics(
            transResult,
            originalSourceProvider,
            bestResult.lyrics,
            translationCoverageThreshold,
            translationAlignmentThreshold,
          )) {
            AppLogger.debug(
              '[LyricsService.fetchTranslation]       ==> Cached $targetLanguage does not match current lyrics, treating as miss',
            );
            continue;
          } else {
            AppLogger.debug(
              '[LyricsService.fetchTranslation]       ==> Found cached $targetLanguage',
            );
          }

          transResult = transResult.copyWith(
            translationProvider: '${transResult.translationProvider} (cached)',
          );
          if (_isCandidate(transResult)) {
            onTranslationCandidate?.call(transResult);
          }
          if (_shouldYield(transResult)) {
            isYielded = true;
            yield transResult;
            return;
          }
        }

        AppLogger.debug(
          '[LyricsService.fetchTranslation]     ==> [!] Cache missed all target languages',
        );
        continue;
      }

      final providerTargetLanguages = refetchTargets == null
          ? targetLanguages
          : (refetchTargets[tProvider] ?? const <String>{});

      for (var targetLanguage in providerTargetLanguages) {
        if (bestResult.language == targetLanguage) {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]       ==> Target language matches source language, skipping $targetLanguage',
          );
          continue;
        }

        if (isCancelled?.call() == true) return;

        final source = _sourceRegistry.sourceFor(tProvider);
        if (source == null || !source.checkTranslationSupport(targetLanguage)) {
          // silence it
          // AppLogger.debug(
          //   '[LyricsService.fetchTranslation]     ==> [!] Provider doesn\'t support translation for $targetLanguage',
          // );
          continue;
        }

        AppLogger.debug(
          '[LyricsService.fetchTranslation]     ==> Fetching translation for $targetLanguage',
        );
        var transResult = await source.fetchTranslation(
          LyricsTranslationRequest(
            data: requestData,
            targetLanguage: targetLanguage,
            translationBias: translationBias,
          ),
        );
        transResult = transResult.copyWith(
          sourceProvider: originalSourceProvider,
        );

        final bool usableResult =
            transResult.translation || transResult.source == 'SKIPPED';
        if (!usableResult) {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]       ==> [!] Failed',
          );
          continue;
        }

        AppLogger.debug(
          '[LyricsService.fetchTranslation]       ==> New translation received',
        );

        if (cacheEnabled) {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]         ==> Caching translation',
          );
          final cacheId = _cacheService.generateTranslationCacheId(
            title,
            artist,
            targetLanguage,
          );
          await _cacheService.cacheTranslation(cacheId, transResult);
        }

        if (_isCandidate(transResult)) {
          onTranslationCandidate?.call(transResult);
        }

        // Keep querying after the first yield so the candidate sheet can show
        // alternatives from lower-priority providers.
        if (_shouldYield(transResult) && !isYielded) {
          isYielded = true;
          yield transResult;
        }
      }
    }
  }

  bool _shouldYield(LyricsResult? transResult) {
    if (transResult != null && transResult.translation) {
      return true;
    } else if (transResult != null && transResult.source == 'SKIPPED') {
      AppLogger.debug(
        '[LyricsService.fetchTranslation]       ==> Translation skipped by provider',
      );
      return true;
    } else {
      return false;
    }
  }

  bool _isSkippedTranslation(LyricsResult? transResult) {
    return transResult != null &&
        !transResult.translation &&
        transResult.source == 'SKIPPED';
  }

  bool _isCandidate(LyricsResult? transResult) {
    if (transResult != null && transResult.translation) {
      return true;
    } else {
      return false;
    }
  }

  bool _matchesCurrentLyrics(
    LyricsResult translation,
    LyricProviderType? originalSourceProvider,
    List<Lyric> currentLyrics,
    int coverageThreshold,
    int perLineSimilarityThreshold,
  ) {
    if (!translation.translationInvalidatable) {
      return true;
    }

    final translationSourceProvider = translation.sourceProvider;
    if (originalSourceProvider != null &&
        translationSourceProvider != null &&
        translationSourceProvider == originalSourceProvider) {
      return true;
    }
    // Fallback: keep the translation when its original lines align well with
    // the current lyrics, even if source providers differ or are missing.
    return TranslationHelper.hasSufficientCoverage(
      currentLyrics: currentLyrics,
      rawTranslation: translation.rawTranslation,
      coverageThreshold: coverageThreshold,
      perLineSimilarityThreshold: perLineSimilarityThreshold,
    );
  }
}
