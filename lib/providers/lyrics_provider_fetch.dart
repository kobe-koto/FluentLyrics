part of 'lyrics_provider.dart';

extension LyricsProviderFetch on LyricsProvider {
  Future<void> _fetchTranslationsForCurrentTrack(
    MediaMetadata metadata, {
    bool showLoadingState = false,
    bool clearCachedTranslations = false,
    bool clearTranslationState = true,
    bool skipCacheLookup = false,
    Map<LyricProviderType, Set<String>>? refetchTargets,
  }) async {
    if (!_settings.translationEnabled.current || _lyricsResult.lyrics.isEmpty) {
      return;
    }

    if (clearCachedTranslations) {
      await _clearTranslationCacheForCurrentTrack(_currentMetadata!);
    }

    final requestVersion = _beginTranslationRequest();
    if (clearTranslationState) {
      _clearTranslationState();
    }

    if (showLoadingState) {
      _beginTranslationRefreshState();
    }

    try {
      final transStream = _lyricsService.fetchTranslation(
        bestResult: _lyricsResult,
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        refetchTargets: refetchTargets,
        skipCacheLookup: skipCacheLookup,
        scope: _translationScope,
        isCancelled: () =>
            !_canAcceptTranslationResult(metadata, requestVersion),
        onTranslationCandidate: (trans) {
          if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
          if (_appendTranslationCandidateIfNeeded(trans)) {
            _notify();
          }
        },
      );

      await for (var transResult in transStream) {
        if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
        _translationResult = transResult;
        _display.invalidateAlignment();
        _updateCurrentIndex();
        _notify();
      }
    } catch (e) {
      if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
      if (_setLoadingStatus('Error: $e')) {
        _notify();
      }
    } finally {
      if (showLoadingState) {
        _finishTranslationRefreshState(metadata, requestVersion);
      }
    }
  }

  Future<void> _fetchLyrics(
    MediaMetadata metadata, {
    bool skipFetchTranslations = false,
  }) async {
    final requestVersion = _beginLyricsRequest();
    _beginLyricsFetchState();

    try {
      final stream = _lyricsService.fetchLyrics(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        onStatusUpdate: (status) {
          if (!_canAcceptLyricsResult(metadata, requestVersion)) return;
          if (_setLoadingStatus(status)) {
            _notify();
          }
        },
        onFetchStatusUpdate: (status) {
          if (!_canAcceptLyricsResult(metadata, requestVersion)) return;
          if (_setFetchingState(status)) {
            _notify();
          }
        },
        scope: _lyricsScope,
        isCancelled: () => !_canAcceptLyricsResult(metadata, requestVersion),
        trimMetadataProviders: _settings.trimMetadataProviders.current,
        richSyncEnabled: _settings.richSyncEnabled.current,
        onTranslation: (trans) {
          if (!_canAcceptLyricsResult(metadata, requestVersion) ||
              !_settings.translationEnabled.current ||
              trans.rawTranslation!.isEmpty ||
              trans.language == null) {
            return;
          }

          if (!_matchesTranslationTargetLanguage(trans.language!)) return;
          _appendTranslationCandidateIfNeeded(trans);

          if (!_translationMatchesCurrentLyricsProvider(_translationResult)) {
            _translationResult = trans;
            _notify();
            if (_settings.cacheEnabled.current &&
                (trans.translation || trans.source == 'SKIPPED')) {
              final cacheId = _cacheService.generateTranslationCacheId(
                metadata.title,
                metadata.artist,
                trans.language!,
              );
              _cacheService.cacheTranslation(cacheId, trans).then((_) {
                AppLogger.debug(
                  'Cached translation from ${trans.source} for ${metadata.title} - ${metadata.artist.join(', ')}',
                );
              });
            }
          }
        },
        onCandidate: (candidate) {
          if (!_canAcceptLyricsResult(metadata, requestVersion)) return;
          if (_appendCandidateIfNeeded(candidate)) {
            _notify();
          }
        },
        onPauseForCandidates: () async {
          if (!_canAcceptLyricsResult(metadata, requestVersion)) return false;
          if (_isCandidateSheetOpen) {
            return true;
          }
          // If the sheet was opened before we reached this point, skip waiting.
          if (_candidateSheetOpenedEarly) {
            _candidateSheetOpenedEarly = false;
            return true;
          }
          _candidatePauseCompleter = Completer<bool>();
          _isPausedForCandidates = true;
          _notify();
          return _candidatePauseCompleter!.future;
        },
      );

      await for (var result in stream) {
        if (!_canAcceptLyricsResult(metadata, requestVersion)) return;

        result = _prepareLyricsResultForDisplay(result);

        _lyricsResult = result;
        _applyReadingFromResult(result);
        if (!_translationMatchesCurrentLyricsProvider(_translationResult)) {
          _clearTranslationState();
        }
        if (result.artworkUrls != null && result.artworkUrls!.isNotEmpty) {
          final newUrls = result.artworkUrls!
              .where((url) => !artworkUrlsNotifier.value.contains(url))
              .toList();
          if (newUrls.isNotEmpty) {
            artworkUrlsNotifier.value = List.from(artworkUrlsNotifier.value)
              ..addAll(newUrls);
          }
        }

        if (result.lyrics.isNotEmpty || result.isPureMusic) {
          _setLoadingState(false);
        }

        _updateCurrentIndex();
        _notify();
      }

      if (!_canAcceptLyricsResult(metadata, requestVersion)) return;

      if (_settings.translationEnabled.current &&
          !skipFetchTranslations &&
          _lyricsResult.lyrics.isNotEmpty &&
          !_translationMatchesCurrentLyricsProvider(_translationResult)) {
        await _fetchTranslationsForCurrentTrack(metadata);
      }
    } catch (e) {
      if (!_canAcceptLyricsResult(metadata, requestVersion)) return;
      _setLoadingStatus('Error: $e');
    } finally {
      _finishLyricsFetchState(metadata, requestVersion);
    }
  }
}
