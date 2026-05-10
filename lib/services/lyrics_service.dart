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

    // create a on translation wrapper that change translationReceived if called
    bool translationReceived = false;
    LyricsResult onTranslationWrapper(LyricsResult result) {
      if (translationEnabled &&
          result.translation &&
          result.rawTranslation!.isNotEmpty) {
        translationReceived = true;
        onTranslation?.call(result);
      }
      return result;
    }

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

    /// Called for every provider that returns a valid translation (not just the
    /// first winner). Used to populate the translation candidate list.
    void Function(LyricsResult)? onTranslationCandidate,
  }) async* {
    AppLogger.debug(
      '[LyricsService.fetchTranslation] Fetching translation for $title - ${artist.join(', ')}',
    );
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;

    final targetLanguages =
        (await _settingsService.getTranslationTargetLanguages()).current;
    final ignoredLanguages =
        (await _settingsService.getTranslationIgnoredLanguages()).current;
    final translationBias =
        (await _settingsService.getTranslationBias()).current;
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

    // check if source == target
    if (bestResult.language != null &&
        targetLanguages.contains(bestResult.language)) {
      AppLogger.debug(
        '[LyricsService.fetchTranslation]   ==> Target language contains source language, skipping translation',
      );
      return;
    }

    // start searching
    bool isYielded = false;

    // check online
    // Iterate translation providers
    LyricsResult? transResult;
    for (var targetLanguage in targetLanguages) {
      if (cacheEnabled) {
        AppLogger.debug(
          '[LyricsService.fetchTranslation]   ==> Checking cache for $targetLanguage',
        );
        final cacheId = _cacheService.generateTranslationCacheId(
          title,
          artist,
          targetLanguage,
        );
        transResult = await _cacheService.getCachedTranslation(cacheId);
        if (transResult != null) {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]     ==> Found cached $targetLanguage',
          );
          transResult = transResult.copyWith(
            translationProvider: '${transResult.translationProvider} (cached)',
          );
          if (_isCandidate(transResult)) {
            onTranslationCandidate?.call(transResult);
          }
          if (_shouldYield(transResult) && !isYielded) {
            isYielded = true;
            yield transResult;
          }
          continue;
        }
      }

      AppLogger.debug(
        '[LyricsService.fetchTranslation]   ==> Checking providers for $targetLanguage',
      );
      for (var tProvider in priority) {
        // break if cancelled
        if (isCancelled?.call() == true) return;
        // cache is checked before, ignore
        if (tProvider == LyricProviderType.cache) continue;

        // reset transResult
        transResult = null;

        final source = _sourceRegistry.sourceFor(tProvider);

        // supported?
        if (source == null || !source.checkTranslationSupport(targetLanguage)) {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]     ==> [!] Unsupported provider: $tProvider',
          );
          continue;
        }
        // try fetch
        AppLogger.debug(
          '[LyricsService.fetchTranslation]     ==> Fetching from ${tProvider.metadata['name']}',
        );
        transResult = await source.fetchTranslation(
          LyricsTranslationRequest(
            data: requestData,
            targetLanguage: targetLanguage,
            translationBias: translationBias,
          ),
        );
        // check if successed (malformed? null?)
        final bool usableResult =
            transResult.translation || transResult.source == 'SKIPPED';

        if (usableResult) {
          // New usable translation found
          AppLogger.debug(
            '[LyricsService.fetchTranslation]       ==> New translation received',
          );

          // cache it if enabled
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

          // Report as a candidate regardless of cache/first status.
          if (_isCandidate(transResult)) {
            onTranslationCandidate?.call(transResult);
          }

          // Continue to next provider to collect more candidates; only yield
          // the first successful result for the actual display (auto-pick).
          if (_shouldYield(transResult) && !isYielded) {
            isYielded = true;
            yield transResult;
          }
        } else {
          AppLogger.debug(
            '[LyricsService.fetchTranslation]       ==> [!] Failed',
          );
          continue;
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

  bool _isCandidate(LyricsResult? transResult) {
    if (transResult != null && transResult.translation) {
      return true;
    } else {
      return false;
    }
  }
}
