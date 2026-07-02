part of '../media_service.dart';

class LinuxMediaService extends MediaService implements MediaController {
  final DBusClient _client = DBusClient.session();
  String? _cachedPlayerBusName;
  DateTime? _lastDiscoveryTime;
  static const _discoveryInterval = Duration(seconds: 2);
  static const _dbusTimeout = Duration(milliseconds: 500);
  static const Duration _activePollInterval = Duration(milliseconds: 250);
  static const Duration _idlePollInterval = Duration(seconds: 1);
  static const Duration _disconnectedPollInterval = Duration(seconds: 2);

  Timer? _pollTimer;
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();
  String? _currentTrackId;
  String? _lastActivePlayerBusName;
  bool _isUpdating = false;
  bool _isPolling = false;
  int _pollSession = 0;

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
    _pollSession++;
    _isPolling = true;
    _scheduleNextPoll(Duration.zero, _pollSession);
  }

  @override
  void stopPolling() {
    _pollSession++;
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _scheduleNextPoll(Duration delay, int session) {
    if (!_isPolling || session != _pollSession) return;
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, () => _updateState(session));
  }

  Duration _nextPollDelay({
    required bool hasMetadata,
    required bool isPlaying,
  }) {
    if (!hasMetadata) return _disconnectedPollInterval;
    return isPlaying ? _activePollInterval : _idlePollInterval;
  }

  Future<void> _updateState(int session) async {
    if (session != _pollSession) {
      return;
    }
    if (_isUpdating) {
      return;
    }

    _isUpdating = true;
    var nextPollDelay = _nextPollDelay(
      hasMetadata: _metadata != null,
      isPlaying: _status.isPlaying,
    );
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) {
        nextPollDelay = _disconnectedPollInterval;
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
        List<String> artist = ['Unknown Artist'];
        if (artistValue is DBusArray) {
          artist = artistValue.children.map((e) => e.asString()).toList();
        } else if (artistValue != null) {
          artist = [artistValue.asString()];
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
        if (duration.inSeconds == 0) {
          return;
        }

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
      nextPollDelay = _nextPollDelay(
        hasMetadata: newMetadata != null,
        isPlaying: newStatus.isPlaying,
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
    } finally {
      _isUpdating = false;
      _scheduleNextPoll(nextPollDelay, session);
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
        } catch (e) {
          // ignore
        }
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
          _lastActivePlayerBusName = player;
          break;
        }
      }

      final lastActivePlayer = _lastActivePlayerBusName;
      _cachedPlayerBusName =
          bestFound ??
          (lastActivePlayer != null && validPlayers.contains(lastActivePlayer)
              ? lastActivePlayer
              : validPlayers.first);
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
        _currentTrackId!.isEmpty) {
      return;
    }

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
