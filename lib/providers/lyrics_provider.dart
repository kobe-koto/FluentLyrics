import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lyric_model.dart';
import '../data/mock_data.dart';

class LyricsProvider with ChangeNotifier {
  Timer? _timer;
  Duration _currentPosition = Duration.zero;
  int _currentIndex = 0;
  bool _isPlaying = false;

  Duration get currentPosition => _currentPosition;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  List<Lyric> get lyrics => neverGonnaGiveYouUpLyrics;

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    _isPlaying = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _currentPosition += const Duration(milliseconds: 100);
      _updateCurrentIndex();
      notifyListeners();

      if (_currentPosition >= lyrics.last.startTime + const Duration(seconds: 5)) {
        stop();
      }
    });
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _currentPosition = Duration.zero;
    _currentIndex = 0;
    notifyListeners();
  }

  void seek(Duration position) {
    _currentPosition = position;
    _updateCurrentIndex();
    notifyListeners();
  }

  void _updateCurrentIndex() {
    for (int i = 0; i < lyrics.length; i++) {
      if (_currentPosition >= lyrics[i].startTime &&
          (i == lyrics.length - 1 || _currentPosition < lyrics[i + 1].startTime)) {
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
    _timer?.cancel();
    super.dispose();
  }
}
