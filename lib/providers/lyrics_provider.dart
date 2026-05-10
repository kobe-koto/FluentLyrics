import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import 'lyrics_provider_settings.dart';
import '../services/media_service.dart';
import '../services/lyrics_service.dart';
import '../services/settings_service.dart';
import '../services/providers/lyrics_cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/lyrics_candidate_helper.dart';
import '../utils/lyrics_display_helper.dart';
import '../utils/richify_helper.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService mediaService;
  final LyricsService _lyricsService;
  final SettingsService _settingsService;
  final LyricsCacheService _cacheService;

  MediaMetadata? _currentMetadata;
  Timer? _permissionTimer;
  LyricsResult _lyricsResult = LyricsResult.empty();
  LyricsResult? _translationResult;
  Duration _currentPosition = Duration.zero;
  final ValueNotifier<Duration> currentPositionNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> positionResyncNotifier = ValueNotifier(
    Duration.zero,
  );
  static const Duration _positionResyncThreshold = Duration(milliseconds: 400);

  LyricsProviderSettings _settings = LyricsProviderSettings.defaults();

  Setting<bool> get _cacheEnabled => _settings.cacheEnabled;
  set _cacheEnabled(Setting<bool> value) => _settings.cacheEnabled = value;

  Setting<int> get _linesBefore => _settings.linesBefore;
  set _linesBefore(Setting<int> value) => _settings.linesBefore = value;

  Setting<int> get _globalOffsetMs => _settings.globalOffsetMs;
  set _globalOffsetMs(Setting<int> value) => _settings.globalOffsetMs = value;

  Setting<int> get _scrollAutoResumeDelay => _settings.scrollAutoResumeDelay;
  set _scrollAutoResumeDelay(Setting<int> value) =>
      _settings.scrollAutoResumeDelay = value;

  Setting<bool> get _blurEnabled => _settings.blurEnabled;
  set _blurEnabled(Setting<bool> value) => _settings.blurEnabled = value;

  Setting<bool> get _richSyncEnabled => _settings.richSyncEnabled;
  set _richSyncEnabled(Setting<bool> value) =>
      _settings.richSyncEnabled = value;

  Setting<List<LyricProviderType>> get _trimMetadataProviders =>
      _settings.trimMetadataProviders;
  set _trimMetadataProviders(Setting<List<LyricProviderType>> value) =>
      _settings.trimMetadataProviders = value;

  Setting<double> get _fontSize => _settings.fontSize;
  set _fontSize(Setting<double> value) => _settings.fontSize = value;

  Setting<double> get _inactiveScale => _settings.inactiveScale;
  set _inactiveScale(Setting<double> value) => _settings.inactiveScale = value;

  Setting<bool> get _translationHighlightOnly =>
      _settings.translationHighlightOnly;
  set _translationHighlightOnly(Setting<bool> value) =>
      _settings.translationHighlightOnly = value;

  Setting<bool> get _translationEnabled => _settings.translationEnabled;
  set _translationEnabled(Setting<bool> value) =>
      _settings.translationEnabled = value;

  Setting<List<String>> get _translationTargetLanguages =>
      _settings.translationTargetLanguages;
  set _translationTargetLanguages(Setting<List<String>> value) =>
      _settings.translationTargetLanguages = value;

  Setting<List<String>> get _translationIgnoredLanguages =>
      _settings.translationIgnoredLanguages;
  set _translationIgnoredLanguages(Setting<List<String>> value) =>
      _settings.translationIgnoredLanguages = value;

  Setting<int> get _translationBias => _settings.translationBias;
  set _translationBias(Setting<int> value) => _settings.translationBias = value;

  Setting<int> get _translationAlignmentThreshold =>
      _settings.translationAlignmentThreshold;
  set _translationAlignmentThreshold(Setting<int> value) =>
      _settings.translationAlignmentThreshold = value;

  Setting<String> get _llmApiEndpoint => _settings.llmApiEndpoint;
  set _llmApiEndpoint(Setting<String> value) =>
      _settings.llmApiEndpoint = value;

  Setting<String> get _llmApiKey => _settings.llmApiKey;
  set _llmApiKey(Setting<String> value) => _settings.llmApiKey = value;

  Setting<String> get _llmModel => _settings.llmModel;
  set _llmModel(Setting<String> value) => _settings.llmModel = value;

  Setting<String> get _llmReasoningEffort => _settings.llmReasoningEffort;
  set _llmReasoningEffort(Setting<String> value) =>
      _settings.llmReasoningEffort = value;

  Setting<bool> get _keepScreenOn => _settings.keepScreenOn;
  set _keepScreenOn(Setting<bool> value) => _settings.keepScreenOn = value;

  Setting<bool> get _backgroundMotionEnabled =>
      _settings.backgroundMotionEnabled;
  set _backgroundMotionEnabled(Setting<bool> value) =>
      _settings.backgroundMotionEnabled = value;

  Setting<bool> get _experimentalRichInlineFontSizeGlitching =>
      _settings.experimentalRichInlineFontSizeGlitching;
  set _experimentalRichInlineFontSizeGlitching(Setting<bool> value) =>
      _settings.experimentalRichInlineFontSizeGlitching = value;

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

  /// Set to true when the sheet is opened before the stream reaches the pause
  /// point, so the pause skips waiting and continues immediately.
  bool _candidateSheetOpenedEarly = false;

  // Translation candidates
  List<LyricsResult> _translationCandidates = [];
  int _translationRequestVersion = 0;

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

  List<Lyric>? _cachedAlignedLyrics;
  LyricsResult? _lastLyricsResultForAlignment;
  LyricsResult? _lastTranslationResultForAlignment;
  bool? _lastRichSyncEnabledForAlignment;

  List<Lyric>? _cachedStrippedLyrics;
  LyricsResult? _lastLyricsResultForStripping;

  List<Lyric> get lyrics {
    final curRichSync = _richSyncEnabled.current;

    List<Lyric> baseLyrics;
    if (curRichSync) {
      baseLyrics = _lyricsResult.lyrics;
    } else {
      if (LyricsDisplayHelper.canReuseStrippedLyrics(
        cachedStrippedLyrics: _cachedStrippedLyrics,
        lastLyricsResultForStripping: _lastLyricsResultForStripping,
        lyricsResult: _lyricsResult,
      )) {
        baseLyrics = _cachedStrippedLyrics!;
      } else {
        baseLyrics = LyricsDisplayHelper.buildDisplayedLyrics(
          lyricsResult: _lyricsResult,
          richSyncEnabled: false,
        );
        _cachedStrippedLyrics = baseLyrics;
        _lastLyricsResultForStripping = _lyricsResult;
      }
    }

    if (_translationEnabled.current &&
        _translationResult?.rawTranslation != null) {
      if (LyricsDisplayHelper.canReuseAlignedLyrics(
        cachedAlignedLyrics: _cachedAlignedLyrics,
        lastLyricsResultForAlignment: _lastLyricsResultForAlignment,
        lyricsResult: _lyricsResult,
        lastTranslationResultForAlignment: _lastTranslationResultForAlignment,
        translationResult: _translationResult,
        lastRichSyncEnabledForAlignment: _lastRichSyncEnabledForAlignment,
        richSyncEnabled: curRichSync,
      )) {
        return _cachedAlignedLyrics!;
      }
      _cachedAlignedLyrics = LyricsDisplayHelper.buildDisplayedLyrics(
        lyricsResult: _lyricsResult,
        richSyncEnabled: curRichSync,
        translationEnabled: true,
        translationResult: _translationResult,
        translationAlignmentThreshold: _translationAlignmentThreshold.current,
      );
      _lastLyricsResultForAlignment = _lyricsResult;
      _lastTranslationResultForAlignment = _translationResult;
      _lastRichSyncEnabledForAlignment = curRichSync;
      return _cachedAlignedLyrics!;
    }

    return baseLyrics;
  }

  LyricsResult get lyricsResult {
    if (!_richSyncEnabled.current && _lyricsResult.isRichSync) {
      return _lyricsResult.copyWith(
        isRichSync: false,
        lyrics: lyrics, // Uses the getter above which strips inline parts
      );
    }
    return _lyricsResult;
  }

  LyricsResult? get translationResult =>
      _translationEnabled.current ? _translationResult : null;

  Duration get currentPosition => _currentPosition;
  Duration get globalOffset => Duration(milliseconds: _globalOffsetMs.current);
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;

  // Setting getters
  Setting<bool> get cacheEnabled => _cacheEnabled;
  Setting<int> get linesBefore => _linesBefore;
  Setting<int> get scrollAutoResumeDelay => _scrollAutoResumeDelay;
  Setting<bool> get blurEnabled => _blurEnabled;
  Setting<bool> get richSyncEnabled => _richSyncEnabled;
  Setting<List<LyricProviderType>> get trimMetadataProviders =>
      _trimMetadataProviders;
  Setting<double> get fontSize => _fontSize;
  Setting<double> get inactiveScale => _inactiveScale;
  Setting<int> get globalOffsetSetting => _globalOffsetMs;

  Setting<bool> get translationEnabled => _translationEnabled;
  Setting<bool> get translationHighlightOnly => _translationHighlightOnly;
  Setting<List<String>> get translationTargetLanguages =>
      _translationTargetLanguages;
  Setting<List<String>> get translationIgnoredLanguages =>
      _translationIgnoredLanguages;
  Setting<int> get translationBias => _translationBias;
  Setting<int> get translationAlignmentThreshold =>
      _translationAlignmentThreshold;
  Setting<String> get llmApiEndpoint => _llmApiEndpoint;
  Setting<String> get llmApiKey => _llmApiKey;
  Setting<String> get llmModel => _llmModel;
  Setting<String> get llmReasoningEffort => _llmReasoningEffort;
  Setting<bool> get keepScreenOn => _keepScreenOn;
  Setting<bool> get backgroundMotionEnabled => _backgroundMotionEnabled;
  Setting<bool> get experimentalRichInlineFontSizeGlitching =>
      _experimentalRichInlineFontSizeGlitching;

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

  void _clearTranslationState({bool clearCandidates = true}) {
    _translationResult = null;
    _cachedAlignedLyrics = null;
    _lastTranslationResultForAlignment = null;
    _lastRichSyncEnabledForAlignment = null;
    if (clearCandidates) {
      _translationCandidates = [];
    }
  }

  void _invalidateTranslationRequests({bool clearCandidates = true}) {
    _translationRequestVersion++;
    _clearTranslationState(clearCandidates: clearCandidates);
  }

  int _beginTranslationRequest() {
    _translationRequestVersion++;
    return _translationRequestVersion;
  }

  bool _canAcceptTranslationResult(MediaMetadata metadata, int requestVersion) {
    return _translationEnabled.current &&
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
      _translationTargetLanguages.current,
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

  void _finishLyricsFetchState(MediaMetadata metadata) {
    if (!metadata.isSameTrack(_currentMetadata)) return;
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
        _translationEnabled.current) {
      return;
    }
    if (_setFetchingState(false)) {
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    _settings = await LyricsProviderSettings.load(_settingsService);

    notifyListeners();
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
      currentSetting: _cacheEnabled,
      value: enabled,
      assign: (value) => _cacheEnabled = value,
      persist: _settingsService.setCacheEnabled,
    );
  }

  void setLinesBefore(int lines) {
    _setSettingValue(
      currentSetting: _linesBefore,
      value: lines,
      assign: (value) => _linesBefore = value,
      persist: _settingsService.setLinesBefore,
    );
  }

  void setScrollAutoResumeDelay(int seconds) {
    _setSettingValue(
      currentSetting: _scrollAutoResumeDelay,
      value: seconds,
      assign: (value) => _scrollAutoResumeDelay = value,
      persist: _settingsService.setScrollAutoResumeDelay,
    );
  }

  void setBlurEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _blurEnabled,
      value: enabled,
      assign: (value) => _blurEnabled = value,
      persist: _settingsService.setBlurEnabled,
    );
  }

  void setRichSyncEnabled(bool enabled) {
    final changed = _setSettingValue(
      currentSetting: _richSyncEnabled,
      value: enabled,
      assign: (value) => _richSyncEnabled = value,
      persist: _settingsService.setRichSyncEnabled,
    );
    if (!changed) return;

    if (_currentMetadata != null) {
      _fetchLyrics(_currentMetadata!);
    }
  }

  void setTrimMetadataProviders(List<LyricProviderType> providers) {
    _setSettingValue(
      currentSetting: _trimMetadataProviders,
      value: providers,
      assign: (value) => _trimMetadataProviders = value,
      persist: _settingsService.setTrimMetadataProviders,
      equals: listEquals,
    );
  }

  bool shouldTrimMetadata(LyricProviderType provider) {
    return _trimMetadataProviders.current.contains(provider);
  }

  void setFontSize(double size) {
    _setSettingValue(
      currentSetting: _fontSize,
      value: size,
      assign: (value) => _fontSize = value,
      persist: _settingsService.setFontSize,
    );
  }

  void setInactiveScale(double scale) {
    _setSettingValue(
      currentSetting: _inactiveScale,
      value: scale,
      assign: (value) => _inactiveScale = value,
      persist: _settingsService.setInactiveScale,
    );
  }

  void setTranslationTargetLanguages(List<String> languages) {
    final changed = _setSettingValue(
      currentSetting: _translationTargetLanguages,
      value: languages,
      assign: (value) => _translationTargetLanguages = value,
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
      currentSetting: _translationIgnoredLanguages,
      value: languages,
      assign: (value) => _translationIgnoredLanguages = value,
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
      currentSetting: _translationBias,
      value: bias,
      assign: (value) => _translationBias = value,
      persist: _settingsService.setTranslationBias,
    );
  }

  void setTranslationAlignmentThreshold(int threshold) {
    final changed = _setSettingValue(
      currentSetting: _translationAlignmentThreshold,
      value: threshold,
      assign: (value) => _translationAlignmentThreshold = value,
      persist: _settingsService.setTranslationAlignmentThreshold,
    );
    if (!changed) return;

    // Changing the threshold requires realigning lyrics
    _lastTranslationResultForAlignment = null;
    notifyListeners();
  }

  void setTranslationEnabled(bool enabled) {
    if (_translationEnabled.current == enabled) return;
    final wasEnabled = _translationEnabled.current;
    _translationEnabled = Setting(
      current: enabled,
      defaultValue: _translationEnabled.defaultValue,
      changed: enabled != _translationEnabled.defaultValue,
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
        _translationResult == null) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
    }
  }

  void setTranslationHighlightOnly(bool highlightOnly) {
    _setSettingValue(
      currentSetting: _translationHighlightOnly,
      value: highlightOnly,
      assign: (value) => _translationHighlightOnly = value,
      persist: _settingsService.setTranslationHighlightOnly,
    );
  }

  void setLlmApiEndpoint(String endpoint) {
    _setSettingValue(
      currentSetting: _llmApiEndpoint,
      value: endpoint,
      assign: (value) => _llmApiEndpoint = value,
      persist: _settingsService.setLlmApiEndpoint,
    );
  }

  void setLlmApiKey(String apiKey) {
    _setSettingValue(
      currentSetting: _llmApiKey,
      value: apiKey,
      assign: (value) => _llmApiKey = value,
      persist: _settingsService.setLlmApiKey,
    );
  }

  void setLlmModel(String model) {
    _setSettingValue(
      currentSetting: _llmModel,
      value: model,
      assign: (value) => _llmModel = value,
      persist: _settingsService.setLlmModel,
    );
  }

  void setLlmReasoningEffort(String effort) {
    _setSettingValue(
      currentSetting: _llmReasoningEffort,
      value: effort,
      assign: (value) => _llmReasoningEffort = value,
      persist: _settingsService.setLlmReasoningEffort,
    );
  }

  void setKeepScreenOn(bool enabled) {
    _setSettingValue(
      currentSetting: _keepScreenOn,
      value: enabled,
      assign: (value) => _keepScreenOn = value,
      persist: _settingsService.setKeepScreenOn,
    );
  }

  void setBackgroundMotionEnabled(bool enabled) {
    _setSettingValue(
      currentSetting: _backgroundMotionEnabled,
      value: enabled,
      assign: (value) => _backgroundMotionEnabled = value,
      persist: _settingsService.setBackgroundMotionEnabled,
    );
  }

  void setExperimentalRichInlineFontSizeGlitching(bool enabled) {
    _setSettingValue(
      currentSetting: _experimentalRichInlineFontSizeGlitching,
      value: enabled,
      assign: (value) => _experimentalRichInlineFontSizeGlitching = value,
      persist: _settingsService.setExperimentalRichInlineFontSizeGlitching,
    );
  }

  void setGlobalOffset(Duration offset) {
    final ms = offset.inMilliseconds;
    final changed = _setSettingValue(
      currentSetting: _globalOffsetMs,
      value: ms,
      assign: (value) => _globalOffsetMs = value,
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
      _translationTargetLanguages.current.map(
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

  Future<void> _fetchTranslationsForCurrentTrack(
    MediaMetadata metadata, {
    bool showLoadingState = false,
    bool clearCachedTranslations = false,
  }) async {
    if (!_translationEnabled.current || _lyricsResult.lyrics.isEmpty) return;

    if (clearCachedTranslations) {
      await _clearTranslationCacheForCurrentTrack(_currentMetadata!);
    }

    final requestVersion = _beginTranslationRequest();
    _clearTranslationState();

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
        isCancelled: () =>
            !_canAcceptTranslationResult(metadata, requestVersion),
        onTranslationCandidate: (trans) {
          if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
          if (_appendTranslationCandidateIfNeeded(trans)) {
            notifyListeners();
          }
        },
      );

      await for (var transResult in transStream) {
        if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
        _translationResult = transResult;
        _cachedAlignedLyrics = null;
        _updateCurrentIndex();
        notifyListeners();
      }
    } catch (e) {
      if (!_canAcceptTranslationResult(metadata, requestVersion)) return;
      if (_setLoadingStatus('Error: $e')) {
        notifyListeners();
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
    _beginLyricsFetchState();

    try {
      final stream = _lyricsService.fetchLyrics(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        onStatusUpdate: (status) {
          if (_setLoadingStatus(status)) {
            notifyListeners();
          }
        },
        onFetchStatusUpdate: (status) {
          if (_setFetchingState(status)) {
            notifyListeners();
          }
        },
        isCancelled: () => !metadata.isSameTrack(_currentMetadata),
        trimMetadataProviders: _trimMetadataProviders.current,
        richSyncEnabled: _richSyncEnabled.current,
        onTranslation: (trans) {
          if (!metadata.isSameTrack(_currentMetadata) ||
              !_translationEnabled.current ||
              trans.rawTranslation!.isEmpty ||
              trans.language == null) {
            return;
          }

          if (!_matchesTranslationTargetLanguage(trans.language!)) return;
          _appendTranslationCandidateIfNeeded(trans);

          if (_translationResult == null) {
            _translationResult = trans;
            notifyListeners();
            if (_cacheEnabled.current &&
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
          if (!metadata.isSameTrack(_currentMetadata)) return;
          if (_appendCandidateIfNeeded(candidate)) {
            notifyListeners();
          }
        },
        onPauseForCandidates: () async {
          if (!metadata.isSameTrack(_currentMetadata)) return false;
          // If the sheet was opened before we reached this point, skip waiting.
          if (_candidateSheetOpenedEarly) {
            _candidateSheetOpenedEarly = false;
            return true;
          }
          _candidatePauseCompleter = Completer<bool>();
          _isPausedForCandidates = true;
          notifyListeners();
          return _candidatePauseCompleter!.future;
        },
      );

      await for (var result in stream) {
        if (!metadata.isSameTrack(_currentMetadata)) return;

        result = _prepareLyricsResultForDisplay(result);

        _lyricsResult = result;
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
        notifyListeners();
      }

      if (!metadata.isSameTrack(_currentMetadata)) return;

      if (_translationEnabled.current &&
          !skipFetchTranslations &&
          _lyricsResult.lyrics.isNotEmpty &&
          _translationResult == null) {
        await _fetchTranslationsForCurrentTrack(metadata);
      }
    } catch (e) {
      if (!metadata.isSameTrack(_currentMetadata)) return;
      _setLoadingStatus('Error: $e');
    } finally {
      _finishLyricsFetchState(metadata);
    }
  }

  /// Called when the user opens the candidates sheet.
  /// If the stream is already paused, completes the Completer to resume.
  /// If the stream hasn't reached the pause point yet, sets a flag so it
  /// skips the wait when it eventually does.
  void resumeCandidateFetch() {
    if (_isPausedForCandidates && _candidatePauseCompleter != null) {
      // Already paused — wake it up.
      _isPausedForCandidates = false;
      _candidatePauseCompleter!.complete(true);
      _candidatePauseCompleter = null;
      notifyListeners();
    } else if (!_isPausedForCandidates && _candidatePauseCompleter == null) {
      // Sheet opened before the stream reached the pause point.
      _candidateSheetOpenedEarly = true;
    }
  }

  /// Replaces the current lyrics display with [candidate] and persists it to
  /// the Isar cache so subsequent loads use this selection.
  Future<void> selectCandidate(LyricsResult candidate) async {
    if (_currentMetadata == null) return;

    // Cancel any ongoing candidate fetch for this track.
    _candidatePauseCompleter?.complete(false);
    _candidatePauseCompleter = null;
    _isPausedForCandidates = false;

    final result = _prepareLyricsResultForDisplay(candidate);

    _lyricsResult = result;
    _invalidateTranslationRequests();
    _updateCurrentIndex();
    notifyListeners();

    if (_cacheEnabled.current) {
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

    if (_translationEnabled.current && result.lyrics.isNotEmpty) {
      unawaited(_fetchTranslationsForCurrentTrack(_currentMetadata!));
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
    if (_currentMetadata == null) return;
    _translationResult = candidate;
    _cachedAlignedLyrics = null; // Invalidate alignment cache.
    _updateCurrentIndex();
    notifyListeners();

    if (_cacheEnabled.current && candidate.language != null) {
      final targetLanguage = candidate.language!;
      final cacheId = _cacheService.generateTranslationCacheId(
        _currentMetadata!.title,
        _currentMetadata!.artist,
        targetLanguage,
      );
      await _cacheService.cacheTranslation(cacheId, candidate);
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
    if (!_translationEnabled.current) return;
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

  @override
  void dispose() {
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
