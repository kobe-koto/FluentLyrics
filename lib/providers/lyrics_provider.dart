import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../services/media_service.dart';
import '../services/lyrics_service.dart';

class LyricsProvider with ChangeNotifier {
  final MediaService _mediaService = LinuxMediaService();
  final LyricsService _lyricsService = LyricsService();

  Timer? _pollTimer;
  MediaMetadata? _currentMetadata;
  List<Lyric> _lyrics = [];
  Duration _currentPosition = Duration.zero;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;

  LyricsProvider() {
    _startPolling();
  }

  MediaMetadata? get currentMetadata => _currentMetadata;
  List<Lyric> get lyrics => _lyrics;
  Duration get currentPosition => _currentPosition;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (
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

      if (_currentMetadata != null) {
        if (_currentMetadata!.duration.inSeconds > 0) {
          _fetchLyrics(_currentMetadata!, true);
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

  Future<void> _fetchLyrics(
    MediaMetadata metadata, [
    bool cached = true,
  ]) async {
    _isLoading = true;
    _lyrics = [];
    notifyListeners();

    final fetchedLyrics = await _lyricsService.fetchLyrics(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      durationSeconds: metadata.duration.inSeconds,
      cached: cached,
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

    for (int i = 0; i < _lyrics.length; i++) {
      if (_currentPosition >= _lyrics[i].startTime &&
          (i == _lyrics.length - 1 ||
              _currentPosition < _lyrics[i + 1].startTime)) {
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
