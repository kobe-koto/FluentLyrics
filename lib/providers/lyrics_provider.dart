import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../services/media_service.dart';
import '../services/lyrics_service.dart';
import '../services/settings_service.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService _mediaService = LinuxMediaService();
  final LyricsService _lyricsService = LyricsService();
  final SettingsService _settingsService = SettingsService();

  Timer? _pollTimer;
  MediaMetadata? _currentMetadata;
  List<Lyric> _lyrics = [];
  Duration _currentPosition = Duration.zero;
  Duration _globalOffset = Duration.zero;
  Duration _trackOffset = Duration.zero;
  int _currentIndex = 0;
  int _linesBefore = 2;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _loadingStatus = "";

  LyricsProvider() {
    _loadSettings();
    _startPolling();
  }

  MediaMetadata? get currentMetadata => _currentMetadata;
  List<Lyric> get lyrics => _lyrics;
  Duration get currentPosition => _currentPosition;
  Duration get globalOffset => _globalOffset;
  Duration get trackOffset => _trackOffset;
  int get currentIndex => _currentIndex;
  int get linesBefore => _linesBefore;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String get loadingStatus => _loadingStatus;

  Future<void> _loadSettings() async {
    _linesBefore = await _settingsService.getLinesBefore();
    final globalOffsetMs = await _settingsService.getGlobalOffset();
    _globalOffset = Duration(milliseconds: globalOffsetMs);
    notifyListeners();
  }

  void setLinesBefore(int lines) {
    _linesBefore = lines;
    _settingsService.setLinesBefore(lines);
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

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) async {
      await _updateStatus();
    });
  }

  Future<void> _updateStatus() async {
    final metadata = await _mediaService.getMetadata();
    final isPlaying = await _mediaService.isPlaying();
    final position = await _mediaService.getPosition();

    bool metadataChanged = false;
    if (metadata != _currentMetadata ||
        (metadata != null &&
            _currentMetadata != null &&
            _currentMetadata!.duration.inSeconds == 0 &&
            metadata.duration.inSeconds > 0)) {
      _currentMetadata = metadata;
      metadataChanged = true;
      _trackOffset = Duration.zero; // Reset offset for new song

      if (_currentMetadata != null) {
        if (_currentMetadata!.duration.inSeconds > 0) {
          _fetchLyrics(_currentMetadata!);
        } else {
          _lyrics = [];
          notifyListeners();
        }
      } else {
        _lyrics = [];
        notifyListeners();
      }
    }

    _isPlaying = isPlaying;
    _currentPosition = position;
    _updateCurrentIndex();

    if (metadataChanged || isPlaying) {
      notifyListeners();
    }
  }

  Future<void> _fetchLyrics(MediaMetadata metadata) async {
    _isLoading = true;
    _loadingStatus = "Starting search...";
    _lyrics = [];
    notifyListeners();

    final fetchedLyrics = await _lyricsService.fetchLyrics(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      durationSeconds: metadata.duration.inSeconds,
      onStatusUpdate: (status) {
        _loadingStatus = status;
        notifyListeners();
      },
    );

    _lyrics = fetchedLyrics;
    _isLoading = false;
    _updateCurrentIndex();
    notifyListeners();
  }

  void _updateCurrentIndex() {
    if (_lyrics.isEmpty) {
      _currentIndex = 0;
      return;
    }

    final adjustedPosition = _currentPosition + _globalOffset + _trackOffset;

    for (int i = 0; i < _lyrics.length; i++) {
      if (adjustedPosition >= _lyrics[i].startTime &&
          (i == _lyrics.length - 1 ||
              adjustedPosition < _lyrics[i + 1].startTime)) {
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
    _pollTimer?.cancel();
    super.dispose();
  }
}
