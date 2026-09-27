import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import 'lyrics_provider_settings.dart';
import '../services/media_service.dart';
import '../services/lyrics_request_scope.dart';
import '../services/lyrics_service.dart';
import '../services/settings_service.dart';
import '../services/secret_store.dart';
import '../services/providers/lyrics_cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/lyrics_candidate_helper.dart';
import '../utils/lyrics_reading_candidate_helper.dart';
import '../utils/lyrics_display_helper.dart';
import 'lyrics_display_pipeline.dart';

import '../services/opencc/zh_conversion_service.dart';
import '../utils/richify_helper.dart';
import '../utils/translation_helper.dart';

part 'lyrics_provider_fetch.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService mediaService;
  final LyricsService _lyricsService;
  final SettingsService _settingsService;
  final LyricsCacheService _cacheService;

  MediaMetadata? _currentMetadata;
  Timer? _permissionTimer;
  LyricsResult _lyricsResult = LyricsResult.empty();
  LyricsResult? _translationResult;
  LyricsReading? _readingResult;
  List<LyricsReading> _readingCandidates = [];
  Duration _currentPosition = Duration.zero;
  final ValueNotifier<Duration> currentPositionNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> positionResyncNotifier = ValueNotifier(
    Duration.zero,
  );
  static const Duration _positionResyncThreshold = Duration(milliseconds: 400);

  LyricsProviderSettings _settings = LyricsProviderSettings.defaults();

  Duration _trackOffset = Duration.zero;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isFetching = false;
  bool _androidPermissionGranted = !Platform.isAndroid;
  String _loadingStatus = '';

  // Candidates
  List<LyricsResult> _candidates = [];
  bool _isPausedForCandidates = false;
  Completer<bool>? _candidatePauseCompleter;
  int _lyricsRequestVersion = 0;
  LyricsRequestScope? _lyricsScope;

  /// Set to true when the sheet is opened before the stream reaches the pause
  /// point, so the pause skips waiting and continues immediately.
  bool _candidateSheetOpenedEarly = false;
  bool _isCandidateSheetOpen = false;

  // Translation candidates
  List<LyricsResult> _translationCandidates = [];
  int _translationRequestVersion = 0;
  LyricsRequestScope? _translationScope;

  MediaControlAbility _controlAbility = MediaControlAbility.none();
  DateTime? _playbackToggleLockedUntil;

  LyricsProvider({
    MediaService? mediaService,
    LyricsService? lyricsService,
    SettingsService? settingsService,
    LyricsCacheService? cacheService,
  }) : mediaService = mediaService ?? MediaService.create(),
       _lyricsService = lyricsService ?? LyricsService(),
       _settingsService = settingsService ?? SettingsService(),
       _cacheService = cacheService ?? LyricsCacheService() {
    LyricsCacheService.addListener(_onCacheDatabaseChanged);
    _loadSettings();
    this.mediaService.addListener(_onMediaChanged);
    this.mediaService.startPolling();
    if (Platform.isAndroid) {
      _startPermissionPolling();
    }
  }

  void _startPermissionPolling() {
    _permissionTimer?.cancel();
    _permissionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkAndroidPermission();
    });
    checkAndroidPermission();
  }

  MediaMetadata? get currentMetadata => _currentMetadata;

  final LyricsDisplayPipeline _display = LyricsDisplayPipeline();

  /// The lyrics as rendered: rich-sync stripping, translation alignment,
  /// Simplified/Traditional conversion, and kanji annotation.
  List<Lyric> get lyrics => _display.build(
    lyricsResult: _lyricsResult,
    translationResult: _translationResult,
    reading: _readingResult,
    richSyncEnabled: _settings.richSyncEnabled.current,
    translationEnabled: _settings.translationEnabled.current,
    annotationEnabled: _settings.annotationEnabled.current,
    annotationBias: _settings.annotationBias.current,
    zhConversionTarget: _settings.zhConversionTarget.current,
    zhConversionIgnoredLanguages:
        _settings.zhConversionIgnoredLanguages.current,
    translationAlignmentThreshold:
        _settings.translationAlignmentThreshold.current,
  );

  LyricsResult get lyricsResult {
    if (!_settings.richSyncEnabled.current && _lyricsResult.isRichSync) {
      return _lyricsResult.copyWith(
        isRichSync: false,
        lyrics: lyrics, // Uses the getter above which strips inline parts
      );
    }
    return _lyricsResult;
  }

  LyricsResult? get translationResult =>
      _settings.translationEnabled.current ? _translationResult : null;

  Duration get currentPosition => _currentPosition;
  Duration get globalOffset =>
      Duration(milliseconds: _settings.globalOffsetMs.current);
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;

  // Setting getters
  Setting<bool> get cacheEnabled => _settings.cacheEnabled;
  Setting<int> get linesBefore => _settings.linesBefore;
  Setting<int> get landscapeLeadingSpace => _settings.landscapeLeadingSpace;
  Setting<int> get richSyncThresholdMs => _settings.richSyncThresholdMs;
  Setting<bool> get annotationEnabled => _settings.annotationEnabled;
  Setting<int> get annotationBias => _settings.annotationBias;
  Setting<String> get zhConversionTarget => _settings.zhConversionTarget;
  Setting<List<String>> get zhConversionIgnoredLanguages =>
      _settings.zhConversionIgnoredLanguages;
  Setting<int> get scrollAutoResumeDelay => _settings.scrollAutoResumeDelay;
  Setting<bool> get blurEnabled => _settings.blurEnabled;
  Setting<bool> get richSyncEnabled => _settings.richSyncEnabled;
  Setting<List<LyricProviderType>> get trimMetadataProviders =>
      _settings.trimMetadataProviders;
  Setting<double> get fontSize => _settings.fontSize;
  Setting<double> get inactiveScale => _settings.inactiveScale;
  Setting<int> get globalOffsetSetting => _settings.globalOffsetMs;

  Setting<bool> get translationEnabled => _settings.translationEnabled;
  Setting<bool> get translationHighlightOnly =>
      _settings.translationHighlightOnly;
  Setting<List<String>> get translationTargetLanguages =>
      _settings.translationTargetLanguages;
  Setting<List<String>> get translationIgnoredLanguages =>
      _settings.translationIgnoredLanguages;
  Setting<int> get translationBias => _settings.translationBias;
  Setting<int> get translationAlignmentThreshold =>
      _settings.translationAlignmentThreshold;
  Setting<int> get translationCoverageThreshold =>
      _settings.translationCoverageThreshold;
  Setting<String> get llmApiEndpoint => _settings.llmApiEndpoint;
  Setting<String> get llmApiKey => _settings.llmApiKey;
  SecretStoreFailure? _secretStoreFailure;
  SecretStoreFailure? get secretStoreFailure => _secretStoreFailure;
  Setting<String> get llmModel => _settings.llmModel;
  Setting<String> get llmReasoningEffort => _settings.llmReasoningEffort;
  Setting<int> get llmTimeToFirstTokenSeconds =>
      _settings.llmTimeToFirstTokenSeconds;
  Setting<double> get llmMinTokensPerSecond => _settings.llmMinTokensPerSecond;
  Setting<bool> get keepScreenOn => _settings.keepScreenOn;
  Setting<bool> get backgroundMotionEnabled =>
      _settings.backgroundMotionEnabled;
  Setting<bool> get experimentalRichInlineFontSizeGlitching =>
      _settings.experimentalRichInlineFontSizeGlitching;
  Setting<bool> get experimentalAnnotationFontSizeGlitching =>
      _settings.experimentalAnnotationFontSizeGlitching;
  Setting<bool> get trayEnabled => _settings.trayEnabled;
  Setting<bool> get hideToTrayOnClose => _settings.hideToTrayOnClose;
  Setting<String> get lyricsStreamPath => _settings.lyricsStreamPath;
  Setting<String> get translationStreamPath => _settings.translationStreamPath;
  Setting<int> get artworkMinSize => _settings.artworkMinSize;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  bool get androidPermissionGranted => _androidPermissionGranted;
  String get loadingStatus => _loadingStatus;
  MediaControlAbility get controlAbility => _controlAbility;
  final ValueNotifier<List<String>> artworkUrlsNotifier = ValueNotifier([]);

  // Candidates getters
  List<LyricsResult> get candidates => _candidates;
  bool get isPausedForCandidates => _isPausedForCandidates;
  List<LyricsResult> get translationCandidates => _translationCandidates;

  /// Reading track (kana/romaji) of the current lyrics, when the provider
  /// shipped one. Used to annotate kanji.
  LyricsReading? get readingResult => _readingResult;
  String? get fetchFailureMessage {
    if (_lyricsResult.isPureMusic || _lyricsResult.lyrics.isNotEmpty) {
      return null;
    }
    if (_lyricsResult.isFailure) return _lyricsResult.failureMessage;
    for (final candidate in _candidates.reversed) {
      if (candidate.isFailure) return candidate.failureMessage;
    }
    return null;
  }

  List<LyricsReading> get readingCandidates => _readingCandidates;

  final Duration _interludeOffset = Duration(
    milliseconds: 500, // auto scroll takes 500ms
  );

  String? get currentCacheId {
    if (_currentMetadata == null) return null;
    return _cacheService.generateCacheId(
      _currentMetadata!.title,
      _currentMetadata!.artist,
      _currentMetadata!.album,
      _currentMetadata!.duration.inSeconds,
      isRichSync: _lyricsResult.isRichSync,
    );
  }

  bool get isInterlude {
    return LyricsDisplayHelper.isInterlude(lyrics, _currentIndex);
  }

  double get interludeProgress {
    if (!isInterlude || lyrics.isEmpty) return 0.0;
    return interludeProgressForPosition(_currentPosition);
  }

  void _clearReadingState() {
    _readingResult = null;
    _readingCandidates = [];
  }

  void _clearTranslationState({bool clearCandidates = true}) {
    _translationResult = null;
    _display.invalidateAlignment();
    if (clearCandidates) {
      _translationCandidates = [];
    }
  }

  void _invalidateTranslationRequests({bool clearCandidates = true}) {
    _translationRequestVersion++;
    _translationScope?.cancel();
    _translationScope = null;
    _clearTranslationState(clearCandidates: clearCandidates);
  }

  int _beginTranslationRequest() {
    _translationRequestVersion++;
    _translationScope?.cancel();
    _translationScope = LyricsRequestScope();
    return _translationRequestVersion;
  }

  int _beginLyricsRequest() {
    _lyricsRequestVersion++;
    _lyricsScope?.cancel();
    _lyricsScope = LyricsRequestScope();
    return _lyricsRequestVersion;
  }

  void _invalidateLyricsRequests() {
    _lyricsRequestVersion++;
    _lyricsScope?.cancel();
    _lyricsScope = null;
  }

  bool _canAcceptLyricsResult(MediaMetadata metadata, int requestVersion) {
    return requestVersion == _lyricsRequestVersion &&
        metadata.isSameTrack(_currentMetadata);
  }

  bool _canAcceptTranslationResult(MediaMetadata metadata, int requestVersion) {
    return _settings.translationEnabled.current &&
        requestVersion == _translationRequestVersion &&
        metadata.isSameTrack(_currentMetadata);
  }

  double interludeProgressForPosition(Duration position) {
    return LyricsDisplayHelper.interludeProgressForPosition(
      lyrics: lyrics,
      currentIndex: _currentIndex,
      position: position,
      globalOffset: globalOffset,
      trackOffset: _trackOffset,
      interludeOffset: _interludeOffset,
    );
  }

  Duration get interludeDuration {
    return LyricsDisplayHelper.interludeDuration(
      lyrics: lyrics,
      currentIndex: _currentIndex,
      interludeOffset: _interludeOffset,
    );
  }

  bool _setLoadingStatus(String status) {
    if (_loadingStatus == status) return false;
    _loadingStatus = status;
    return true;
  }

  bool _setFetchingState(bool isFetching) {
    if (_isFetching == isFetching) return false;
    _isFetching = isFetching;
    return true;
  }

  bool _setLoadingState(bool isLoading) {
    if (_isLoading == isLoading) return false;
    _isLoading = isLoading;
    return true;
  }

  bool _matchesTranslationTargetLanguage(String language) {
    return matchesTranslationTargetLanguage(
      _settings.translationTargetLanguages.current,
      language,
    );
  }

  bool _appendTranslationCandidateIfNeeded(LyricsResult candidate) {
    final nextCandidates = appendTranslationCandidateIfNeeded(
      _translationCandidates,
      candidate,
    );
    if (identical(nextCandidates, _translationCandidates)) return false;
    _translationCandidates = nextCandidates;
    return true;
  }

  bool _translationMatchesCurrentLyricsProvider(LyricsResult? translation) {
    if (translation == null) return false;
    if (!translation.translationInvalidatable) return true;

    final currentSourceProvider = _lyricsResult.sourceProvider;
    final translationSourceProvider = translation.sourceProvider;
    if (currentSourceProvider != null &&
        translationSourceProvider != null &&
        translationSourceProvider == currentSourceProvider) {
      return true;
    }
    // Fallback: even if the source providers differ (or are missing), the
    // translation may still be aligned with the current lyrics. Treat it as
    // valid when its original lines cover enough of the current lyrics.
    return TranslationHelper.hasSufficientCoverage(
      currentLyrics: _lyricsResult.lyrics,
      rawTranslation: translation.rawTranslation,
      coverageThreshold: _settings.translationCoverageThreshold.current,
      perLineSimilarityThreshold:
          _settings.translationAlignmentThreshold.current,
    );
  }

  bool _translationInvalidatedByLyrics(
    LyricsResult translation,
    LyricsResult lyricsResult,
  ) {
    if (!translation.translationInvalidatable) return false;

    final currentSourceProvider = lyricsResult.sourceProvider;
    final translationSourceProvider = translation.sourceProvider;
    if (currentSourceProvider != null &&
        translationSourceProvider != null &&
        translationSourceProvider == currentSourceProvider) {
      return false;
    }

    return !TranslationHelper.hasSufficientCoverage(
      currentLyrics: lyricsResult.lyrics,
      rawTranslation: translation.rawTranslation,
      coverageThreshold: _settings.translationCoverageThreshold.current,
      perLineSimilarityThreshold:
          _settings.translationAlignmentThreshold.current,
    );
  }

  LyricProviderType? _translationProviderTypeFor(LyricsResult translation) {
    final provider = translation.translationProvider
        ?.replaceAll(' (cached)', '')
        .toLowerCase();
    if (provider == null) return null;
    if (provider.contains('musixmatch')) return LyricProviderType.musixmatch;
    if (provider.contains('netease')) return LyricProviderType.netease;
    if (provider.contains('qqmusic') || provider.contains('qq music')) {
      return LyricProviderType.qqmusic;
    }
    if (provider.contains('llm')) return LyricProviderType.llm;
    return null;
  }

  Map<LyricProviderType, Set<String>> _invalidatedTranslationTargetsFor(
    LyricsResult lyricsResult,
  ) {
    final targets = <LyricProviderType, Set<String>>{};
    final seen = <LyricsResult>{};
    final translations = <LyricsResult>[
      ..._translationCandidates,
      ?_translationResult,
    ];

    for (final translation in translations) {
      if (!seen.add(translation)) continue;
      final language = translation.language;
      if (language == null) continue;
      if (!_translationInvalidatedByLyrics(translation, lyricsResult)) continue;

      final provider = _translationProviderTypeFor(translation);
      if (provider == null) continue;
      targets.putIfAbsent(provider, () => <String>{}).add(language);
    }
    return targets;
  }

  bool _appendCandidateIfNeeded(LyricsResult candidate) {
    final nextCandidates = appendCandidateIfNeeded(_candidates, candidate);
    if (identical(nextCandidates, _candidates)) return false;
    _candidates = nextCandidates;
    return true;
  }

  LyricsResult _prepareLyricsResultForDisplay(LyricsResult result) {
    return prepareLyricsResultForDisplay(result);
  }

  void _beginLyricsFetchState() {
    _isFetching = true;
    _isLoading = true;
    _loadingStatus = 'Starting search...';
    _lyricsResult = LyricsResult.empty();
    _invalidateTranslationRequests();
    _candidates = [];
    _isPausedForCandidates = false;
    _candidateSheetOpenedEarly = false;
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    artworkUrlsNotifier.value = [];
    notifyListeners();
  }

  void _finishLyricsFetchState(MediaMetadata metadata, int requestVersion) {
    if (!_canAcceptLyricsResult(metadata, requestVersion)) return;
    _isPausedForCandidates = false;
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    _setLoadingState(false);
    notifyListeners();
  }

  void _beginTranslationRefreshState() {
    if (_setFetchingState(true) |
        _setLoadingStatus('Refreshing translations...')) {
      notifyListeners();
    }
  }

  void _finishTranslationRefreshState(
    MediaMetadata metadata,
    int requestVersion,
  ) {
    if (!metadata.isSameTrack(_currentMetadata)) return;
    if (requestVersion != _translationRequestVersion &&
        _settings.translationEnabled.current) {
      return;
    }
    if (_setFetchingState(false)) {
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    _settings = await LyricsProviderSettings.load(_settingsService);
    _secretStoreFailure = _settingsService.secretStoreFailure;

    notifyListeners();

    // Extracting the bundled OpenCC data is not instant; notify again so the
    // lyrics are converted as soon as converters become available.
    unawaited(
      ZhConversionService.instance.ensureInitialized().then((_) {
        if (_disposed) return;
        notifyListeners();
      }),
    );
  }

  bool _setSettingValue<T>({
    required Setting<T> currentSetting,
    required T value,
    required void Function(Setting<T>) assign,
    required Future<void> Function(T) persist,
    bool Function(T current, T next)? equals,
  }) {
    final isEqual = equals ?? (T current, T next) => current == next;
    if (isEqual(currentSetting.current, value)) return false;

    assign(
      Setting(
        current: value,
        defaultValue: currentSetting.defaultValue,
        changed: !isEqual(value, currentSetting.defaultValue),
      ),
    );
    unawaited(persist(value));
    notifyListeners();
    return true;
  }

  void setCacheEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.cacheEnabled,
      value: enabled,
      assign: (value) => _settings.cacheEnabled = value,
      persist: _settingsService.setCacheEnabled,
    );
  }

  void setLinesBefore(int lines) {
    _setSettingValue(
      currentSetting: _settings.linesBefore,
      value: lines,
      assign: (value) => _settings.linesBefore = value,
      persist: _settingsService.setLinesBefore,
    );
  }

  void setLandscapeLeadingSpace(int percent) {
    _setSettingValue(
      currentSetting: _settings.landscapeLeadingSpace,
      value: percent,
      assign: (value) => _settings.landscapeLeadingSpace = value,
      persist: _settingsService.setLandscapeLeadingSpace,
    );
  }

  void setRichSyncThresholdMs(int ms) {
    _setSettingValue(
      currentSetting: _settings.richSyncThresholdMs,
      value: ms,
      assign: (value) => _settings.richSyncThresholdMs = value,
      persist: _settingsService.setRichSyncThresholdMs,
    );
  }

  void setAnnotationEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.annotationEnabled,
      value: enabled,
      assign: (value) => _settings.annotationEnabled = value,
      persist: _settingsService.setAnnotationEnabled,
    );
  }

  void setAnnotationBias(int ms) {
    _setSettingValue(
      currentSetting: _settings.annotationBias,
      value: ms,
      assign: (value) => _settings.annotationBias = value,
      persist: _settingsService.setAnnotationBias,
    );
  }

  void setZhConversionTarget(String target) {
    _setSettingValue(
      currentSetting: _settings.zhConversionTarget,
      value: target,
      assign: (value) => _settings.zhConversionTarget = value,
      persist: _settingsService.setZhConversionTarget,
    );
  }

  void setZhConversionIgnoredLanguages(List<String> languages) {
    _setSettingValue(
      currentSetting: _settings.zhConversionIgnoredLanguages,
      value: languages,
      assign: (value) => _settings.zhConversionIgnoredLanguages = value,
      persist: _settingsService.setZhConversionIgnoredLanguages,
      equals: listEquals,
    );
  }

  void setScrollAutoResumeDelay(int seconds) {
    _setSettingValue(
      currentSetting: _settings.scrollAutoResumeDelay,
      value: seconds,
      assign: (value) => _settings.scrollAutoResumeDelay = value,
      persist: _settingsService.setScrollAutoResumeDelay,
    );
  }

  void setBlurEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.blurEnabled,
      value: enabled,
      assign: (value) => _settings.blurEnabled = value,
      persist: _settingsService.setBlurEnabled,
    );
  }

  void setRichSyncEnabled(bool enabled) {
    final changed = _setSettingValue(
      currentSetting: _settings.richSyncEnabled,
      value: enabled,
      assign: (value) => _settings.richSyncEnabled = value,
      persist: _settingsService.setRichSyncEnabled,
    );
    if (!changed) return;

    if (_currentMetadata != null) {
      _fetchLyrics(_currentMetadata!);
    }
  }

  void setTrimMetadataProviders(List<LyricProviderType> providers) {
    _setSettingValue(
      currentSetting: _settings.trimMetadataProviders,
      value: providers,
      assign: (value) => _settings.trimMetadataProviders = value,
      persist: _settingsService.setTrimMetadataProviders,
      equals: listEquals,
    );
  }

  bool shouldTrimMetadata(LyricProviderType provider) {
    return _settings.trimMetadataProviders.current.contains(provider);
  }

  void setFontSize(double size) {
    _setSettingValue(
      currentSetting: _settings.fontSize,
      value: size,
      assign: (value) => _settings.fontSize = value,
      persist: _settingsService.setFontSize,
    );
  }

  void setInactiveScale(double scale) {
    _setSettingValue(
      currentSetting: _settings.inactiveScale,
      value: scale,
      assign: (value) => _settings.inactiveScale = value,
      persist: _settingsService.setInactiveScale,
    );
  }

  void setTranslationTargetLanguages(List<String> languages) {
    final changed = _setSettingValue(
      currentSetting: _settings.translationTargetLanguages,
      value: languages,
      assign: (value) => _settings.translationTargetLanguages = value,
      persist: _settingsService.setTranslationTargetLanguages,
      equals: listEquals,
    );
    if (!changed) return;

    _invalidateTranslationRequests();
    if (_currentMetadata != null && _lyricsResult.lyrics.isNotEmpty) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
    }
  }

  void setTranslationIgnoredLanguages(List<String> languages) {
    final changed = _setSettingValue(
      currentSetting: _settings.translationIgnoredLanguages,
      value: languages,
      assign: (value) => _settings.translationIgnoredLanguages = value,
      persist: _settingsService.setTranslationIgnoredLanguages,
      equals: listEquals,
    );
    if (!changed) return;

    _invalidateTranslationRequests();
    if (_currentMetadata != null && _lyricsResult.lyrics.isNotEmpty) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
    }
  }

  void setTranslationBias(int bias) {
    _setSettingValue(
      currentSetting: _settings.translationBias,
      value: bias,
      assign: (value) => _settings.translationBias = value,
      persist: _settingsService.setTranslationBias,
    );
  }

  void setTranslationAlignmentThreshold(int threshold) {
    final changed = _setSettingValue(
      currentSetting: _settings.translationAlignmentThreshold,
      value: threshold,
      assign: (value) => _settings.translationAlignmentThreshold = value,
      persist: _settingsService.setTranslationAlignmentThreshold,
    );
    if (!changed) return;

    // Changing the threshold requires realigning lyrics
    _display.invalidateAlignment();
    notifyListeners();
  }

  void setTranslationCoverageThreshold(int threshold) {
    _setSettingValue(
      currentSetting: _settings.translationCoverageThreshold,
      value: threshold,
      assign: (value) => _settings.translationCoverageThreshold = value,
      persist: _settingsService.setTranslationCoverageThreshold,
    );
  }

  void setTranslationEnabled(bool enabled) {
    if (_settings.translationEnabled.current == enabled) return;
    final wasEnabled = _settings.translationEnabled.current;
    _settings.translationEnabled = Setting(
      current: enabled,
      defaultValue: _settings.translationEnabled.defaultValue,
      changed: enabled != _settings.translationEnabled.defaultValue,
    );
    _settingsService.setTranslationEnabled(enabled);
    if (!enabled) {
      _invalidateTranslationRequests();
      notifyListeners();
      return;
    }
    notifyListeners();

    if (!wasEnabled &&
        _currentMetadata != null &&
        _lyricsResult.lyrics.isNotEmpty &&
        !_translationMatchesCurrentLyricsProvider(_translationResult)) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
    }
  }

  void setTranslationHighlightOnly(bool highlightOnly) {
    _setSettingValue(
      currentSetting: _settings.translationHighlightOnly,
      value: highlightOnly,
      assign: (value) => _settings.translationHighlightOnly = value,
      persist: _settingsService.setTranslationHighlightOnly,
    );
  }

  void setLlmApiEndpoint(String endpoint) {
    _setSettingValue(
      currentSetting: _settings.llmApiEndpoint,
      value: endpoint,
      assign: (value) => _settings.llmApiEndpoint = value,
      persist: _settingsService.setLlmApiEndpoint,
    );
  }

  Future<void> setLlmApiKey(String apiKey) async {
    final previous = _settings.llmApiKey;
    if (previous.current == apiKey && _secretStoreFailure == null) return;
    _settings.llmApiKey = Setting(
      current: apiKey,
      defaultValue: previous.defaultValue,
      changed: apiKey != previous.defaultValue,
    );
    notifyListeners();
    try {
      await _settingsService.setLlmApiKey(apiKey);
      if (_secretStoreFailure != null) {
        _secretStoreFailure = null;
        notifyListeners();
      }
    } on SecretStoreException catch (error) {
      _settings.llmApiKey = previous;
      _secretStoreFailure = error.failure;
      notifyListeners();
    }
  }

  void setLlmModel(String model) {
    _setSettingValue(
      currentSetting: _settings.llmModel,
      value: model,
      assign: (value) => _settings.llmModel = value,
      persist: _settingsService.setLlmModel,
    );
  }

  void setLlmReasoningEffort(String effort) {
    _setSettingValue(
      currentSetting: _settings.llmReasoningEffort,
      value: effort,
      assign: (value) => _settings.llmReasoningEffort = value,
      persist: _settingsService.setLlmReasoningEffort,
    );
  }

  void setLlmTimeToFirstTokenSeconds(int seconds) {
    _setSettingValue(
      currentSetting: _settings.llmTimeToFirstTokenSeconds,
      value: seconds,
      assign: (value) => _settings.llmTimeToFirstTokenSeconds = value,
      persist: _settingsService.setLlmTimeToFirstTokenSeconds,
    );
  }

  void setLlmMinTokensPerSecond(double tokensPerSecond) {
    _setSettingValue(
      currentSetting: _settings.llmMinTokensPerSecond,
      value: tokensPerSecond,
      assign: (value) => _settings.llmMinTokensPerSecond = value,
      persist: _settingsService.setLlmMinTokensPerSecond,
    );
  }

  void setKeepScreenOn(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.keepScreenOn,
      value: enabled,
      assign: (value) => _settings.keepScreenOn = value,
      persist: _settingsService.setKeepScreenOn,
    );
  }

  void setBackgroundMotionEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.backgroundMotionEnabled,
      value: enabled,
      assign: (value) => _settings.backgroundMotionEnabled = value,
      persist: _settingsService.setBackgroundMotionEnabled,
    );
  }

  void setExperimentalRichInlineFontSizeGlitching(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.experimentalRichInlineFontSizeGlitching,
      value: enabled,
      assign: (value) =>
          _settings.experimentalRichInlineFontSizeGlitching = value,
      persist: _settingsService.setExperimentalRichInlineFontSizeGlitching,
    );
  }

  void setExperimentalAnnotationFontSizeGlitching(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.experimentalAnnotationFontSizeGlitching,
      value: enabled,
      assign: (value) =>
          _settings.experimentalAnnotationFontSizeGlitching = value,
      persist: _settingsService.setExperimentalAnnotationFontSizeGlitching,
    );
  }

  void setTrayEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.trayEnabled,
      value: enabled,
      assign: (value) => _settings.trayEnabled = value,
      persist: _settingsService.setTrayEnabled,
    );
  }

  void setHideToTrayOnClose(bool enabled) {
    _setSettingValue(
      currentSetting: _settings.hideToTrayOnClose,
      value: enabled,
      assign: (value) => _settings.hideToTrayOnClose = value,
      persist: _settingsService.setHideToTrayOnClose,
    );
  }

  void setLyricsStreamPath(String value) {
    _setSettingValue(
      currentSetting: _settings.lyricsStreamPath,
      value: value,
      assign: (v) => _settings.lyricsStreamPath = v,
      persist: _settingsService.setLyricsStreamPath,
    );
  }

  void setTranslationStreamPath(String value) {
    _setSettingValue(
      currentSetting: _settings.translationStreamPath,
      value: value,
      assign: (v) => _settings.translationStreamPath = v,
      persist: _settingsService.setTranslationStreamPath,
    );
  }

  void setArtworkMinSize(int size) {
    _setSettingValue(
      currentSetting: _settings.artworkMinSize,
      value: size,
      assign: (v) => _settings.artworkMinSize = v,
      persist: _settingsService.setArtworkMinSize,
    );
  }

  void setGlobalOffset(Duration offset) {
    final ms = offset.inMilliseconds;
    final changed = _setSettingValue(
      currentSetting: _settings.globalOffsetMs,
      value: ms,
      assign: (value) => _settings.globalOffsetMs = value,
      persist: _settingsService.setGlobalOffset,
    );
    if (!changed) return;

    _updateCurrentIndex();
    notifyListeners();
  }

  void setTrackOffset(Duration offset) {
    _trackOffset = offset;
    _updateCurrentIndex();
    notifyListeners();
  }

  void adjustTrackOffset(Duration delta) {
    _trackOffset += delta;
    _updateCurrentIndex();
    notifyListeners();
  }

  Future<void> playPause() async {
    // Optimistic toggle
    _isPlaying = !_isPlaying;
    _playbackToggleLockedUntil = DateTime.now().add(const Duration(seconds: 1));
    notifyListeners();

    try {
      await mediaService.controller.playPause();
    } catch (e) {
      // Revert on error
      _isPlaying = !_isPlaying;
      _playbackToggleLockedUntil = null;
      notifyListeners();
    }
  }

  Future<void> nextTrack() async {
    await mediaService.controller.nextTrack();
  }

  Future<void> previousTrack() async {
    await mediaService.controller.previousTrack();
  }

  Future<void> seek(Duration position) async {
    // Optimistic update
    _setCurrentPosition(position, forceResync: true);
    _updateCurrentIndex();
    notifyListeners();

    await mediaService.controller.seek(position);
  }

  void _onMediaChanged() {
    if (Platform.isAndroid) {
      checkAndroidPermission();
    }
    _syncWithMediaService();
  }

  Future<void> checkAndroidPermission() async {
    final service = mediaService;
    if (service is AndroidMediaService) {
      final granted = await service.checkPermission();
      if (_androidPermissionGranted != granted) {
        _androidPermissionGranted = granted;
        notifyListeners();
      }
    }
  }

  Future<void> clearCurrentTrackCache() async {
    if (_currentMetadata != null) {
      await _cacheService.clearTrackCache(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        _currentMetadata!.album,
        _currentMetadata!.duration.inSeconds,
      );
      await _clearTranslationCacheForCurrentTrack(_currentMetadata!);
      if (_currentMetadata != null) {
        // Force the fetching logic to re-search for artwork by resetting to 'fallback'.
        final systemMetadata = mediaService.metadata;
        if (systemMetadata?.artUrl == '' ||
            systemMetadata?.artUrl == 'fallback') {
          _currentMetadata = _currentMetadata!.copyWith(artUrl: 'fallback');
        }
        await _fetchLyrics(_currentMetadata!);
      }
    }
  }

  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
    if (_currentMetadata != null) {
      await _fetchLyrics(_currentMetadata!);
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  void _syncWithMediaService() {
    final metadata = mediaService.metadata;
    final isPlaying = mediaService.status.isPlaying;
    final position = mediaService.status.position;
    final controlAbility = mediaService.controlAbility;

    bool metadataChanged = false;

    MediaMetadata? processedMetadata = metadata;
    if (metadata != null &&
        metadata.artUrl == 'fallback' &&
        _currentMetadata != null &&
        _currentMetadata!.artUrl != 'fallback' &&
        _currentMetadata!.isSameTrack(metadata)) {
      processedMetadata = metadata.copyWith(artUrl: _currentMetadata!.artUrl);
    }

    final trackChanged = processedMetadata == null
        ? _currentMetadata != null
        : !processedMetadata.isSameTrack(_currentMetadata);
    final durationBecameValid =
        processedMetadata != null &&
        _currentMetadata != null &&
        _currentMetadata!.duration.inSeconds == 0 &&
        processedMetadata.duration.inSeconds > 0;

    if (trackChanged || durationBecameValid) {
      _currentMetadata = processedMetadata;
      metadataChanged = true;
      _trackOffset = Duration.zero;

      // Cancel any pending candidate pause for the old track.
      _candidatePauseCompleter?.complete(false);
      _candidatePauseCompleter = null;
      _isPausedForCandidates = false;
      _candidateSheetOpenedEarly = false;
      _candidates = [];
      _clearReadingState();
      _invalidateLyricsRequests();
      _invalidateTranslationRequests();

      if (_currentMetadata != null) {
        if (_currentMetadata!.duration.inSeconds > 0) {
          _fetchLyrics(_currentMetadata!);
        } else {
          _isLoading = false;
          _lyricsResult = LyricsResult.empty();
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _lyricsResult = LyricsResult.empty();
        notifyListeners();
      }
    } else if (processedMetadata != _currentMetadata) {
      _currentMetadata = processedMetadata;
      metadataChanged = true;
    }

    final playbackChanged = _isPlaying != isPlaying;
    final capabilitiesChanged = _controlAbility != controlAbility;

    final now = DateTime.now();
    if (_playbackToggleLockedUntil == null ||
        now.isAfter(_playbackToggleLockedUntil!)) {
      _isPlaying = isPlaying;
      _playbackToggleLockedUntil = null;
    } else if (_isPlaying == isPlaying) {
      _playbackToggleLockedUntil = null;
    }

    _setCurrentPosition(position);
    _controlAbility = controlAbility;
    final indexChanged = _updateCurrentIndex();

    if (metadataChanged ||
        playbackChanged ||
        capabilitiesChanged ||
        indexChanged) {
      notifyListeners();
    }
  }

  void requestAndroidPermission() {
    final service = mediaService;
    if (service is AndroidMediaService) {
      service.openSettings();
    }
  }

  Future<void> _clearTranslationCacheForCurrentTrack(
    MediaMetadata metadata,
  ) async {
    await Future.wait(
      [
        ..._settings.translationTargetLanguages.current,
        LyricsCacheService.manualTranslationSkipLanguage,
      ].map(
        (lang) => _cacheService.clearTranslationCache(
          _cacheService.generateTranslationCacheId(
            metadata.title,
            metadata.artist,
            lang,
          ),
        ),
      ),
    );
  }

  void _applyReadingFromResult(LyricsResult result) {
    final reading = result.reading;
    if (reading == null || reading.isEmpty) return;

    _readingResult = reading;
    _readingCandidates = appendReadingCandidateIfNeeded(
      _readingCandidates,
      reading,
    );

    if (!_settings.cacheEnabled.current) return;
    final metadata = _currentMetadata;
    if (metadata == null) return;
    final cacheId = _cacheService.generateCacheId(
      metadata.title,
      metadata.artist,
      metadata.album,
      metadata.duration.inSeconds,
      isRichSync: result.isRichSync,
    );
    unawaited(
      _cacheService.cacheReading(
        cacheId,
        reading,
        source: result.source,
        sourceProvider: result.sourceProvider?.name,
      ),
    );
    for (final candidate in _readingCandidates) {
      unawaited(
        _cacheService.cacheReadingCandidate(
          cacheId,
          candidate,
          source: result.source,
          sourceProvider: result.sourceProvider?.name,
        ),
      );
    }
  }

  /// Switches the reading track used for kanji annotation and persists the
  /// choice, mirroring [selectTranslationCandidate].
  Future<void> selectReadingCandidate(LyricsReading reading) async {
    final metadata = _currentMetadata;
    if (metadata == null) return;
    if (identical(_readingResult, reading)) return;

    _readingResult = reading;
    notifyListeners();

    if (!_settings.cacheEnabled.current) return;
    final cacheId = _cacheService.generateCacheId(
      metadata.title,
      metadata.artist,
      metadata.album,
      metadata.duration.inSeconds,
      isRichSync: _lyricsResult.isRichSync,
    );
    await _cacheService.cacheReading(
      cacheId,
      reading,
      source: _lyricsResult.source,
      sourceProvider: _lyricsResult.sourceProvider?.name,
    );
  }

  Future<void> markCurrentTranslationAsSkipped() async {
    final metadata = _currentMetadata;
    if (metadata == null) return;
    if (!_settings.translationEnabled.current) return;

    _invalidateTranslationRequests();
    final skipped = LyricsResult(
      lyrics: const [],
      source: 'SKIPPED',
      translation: false,
      language: LyricsCacheService.manualTranslationSkipLanguage,
      translationProvider: LyricsCacheService.manualTranslationSkipProvider,
      sourceProvider: _lyricsResult.sourceProvider,
    );
    _translationResult = skipped;
    _display.invalidateAlignment();
    notifyListeners();

    if (_settings.cacheEnabled.current) {
      final cacheId = _cacheService.generateTranslationCacheId(
        metadata.title,
        metadata.artist,
        LyricsCacheService.manualTranslationSkipLanguage,
      );
      await _cacheService.cacheTranslation(cacheId, skipped);
    }
  }

  Future<void> markCurrentTrackAsPureMusic() async {
    final metadata = _currentMetadata;
    if (metadata == null) return;

    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    _isPausedForCandidates = false;
    _invalidateLyricsRequests();
    _invalidateTranslationRequests();
    _isFetching = false;
    _isLoading = false;

    final result = LyricsResult(
      lyrics: const [],
      source: LyricsCacheService.manualPureMusicSource,
      isSynced: false,
      isPureMusic: true,
    );
    _lyricsResult = result;
    _appendCandidateIfNeeded(result);
    _updateCurrentIndex();
    notifyListeners();

    if (_settings.cacheEnabled.current) {
      await _cacheService.cacheLyrics(
        metadata.title,
        metadata.artist,
        metadata.album,
        metadata.duration.inSeconds,
        result,
      );
    }
  }

  /// Called when the user opens the candidates sheet.
  /// If the stream is already paused, completes the Completer to resume.
  /// If the stream hasn't reached the pause point yet, sets a flag so it
  /// skips the wait when it eventually does.
  void setCandidateSheetOpen(bool isOpen) {
    _isCandidateSheetOpen = isOpen;
    if (isOpen) {
      _resumePausedCandidateFetch();
    }
  }

  void resumeCandidateFetch() {
    if (_resumePausedCandidateFetch()) {
      return;
    }

    if (!_isPausedForCandidates && _candidatePauseCompleter == null) {
      // Sheet opened before the stream reached the pause point.
      _candidateSheetOpenedEarly = true;
    }
  }

  bool _resumePausedCandidateFetch() {
    if (_isPausedForCandidates && _candidatePauseCompleter != null) {
      // Already paused — wake it up.
      _isPausedForCandidates = false;
      _candidatePauseCompleter!.complete(true);
      _candidatePauseCompleter = null;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Replaces the current lyrics display with [candidate] and persists it to
  /// the Isar cache so subsequent loads use this selection.
  Future<void> selectCandidate(LyricsResult candidate) async {
    if (_currentMetadata == null || candidate.isFailure) return;

    // Cancel any ongoing candidate fetch for this track.
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    _isPausedForCandidates = false;
    _invalidateLyricsRequests();
    _isFetching = false;
    _isLoading = false;

    final result = _prepareLyricsResultForDisplay(candidate);
    final invalidatedTranslationTargets = _invalidatedTranslationTargetsFor(
      result,
    );

    _lyricsResult = result;
    _translationRequestVersion++;
    _display.invalidateAlignment();
    _updateCurrentIndex();
    notifyListeners();

    if (_settings.cacheEnabled.current) {
      await _cacheService.cacheLyrics(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        _currentMetadata!.album,
        _currentMetadata!.duration.inSeconds,
        candidate, // store the raw (un-trimmed) result so re-loads are consistent
      );
      AppLogger.debug(
        '[LyricsProvider] Candidate from ${candidate.source} saved to cache.',
      );
    }

    if (_settings.translationEnabled.current &&
        result.lyrics.isNotEmpty &&
        invalidatedTranslationTargets.isNotEmpty) {
      unawaited(
        _fetchTranslationsForCurrentTrack(
          _currentMetadata!,
          clearTranslationState: false,
          skipCacheLookup: true,
          refetchTargets: invalidatedTranslationTargets,
        ),
      );
    }
  }

  /// Merges word-level timing from [richSource] into [syncedTarget], producing
  /// a new rich-synced result that is applied and cached immediately.
  Future<void> richifyCandidate({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
  }) async {
    if (_currentMetadata == null) return;

    final richified = RichifyHelper.apply(
      syncedTarget: syncedTarget,
      richSource: richSource,
    );

    // Add to the candidate list so it shows up (and is marked active) in the
    // sheet after the user returns to it.
    _appendCandidateIfNeeded(richified);

    // Reuse selectCandidate so trimming + silence prepending is consistent.
    await selectCandidate(richified);
  }

  /// Replaces the current translation with [candidate] and persists it to the
  /// Isar cache so subsequent loads use this selection.
  Future<void> selectTranslationCandidate(LyricsResult candidate) async {
    if (_currentMetadata == null || candidate.isFailure) return;
    final taggedCandidate = candidate.copyWith(
      sourceProvider: _lyricsResult.sourceProvider,
    );
    _translationRequestVersion++;
    _translationResult = taggedCandidate;
    _display.invalidateAlignment(); // Invalidate alignment cache.
    _updateCurrentIndex();
    notifyListeners();

    if (_settings.cacheEnabled.current && taggedCandidate.language != null) {
      final targetLanguage = taggedCandidate.language!;
      final cacheId = _cacheService.generateTranslationCacheId(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        targetLanguage,
      );
      await _cacheService.cacheTranslation(cacheId, taggedCandidate);
      AppLogger.debug(
        '[LyricsProvider] Translation candidate from ${candidate.translationProvider} saved to cache.',
      );
    }
  }

  /// Manually re-fires the lyrics fetch logic without resetting the album art.
  Future<void> refetchLyrics() async {
    final metadata = _currentMetadata;
    if (metadata != null) {
      await _cacheService.clearTrackCache(
        metadata.title,
        metadata.artist,
        metadata.album,
        metadata.duration.inSeconds,
      );
      await _fetchLyrics(metadata);
    }
  }

  /// Manually re-fires the translation fetch logic to refresh translations.
  Future<void> refetchTranslations() async {
    final metadata = _currentMetadata;
    if (metadata == null) return;
    if (!_settings.translationEnabled.current) return;
    if (_lyricsResult.lyrics.isEmpty) return;
    await _fetchTranslationsForCurrentTrack(
      metadata,
      showLoadingState: true,
      clearCachedTranslations: true,
    );
  }

  bool _updateCurrentIndex() {
    final previousIndex = _currentIndex;
    if (_lyricsResult.lyrics.isEmpty) {
      _currentIndex = -1;
      return previousIndex != _currentIndex;
    }

    final adjustedPosition = _currentPosition + globalOffset + _trackOffset;

    if (adjustedPosition < _lyricsResult.lyrics[0].startTime) {
      _currentIndex = -1;
      return previousIndex != _currentIndex;
    }

    int low = 0;
    int high = _lyricsResult.lyrics.length - 1;
    int matchedIndex = -1;

    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      if (_lyricsResult.lyrics[mid].startTime <= adjustedPosition) {
        matchedIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    _currentIndex = matchedIndex;
    final indexChanged = previousIndex != _currentIndex;
    if (indexChanged) {
      positionResyncNotifier.value = _currentPosition;
    }
    return indexChanged;
  }

  void _setCurrentPosition(Duration position, {bool forceResync = false}) {
    if (_currentPosition == position) return;
    final previousPosition = _currentPosition;
    _currentPosition = position;
    currentPositionNotifier.value = position;

    final delta = position - previousPosition;
    if (forceResync ||
        delta < Duration.zero ||
        delta > _positionResyncThreshold) {
      positionResyncNotifier.value = position;
    }
  }

  bool _disposed = false;

  void _notify() => notifyListeners();

  bool get cacheDatabasePromptPending =>
      LyricsCacheService.promptPending && !LyricsCacheService.rebuildDeclined;

  String? get cacheDatabaseError => LyricsCacheService.openError?.toString();

  Future<void> rebuildCacheDatabase() => LyricsCacheService.rebuild();

  void dismissCacheDatabasePrompt() {
    LyricsCacheService.declineRebuild();
  }

  void _onCacheDatabaseChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lyricsScope?.cancel();
    _translationScope?.cancel();
    LyricsCacheService.removeListener(_onCacheDatabaseChanged);
    _permissionTimer?.cancel();
    mediaService.removeListener(_onMediaChanged);
    mediaService.stopPolling();
    mediaService.dispose();
    currentPositionNotifier.dispose();
    positionResyncNotifier.dispose();
    artworkUrlsNotifier.dispose();
    super.dispose();
  }
}
