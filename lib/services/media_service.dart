import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';

import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

part 'media_service_platforms/media_service_linux.dart';
part 'media_service_platforms/media_service_mac.dart';
part 'media_service_platforms/media_service_android.dart';

class MediaMetadata {
  final String title;
  final List<String> artist;
  final String album;
  final Duration duration;
  final String artUrl;

  MediaMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.artUrl,
  });

  MediaMetadata copyWith({
    String? title,
    List<String>? artist,
    String? album,
    Duration? duration,
    String? artUrl,
  }) {
    return MediaMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artUrl: artUrl ?? this.artUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          listEquals(artist, other.artist) &&
          album == other.album &&
          artUrl == other.artUrl;

  @override
  int get hashCode =>
      title.hashCode ^
      Object.hashAll(artist) ^
      album.hashCode ^
      artUrl.hashCode;

  bool isSameTrack(MediaMetadata? other) {
    if (other == null) return false;
    return title == other.title &&
        listEquals(artist, other.artist) &&
        album == other.album &&
        duration.inSeconds == other.duration.inSeconds;
  }
}

class MediaControlAbility {
  final bool canPlayPause;
  final bool canGoNext;
  final bool canGoPrevious;
  final bool canSeek;

  MediaControlAbility({
    required this.canPlayPause,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.canSeek,
  });

  factory MediaControlAbility.none() => MediaControlAbility(
    canPlayPause: false,
    canGoNext: false,
    canGoPrevious: false,
    canSeek: false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaControlAbility &&
          runtimeType == other.runtimeType &&
          canPlayPause == other.canPlayPause &&
          canGoNext == other.canGoNext &&
          canGoPrevious == other.canGoPrevious &&
          canSeek == other.canSeek;

  @override
  int get hashCode =>
      canPlayPause.hashCode ^
      canGoNext.hashCode ^
      canGoPrevious.hashCode ^
      canSeek.hashCode;
}

class MediaPlaybackStatus {
  final bool isPlaying;
  final Duration position;

  MediaPlaybackStatus({required this.isPlaying, required this.position});

  factory MediaPlaybackStatus.empty() =>
      MediaPlaybackStatus(isPlaying: false, position: Duration.zero);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaPlaybackStatus &&
          runtimeType == other.runtimeType &&
          isPlaying == other.isPlaying &&
          position == other.position;

  @override
  int get hashCode => isPlaying.hashCode ^ position.hashCode;
}

abstract class MediaController {
  Future<void> play();
  Future<void> pause();
  Future<void> playPause();
  Future<void> nextTrack();
  Future<void> previousTrack();
  Future<void> seek(Duration position);
}

abstract class MediaService extends ChangeNotifier {
  MediaService();

  MediaMetadata? get metadata;
  MediaPlaybackStatus get status;
  MediaControlAbility get controlAbility;
  MediaController get controller;

  void startPolling();
  void stopPolling();
  @override
  void dispose();

  factory MediaService.create() {
    if (Platform.isLinux) {
      return LinuxMediaService();
    } else if (Platform.isAndroid) {
      return AndroidMediaService();
    } else if (Platform.isMacOS) {
      return MacOSMediaService();
    }
    throw UnsupportedError('Platform not supported');
  }
}
