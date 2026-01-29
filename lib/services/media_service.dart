import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

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
    }
    throw UnsupportedError('Platform not supported');
  }
}

class LinuxMediaService extends MediaService implements MediaController {
  final DBusClient _client = DBusClient.session();
  String? _cachedPlayerBusName;
  DateTime? _lastDiscoveryTime;
  static const _discoveryInterval = Duration(seconds: 2);
  static const _dbusTimeout = Duration(milliseconds: 500);

  Timer? _pollTimer;
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();
  String? _currentTrackId;

  @override
  MediaMetadata? get metadata => _metadata;
  @override
  MediaPlaybackStatus get status => _status;
  @override
  MediaControlAbility get controlAbility => _controlAbility;
  @override
  MediaController get controller => this;

  @override
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _updateState(),
    );
    _updateState();
  }

  @override
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _updateState() async {
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) {
        if (_metadata != null || _status != MediaPlaybackStatus.empty()) {
          _metadata = null;
          _status = MediaPlaybackStatus.empty();
          _controlAbility = MediaControlAbility.none();
          _currentTrackId = null;
          notifyListeners();
        }
        return;
      }

      final object = DBusRemoteObject(
        _client,
        name: playerBusName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );

      final properties = await object
          .getAllProperties('org.mpris.MediaPlayer2.Player')
          .timeout(_dbusTimeout);

      final metadataValue = properties['Metadata'];
      MediaMetadata? newMetadata;
      String? newTrackId;

      if (metadataValue is DBusDict) {
        final dict = metadataValue.children.map(
          (key, value) => MapEntry(key.asString(), value),
        );

        DBusValue? unwrap(DBusValue? v) {
          if (v is DBusVariant) return v.value;
          return v;
        }

        final title =
            unwrap(dict['xesam:title'])?.asString() ?? 'Unknown Title';
        final artistValue = unwrap(dict['xesam:artist']);
        String artist = 'Unknown Artist';
        if (artistValue is DBusArray) {
          artist = artistValue.children.map((e) => e.asString()).join(', ');
        } else if (artistValue != null) {
          artist = artistValue.asString();
        }

        final album =
            unwrap(dict['xesam:album'])?.asString() ?? 'Unknown Album';
        final artUrlValue = unwrap(dict['mpris:artUrl'])?.asString();
        final artUrl = (artUrlValue == null || artUrlValue.isEmpty)
            ? 'fallback'
            : artUrlValue;

        final lengthValue = unwrap(dict['mpris:length']);
        int length = 0;
        if (lengthValue is DBusUint64) {
          length = lengthValue.value;
        } else if (lengthValue is DBusInt64) {
          length = lengthValue.value;
        }
        final duration = Duration(microseconds: length);

        newTrackId = unwrap(dict['mpris:trackid'])?.asString();

        newMetadata = MediaMetadata(
          title: title,
          artist: artist,
          album: album,
          duration: duration,
          artUrl: artUrl,
        );
      }

      final playbackStatus =
          properties['PlaybackStatus']?.asString() ?? 'Stopped';
      final isPlaying = playbackStatus == 'Playing';

      final posValue = properties['Position'];
      Duration position = Duration.zero;
      DBusValue? p = posValue;
      if (p is DBusVariant) p = p.value;
      if (p is DBusInt64) {
        position = Duration(microseconds: p.value);
      } else if (p is DBusUint64) {
        position = Duration(microseconds: p.value);
      }

      final canPlay = properties['CanPlay']?.asBoolean() ?? false;
      final canPause = properties['CanPause']?.asBoolean() ?? false;
      final canGoNext = properties['CanGoNext']?.asBoolean() ?? false;
      final canGoPrevious = properties['CanGoPrevious']?.asBoolean() ?? false;
      final canSeek = properties['CanSeek']?.asBoolean() ?? false;

      final newStatus = MediaPlaybackStatus(
        isPlaying: isPlaying,
        position: position,
      );
      final newAbility = MediaControlAbility(
        canPlayPause: canPlay || canPause,
        canGoNext: canGoNext,
        canGoPrevious: canGoPrevious,
        canSeek: canSeek,
      );

      bool changed = false;
      if (_metadata != newMetadata) {
        _metadata = newMetadata;
        changed = true;
      }
      if (_status != newStatus) {
        _status = newStatus;
        changed = true;
      }
      if (_controlAbility != newAbility) {
        _controlAbility = newAbility;
        changed = true;
      }
      if (_currentTrackId != newTrackId) {
        _currentTrackId = newTrackId;
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      _cachedPlayerBusName = null;
    }
  }

  Future<String?> _getBestPlayer() async {
    final now = DateTime.now();
    if (_cachedPlayerBusName != null &&
        _lastDiscoveryTime != null &&
        now.difference(_lastDiscoveryTime!) < _discoveryInterval) {
      return _cachedPlayerBusName;
    }

    try {
      final names = await _client.listNames().timeout(_dbusTimeout);
      final players = names
          .where((n) => n.startsWith('org.mpris.MediaPlayer2.'))
          .toList();
      if (players.isEmpty) {
        _cachedPlayerBusName = null;
        return null;
      }

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
        } catch (e) {}
      }

      if (validPlayers.isEmpty) {
        _cachedPlayerBusName = null;
        return null;
      }

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
      return _cachedPlayerBusName;
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
  Future<void> play() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return;
    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'Play',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> pause() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return;
    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'Pause',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> playPause() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return;
    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'PlayPause',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> nextTrack() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return;
    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'Next',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> previousTrack() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return;
    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'Previous',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null ||
        _currentTrackId == null ||
        _currentTrackId!.isEmpty)
      return;

    final object = DBusRemoteObject(
      _client,
      name: playerBusName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    await object.callMethod(
      'org.mpris.MediaPlayer2.Player',
      'SetPosition',
      [DBusObjectPath(_currentTrackId!), DBusInt64(position.inMicroseconds)],
      replySignature: DBusSignature(''),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _client.close();
    super.dispose();
  }
}

class AndroidMediaService extends MediaService implements MediaController {
  static const MethodChannel _channel = MethodChannel(
    'cc.koto.fluent_lyrics/media',
  );

  Timer? _pollTimer;
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();

  @override
  MediaMetadata? get metadata => _metadata;
  @override
  MediaPlaybackStatus get status => _status;
  @override
  MediaControlAbility get controlAbility => _controlAbility;
  @override
  MediaController get controller => this;

  @override
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _updateState(),
    );
    _updateState();
  }

  @override
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _updateState() async {
    try {
      final Map? result = await _channel.invokeMethod('getStatus');
      if (result == null) {
        if (_metadata != null || _status != MediaPlaybackStatus.empty()) {
          _metadata = null;
          _status = MediaPlaybackStatus.empty();
          _controlAbility = MediaControlAbility.none();
          notifyListeners();
        }
        return;
      }

      final metadataMap = result['metadata'] as Map?;
      MediaMetadata? newMetadata;
      if (metadataMap != null) {
        newMetadata = MediaMetadata(
          title: metadataMap['title'] ?? 'Unknown Title',
          artist: metadataMap['artist'] ?? 'Unknown Artist',
          album: metadataMap['album'] ?? 'Unknown Album',
          duration: Duration(milliseconds: metadataMap['duration'] ?? 0),
          artUrl:
              (metadataMap['artUrl'] == null ||
                  (metadataMap['artUrl'] as String).isEmpty)
              ? 'fallback'
              : metadataMap['artUrl'],
        );
      }

      final abilityMap = result['controlAbility'] as Map?;
      final isPlaying = result['isPlaying'] ?? false;
      final position = Duration(milliseconds: result['position'] ?? 0);

      final newStatus = MediaPlaybackStatus(
        isPlaying: isPlaying,
        position: position,
      );
      final newAbility = abilityMap != null
          ? MediaControlAbility(
              canPlayPause: abilityMap['canPlayPause'] ?? false,
              canGoNext: abilityMap['canGoNext'] ?? false,
              canGoPrevious: abilityMap['canGoPrevious'] ?? false,
              canSeek: abilityMap['canSeek'] ?? false,
            )
          : MediaControlAbility.none();

      if (_metadata != newMetadata ||
          _status != newStatus ||
          _controlAbility != newAbility) {
        _metadata = newMetadata;
        _status = newStatus;
        _controlAbility = newAbility;
        notifyListeners();
      }
    } catch (e) {}
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> playPause() async {
    await _channel.invokeMethod('playPause');
  }

  @override
  Future<void> nextTrack() async {
    await _channel.invokeMethod('nextTrack');
  }

  @override
  Future<void> previousTrack() async {
    await _channel.invokeMethod('previousTrack');
  }

  @override
  Future<void> seek(Duration position) async {
    await _channel.invokeMethod('seek', {'position': position.inMilliseconds});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<bool> checkPermission() async {
    return await _channel.invokeMethod('checkPermission');
  }

  Future<void> openSettings() async {
    await _channel.invokeMethod('openPermissionSettings');
  }
}
