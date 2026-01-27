import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../services/media_service.dart';
import '../services/lyrics_service.dart';
import '../services/settings_service.dart';
import '../services/providers/lyrics_cache_service.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService mediaService = MediaService.create();
  final LyricsService _lyricsService = LyricsService();
  final SettingsService _settingsService = SettingsService();
  final LyricsCacheService _cacheService = LyricsCacheService();

  MediaMetadata? _currentMetadata;
  Timer? _permissionTimer;
  LyricsResult _lyricsResult = LyricsResult.empty();
  Duration _currentPosition = Duration.zero;
  Duration _globalOffset = Duration.zero;
  Duration _trackOffset = Duration.zero;
  int _currentIndex = -1;
  int _linesBefore = 2;
  int _scrollAutoResumeDelay = 5;
  bool _blurEnabled = true;
  List<LyricProviderType> _trimMetadataProviders = [LyricProviderType.netease];
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _androidPermissionGranted = !Platform.isAndroid;
  String _loadingStatus = "";
  double _fontSize = 36.0;
  double _inactiveScale = 0.85;

  MediaControlAbility _controlAbility = MediaControlAbility.none();
  DateTime? _playbackToggleLockedUntil;

  LyricsProvider() {
    _loadSettings();
    mediaService.addListener(_onMediaChanged);
    mediaService.startPolling();
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
  List<Lyric> get lyrics => _lyricsResult.lyrics;
  LyricsResult get lyricsResult => _lyricsResult;
  Duration get currentPosition => _currentPosition;
  Duration get globalOffset => _globalOffset;
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;
  int get linesBefore => _linesBefore;
  int get scrollAutoResumeDelay => _scrollAutoResumeDelay;
  bool get blurEnabled => _blurEnabled;
  List<LyricProviderType> get trimMetadataProviders => _trimMetadataProviders;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get androidPermissionGranted => _androidPermissionGranted;
  String get loadingStatus => _loadingStatus;
  double get fontSize => _fontSize;
  double get inactiveScale => _inactiveScale;
  MediaControlAbility get controlAbility => _controlAbility;

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
    if (lyrics.isEmpty) return false;

    // Mid-song pause indicator (includes injected prelude)
    if (_currentIndex >= 0 && _currentIndex < lyrics.length) {
      if (lyrics[_currentIndex].text.trim().isEmpty) {
        return true;
      }
    }

    return false;
  }

  double get interludeProgress {
    if (!isInterlude || lyrics.isEmpty) return 0.0;
    final adjustedPosition = _currentPosition + _globalOffset + _trackOffset;

    // Empty line progress (works for prelude too)
    if (_currentIndex >= 0 && _currentIndex < lyrics.length - 1) {
      final currentStartTime = lyrics[_currentIndex].startTime;
      final nextStartTime = lyrics[_currentIndex + 1].startTime;
      final duration =
          nextStartTime.inMilliseconds -
          currentStartTime.inMilliseconds -
          500 - // auto scroll takes 500ms
          250; // shrink animation takes 250ms
      if (duration > 0) {
        return ((adjustedPosition.inMilliseconds -
                    currentStartTime.inMilliseconds) /
                duration)
            .clamp(0.0, 1.0);
      }
    }

    return 0.0;
  }

  Duration get interludeDuration {
    if (!isInterlude || lyrics.isEmpty) return Duration.zero;
    if (_currentIndex >= 0 && _currentIndex < lyrics.length - 1) {
      final currentStartTime = lyrics[_currentIndex].startTime;
      final nextStartTime = lyrics[_currentIndex + 1].startTime;
      return nextStartTime -
          currentStartTime -
          Duration(milliseconds: 500) - // auto scroll takes 500ms
          Duration(milliseconds: 250); // shrink animation takes 250ms
    }
    return Duration.zero;
  }

  Future<void> _loadSettings() async {
    _linesBefore = await _settingsService.getLinesBefore();
    final globalOffsetMs = await _settingsService.getGlobalOffset();
    _globalOffset = Duration(milliseconds: globalOffsetMs);
    _scrollAutoResumeDelay = await _settingsService.getScrollAutoResumeDelay();
    _blurEnabled = await _settingsService.getBlurEnabled();
    _trimMetadataProviders = await _settingsService.getTrimMetadataProviders();
    _fontSize = await _settingsService.getFontSize();
    _inactiveScale = await _settingsService.getInactiveScale();
    notifyListeners();
  }

  void setLinesBefore(int lines) {
    _linesBefore = lines;
    _settingsService.setLinesBefore(lines);
    notifyListeners();
  }

  void setScrollAutoResumeDelay(int seconds) {
    _scrollAutoResumeDelay = seconds;
    _settingsService.setScrollAutoResumeDelay(seconds);
    notifyListeners();
  }

  void setBlurEnabled(bool enabled) {
    _blurEnabled = enabled;
    _settingsService.setBlurEnabled(enabled);
    notifyListeners();
  }

  void setTrimMetadataProviders(List<LyricProviderType> providers) {
    _trimMetadataProviders = providers;
    _settingsService.setTrimMetadataProviders(providers);
    notifyListeners();
  }

  bool shouldTrimMetadata(LyricProviderType provider) {
    return _trimMetadataProviders.contains(provider);
  }

  void setFontSize(double size) {
    _fontSize = size;
    _settingsService.setFontSize(size);
    notifyListeners();
  }

  void setInactiveScale(double scale) {
    _inactiveScale = scale;
    _settingsService.setInactiveScale(scale);
    notifyListeners();
  }

  void setGlobalOffset(Duration offset) {
    _globalOffset = offset;
    _settingsService.setGlobalOffset(offset.inMilliseconds);
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
      if (_currentMetadata != null) {
        // Force the fetching logic to re-search for artwork by resetting to 'fallback'.
        // This is only necessary if the system art was 'fallback' (i.e. no local art).
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
      // Keep our existing artUrl if the fresh metadata is still reporting 'fallback'
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
      _trackOffset = Duration.zero; // Reset offset for new song

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
      // Only artUrl or something else minor changed
      _currentMetadata = processedMetadata;
      metadataChanged = true;
    }

    bool capabilitiesChanged = _controlAbility != controlAbility;

    // Update playback state if not locked
    final now = DateTime.now();
    if (_playbackToggleLockedUntil == null ||
        now.isAfter(_playbackToggleLockedUntil!)) {
      _isPlaying = isPlaying;
      _playbackToggleLockedUntil = null;
    } else if (_isPlaying == isPlaying) {
      // Unlock early if system caught up
      _playbackToggleLockedUntil = null;
    }

    _currentPosition = position;
    _controlAbility = controlAbility;
    _updateCurrentIndex();

    if (metadataChanged || isPlaying || capabilitiesChanged) {
      notifyListeners();
    }
  }

  void requestAndroidPermission() {
    final service = mediaService;
    if (service is AndroidMediaService) {
      service.openSettings();
    }
  }

  Future<void> _fetchLyrics(MediaMetadata metadata) async {
    _isLoading = true;
    _loadingStatus = "Starting search...";
    _lyricsResult = LyricsResult.empty();
    notifyListeners();

    try {
      final stream = _lyricsService.fetchLyrics(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        durationSeconds: metadata.duration.inSeconds,
        onStatusUpdate: (status) {
          _loadingStatus = status;
          notifyListeners();
        },
        isCancelled: () => !metadata.isSameTrack(_currentMetadata),
        trimMetadataProviders: _trimMetadataProviders,
      );

      // Insert the prelude indication line if needed
      await for (var result in stream) {
        if (!metadata.isSameTrack(_currentMetadata)) return;

        result = result.trim();

        if (result.lyrics.isNotEmpty &&
            result.lyrics[0].startTime > const Duration(seconds: 3)) {
          // Ensure we don't modify the same list if it's shared
          final newLyrics = List<Lyric>.from(result.lyrics);
          newLyrics.insert(
            0,
            Lyric(
              text: '',
              startTime: Duration.zero,
              endTime: result.lyrics[0].startTime,
            ),
          );
          result = result.copyWith(lyrics: newLyrics);
        }

        _lyricsResult = result;
        if (result.lyrics.isNotEmpty || result.isPureMusic) {
          _isLoading = false;
        }

        if (_currentMetadata?.artUrl == 'fallback' &&
            result.artworkUrl != null) {
          _currentMetadata = _currentMetadata!.copyWith(
            artUrl: result.artworkUrl,
          );
        }

        _updateCurrentIndex();
        notifyListeners();
      }
    } catch (e) {
      if (!metadata.isSameTrack(_currentMetadata)) return;
      _loadingStatus = "Error: $e";
    } finally {
      if (metadata.isSameTrack(_currentMetadata)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _updateCurrentIndex() {
    if (_lyricsResult.lyrics.isEmpty) {
      _currentIndex = -1;
      return;
    }

    final adjustedPosition = _currentPosition + _globalOffset + _trackOffset;

    if (adjustedPosition < _lyricsResult.lyrics[0].startTime) {
      if (_currentIndex != -1) {
        _currentIndex = -1;
        notifyListeners();
      }
      return;
    }

    for (int i = 0; i < _lyricsResult.lyrics.length; i++) {
      if (adjustedPosition >= _lyricsResult.lyrics[i].startTime &&
          (i == _lyricsResult.lyrics.length - 1 ||
              adjustedPosition < _lyricsResult.lyrics[i + 1].startTime)) {
        if (_currentIndex != i) {
          _currentIndex = i;
          notifyListeners();
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    mediaService.removeListener(_onMediaChanged);
    mediaService.stopPolling();
    mediaService.dispose();
    super.dispose();
  }
}
