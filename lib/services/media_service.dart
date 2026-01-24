import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class MediaMetadata {
  final String title;
  final String artist;
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
    String? artist,
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
          artist == other.artist &&
          album == other.album &&
          artUrl == other.artUrl;

  @override
  int get hashCode =>
      title.hashCode ^ artist.hashCode ^ album.hashCode ^ artUrl.hashCode;

  bool isSameTrack(MediaMetadata? other) {
    if (other == null) return false;
    return title == other.title &&
        artist == other.artist &&
        album == other.album &&
        duration.inSeconds == other.duration.inSeconds;
  }
}

abstract class MediaService {
  Future<MediaMetadata?> getMetadata();
  Future<Duration> getPosition();
  Future<bool> isPlaying();
  void dispose();

  factory MediaService() {
    if (Platform.isLinux) {
      return LinuxMediaService();
    } else if (Platform.isAndroid) {
      return AndroidMediaService();
    }
    throw UnsupportedError('Platform not supported');
  }
}

class LinuxMediaService implements MediaService {
  final DBusClient _client = DBusClient.session();
  String? _cachedPlayerBusName;
  DateTime? _lastDiscoveryTime;
  static const _discoveryInterval = Duration(seconds: 2);
  static const _dbusTimeout = Duration(milliseconds: 500);

  Future<String?> _getBestPlayer() async {
    final now = DateTime.now();
    if (_cachedPlayerBusName != null &&
        _lastDiscoveryTime != null &&
        now.difference(_lastDiscoveryTime!) < _discoveryInterval) {
      return _cachedPlayerBusName;
    }

    try {
      // List all available players
      final names = await _client.listNames().timeout(_dbusTimeout);
      final players = names
          .where((n) => n.startsWith('org.mpris.MediaPlayer2.'))
          .toList();
      if (players.isEmpty) {
        _cachedPlayerBusName = null;
        return null;
      }

      // filter out players that dont have any metadata
      final List<String> validPlayers = [];
      for (final player in players) {
        try {
          final object = DBusRemoteObject(
            _client,
            name: player,
            path: DBusObjectPath('/org/mpris/MediaPlayer2'),
          );
          final metadataValue = await object
              .getProperty('org.mpris.MediaPlayer2.Player', 'Metadata')
              .timeout(_dbusTimeout);

          if (metadataValue is DBusDict) {
            final dict = metadataValue.asStringVariantDict();
            final trackId = dict['mpris:trackid']?.asString();
            if (trackId != '/org/mpris/MediaPlayer2/TrackList/NoTrack' &&
                trackId != null &&
                trackId.isNotEmpty) {
              validPlayers.add(player);
            }
          }
        } catch (e) {
          // Skip unresponsive or invalid players
        }
      }

      if (validPlayers.isEmpty) {
        _cachedPlayerBusName = null;
        return null;
      }

      // Prefer the player that is currently playing
      String? bestFound;
      for (final player in validPlayers) {
        final status = await _getPlaybackStatus(player);
        if (status == 'Playing') {
          bestFound = player;
          break;
        }
      }

      _cachedPlayerBusName = bestFound ?? validPlayers.first;
      _lastDiscoveryTime = now;
      return _cachedPlayerBusName;
    } catch (e) {
      return _cachedPlayerBusName; // Return old one on failure if we have it
    }
  }

  Future<String> _getPlaybackStatus(String busName) async {
    try {
      final object = DBusRemoteObject(
        _client,
        name: busName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      final value = await object
          .getProperty('org.mpris.MediaPlayer2.Player', 'PlaybackStatus')
          .timeout(_dbusTimeout);
      return value.asString();
    } catch (e) {
      return 'Stopped';
    }
  }

  @override
  Future<MediaMetadata?> getMetadata() async {
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) return null;

      final object = DBusRemoteObject(
        _client,
        name: playerBusName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      final metadataValue = await object
          .getProperty('org.mpris.MediaPlayer2.Player', 'Metadata')
          .timeout(_dbusTimeout);

      if (metadataValue is! DBusDict) return null;
      final metadata = metadataValue.children.map(
        (key, value) => MapEntry(key.asString(), value),
      );

      DBusValue? unwrap(DBusValue? v) {
        if (v is DBusVariant) return v.value;
        return v;
      }

      final title =
          unwrap(metadata['xesam:title'])?.asString() ?? 'Unknown Title';
      final artistValue = unwrap(metadata['xesam:artist']);
      String artist = 'Unknown Artist';
      if (artistValue is DBusArray) {
        artist = artistValue.children.map((e) => e.asString()).join(', ');
      } else if (artistValue != null) {
        artist = artistValue.asString();
      }

      final album =
          unwrap(metadata['xesam:album'])?.asString() ?? 'Unknown Album';
      final artUrl = unwrap(metadata['mpris:artUrl'])?.asString() ?? '';

      final lengthValue = unwrap(metadata['mpris:length']);
      int length = 0;
      if (lengthValue is DBusUint64) {
        length = lengthValue.value;
      } else if (lengthValue is DBusInt64) {
        length = lengthValue.value;
      }
      final duration = Duration(microseconds: length);

      return MediaMetadata(
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        artUrl: artUrl,
      );
    } catch (e) {
      // If the cached player fails, invalidate it
      _cachedPlayerBusName = null;
      return null;
    }
  }

  @override
  Future<Duration> getPosition() async {
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) return Duration.zero;

      final object = DBusRemoteObject(
        _client,
        name: playerBusName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      final positionValue = await object
          .getProperty('org.mpris.MediaPlayer2.Player', 'Position')
          .timeout(_dbusTimeout);

      DBusValue? unwrap(DBusValue? v) {
        if (v is DBusVariant) return v.value;
        return v;
      }

      final pos = unwrap(positionValue);
      if (pos is DBusInt64) {
        return Duration(microseconds: pos.value);
      } else if (pos is DBusUint64) {
        return Duration(microseconds: pos.value);
      }
      return Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Future<bool> isPlaying() async {
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) return false;
      return (await _getPlaybackStatus(playerBusName)) == 'Playing';
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}

class AndroidMediaService implements MediaService {
  static const MethodChannel _channel = MethodChannel(
    'cc.koto.fluent_lyrics/media',
  );

  @override
  Future<MediaMetadata?> getMetadata() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'getMetadata',
      );
      if (result == null) return null;

      return MediaMetadata(
        title: result['title'] ?? 'Unknown Title',
        artist: result['artist'] ?? 'Unknown Artist',
        album: result['album'] ?? 'Unknown Album',
        duration: Duration(milliseconds: result['duration'] ?? 0),
        artUrl: result['artUrl'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Duration> getPosition() async {
    try {
      final int? position = await _channel.invokeMethod('getPosition');
      return Duration(milliseconds: position ?? 0);
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Future<bool> isPlaying() async {
    try {
      final bool? isPlaying = await _channel.invokeMethod('isPlaying');
      return isPlaying ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    // No specific resources to dispose for Android MethodChannel
  }

  Future<bool> checkPermission() async {
    return await _channel.invokeMethod('checkPermission');
  }

  Future<void> openSettings() async {
    await _channel.invokeMethod('openPermissionSettings');
  }
}
