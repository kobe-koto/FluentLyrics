part of '../media_service.dart';

class LinuxMediaService extends MediaService implements MediaController {
  final DBusClient _client = DBusClient.session();
  String? _cachedPlayerBusName;
  DateTime? _lastDiscoveryTime;
  static const _mprisBusNamePrefix = 'org.mpris.MediaPlayer2.';
  static const _discoveryInterval = Duration(seconds: 2);
  static const _dbusTimeout = Duration(milliseconds: 500);
  static const Duration _startupRefreshDelay = Duration(milliseconds: 10);
  static const Duration _positionTickInterval = Duration(milliseconds: 250);
  static const Duration _fallbackRefreshInterval = Duration(seconds: 10);
  static const Duration _disconnectedPollInterval = Duration(seconds: 2);

  Timer? _fallbackTimer;
  Timer? _positionTimer;
  StreamSubscription<DBusNameOwnerChangedEvent>? _nameOwnerSubscription;
  final Map<String, StreamSubscription<DBusPropertiesChangedSignal>>
  _playerPropertySubscriptions = {};
  final Map<String, StreamSubscription<DBusSignal>> _playerSeekedSubscriptions =
      {};
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();
  String? _currentTrackId;
  String? _lastActivePlayerBusName;
  bool _isUpdating = false;
  bool _isPolling = false;
  int _pollSession = 0;
  DateTime? _positionAnchorTime;
  Duration _positionAnchor = Duration.zero;

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
    final session = _pollSession;
    _nameOwnerSubscription?.cancel();
    _nameOwnerSubscription = _client.nameOwnerChanged.listen((event) {
      if (!_isPolling ||
          session != _pollSession ||
          !event.name.startsWith(_mprisBusNamePrefix)) {
        return;
      }
      _cachedPlayerBusName = null;
      _lastDiscoveryTime = null;
      _refreshPlayerSubscriptions(session);
      _updateState(session);
    });
    _scheduleFallbackRefresh(_startupRefreshDelay, session);
  }

  @override
  void stopPolling() {
    _pollSession++;
    _isPolling = false;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _nameOwnerSubscription?.cancel();
    _nameOwnerSubscription = null;
    _cancelPlayerSubscriptions();
    _stopPositionTicker();
  }

  void _scheduleFallbackRefresh(Duration delay, int session) {
    if (!_isPolling || session != _pollSession) return;
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(delay, () {
      _refreshPlayerSubscriptions(session);
      _updateState(session);
    });
  }

  Duration _nextFallbackDelay({required bool hasMetadata}) {
    return hasMetadata ? _fallbackRefreshInterval : _disconnectedPollInterval;
  }

  Future<void> _updateState(int session) async {
    if (session != _pollSession) {
      return;
    }
    if (_isUpdating) {
      return;
    }

    _isUpdating = true;
    try {
      final playerBusName = await _getBestPlayer();
      if (playerBusName == null) {
        _stopPositionTicker();
        if (_metadata != null || _status != MediaPlaybackStatus.empty()) {
          _metadata = null;
          _status = MediaPlaybackStatus.empty();
          _controlAbility = MediaControlAbility.none();
          _currentTrackId = null;
          _positionAnchor = Duration.zero;
          _positionAnchorTime = null;
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

        final title =
            _unwrapValue(dict['xesam:title'])?.asString() ?? 'Unknown Title';
        final artistValue = _unwrapValue(dict['xesam:artist']);
        List<String> artist = ['Unknown Artist'];
        if (artistValue is DBusArray) {
          artist = artistValue.children.map((e) => e.asString()).toList();
        } else if (artistValue != null) {
          artist = [artistValue.asString()];
        }

        final album =
            _unwrapValue(dict['xesam:album'])?.asString() ?? 'Unknown Album';
        final artUrlValue = _unwrapValue(dict['mpris:artUrl'])?.asString();
        final artUrl = (artUrlValue == null || artUrlValue.isEmpty)
            ? 'fallback'
            : artUrlValue;

        final lengthValue = _unwrapValue(dict['mpris:length']);
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

        newTrackId = _unwrapValue(dict['mpris:trackid'])?.asString();

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

      _positionAnchor = newStatus.position;
      _positionAnchorTime = DateTime.now();
      if (newStatus.isPlaying && newMetadata != null) {
        _startPositionTicker();
      } else {
        _stopPositionTicker();
      }

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
      _scheduleFallbackRefresh(
        _nextFallbackDelay(hasMetadata: _metadata != null),
        session,
      );
    }
  }

  Future<void> _refreshPlayerSubscriptions(int session) async {
    if (!_isPolling || session != _pollSession) return;
    try {
      final names = await _client.listNames().timeout(_dbusTimeout);
      final players = names
          .where((name) => name.startsWith(_mprisBusNamePrefix))
          .toSet();

      final removedPlayers = _playerPropertySubscriptions.keys
          .where((name) => !players.contains(name))
          .toList();
      for (final player in removedPlayers) {
        await _playerPropertySubscriptions.remove(player)?.cancel();
        await _playerSeekedSubscriptions.remove(player)?.cancel();
      }

      for (final player in players) {
        if (_playerPropertySubscriptions.containsKey(player)) continue;
        final object = DBusRemoteObject(
          _client,
          name: player,
          path: DBusObjectPath('/org/mpris/MediaPlayer2'),
        );
        _playerPropertySubscriptions[player] = object.propertiesChanged.listen(
          (signal) => _handlePlayerPropertiesChanged(session, player, signal),
          onError: (_) {
            _playerPropertySubscriptions.remove(player)?.cancel();
            _playerSeekedSubscriptions.remove(player)?.cancel();
            if (_isPolling && session == _pollSession) {
              _cachedPlayerBusName = null;
              _lastDiscoveryTime = null;
              _updateState(session);
            }
          },
        );
        _playerSeekedSubscriptions[player] =
            DBusRemoteObjectSignalStream(
              object: object,
              interface: 'org.mpris.MediaPlayer2.Player',
              name: 'Seeked',
              signature: DBusSignature('x'),
            ).listen(
              (signal) => _handlePlayerSeeked(session, player, signal),
              onError: (_) {
                _playerSeekedSubscriptions.remove(player)?.cancel();
              },
            );
      }
    } catch (_) {
      // Keep the existing fallback refresh alive if the bus is temporarily busy.
    }
  }

  void _handlePlayerPropertiesChanged(
    int session,
    String player,
    DBusPropertiesChangedSignal signal,
  ) {
    if (!_isPolling ||
        session != _pollSession ||
        signal.propertiesInterface != 'org.mpris.MediaPlayer2.Player') {
      return;
    }

    final changed = signal.changedProperties;
    final invalidated = signal.invalidatedProperties;
    const relevantProperties = {
      'Metadata',
      'PlaybackStatus',
      'Position',
      'CanPlay',
      'CanPause',
      'CanGoNext',
      'CanGoPrevious',
      'CanSeek',
    };
    final isRelevant =
        changed.keys.any(relevantProperties.contains) ||
        invalidated.any(relevantProperties.contains);
    if (!isRelevant) return;

    final playbackValue = _unwrapValue(changed['PlaybackStatus']);
    if (playbackValue is DBusString && playbackValue.value == 'Playing') {
      _cachedPlayerBusName = player;
      _lastActivePlayerBusName = player;
      _lastDiscoveryTime = DateTime.now();
    } else if (changed.containsKey('PlaybackStatus') &&
        _cachedPlayerBusName == player) {
      _lastDiscoveryTime = null;
    }

    _updateState(session);
  }

  void _handlePlayerSeeked(int session, String player, DBusSignal signal) {
    if (!_isPolling || session != _pollSession) return;

    if (signal.values.isNotEmpty) {
      final positionValue = _unwrapValue(signal.values.first);
      Duration? position;
      if (positionValue is DBusInt64) {
        position = Duration(microseconds: positionValue.value);
      } else if (positionValue is DBusUint64) {
        position = Duration(microseconds: positionValue.value);
      }

      if (position != null && _cachedPlayerBusName == player) {
        _positionAnchor = position;
        _positionAnchorTime = DateTime.now();
        _status = MediaPlaybackStatus(
          isPlaying: _status.isPlaying,
          position: position,
        );
        notifyListeners();
      }
    }

    _updateState(session);
  }

  void _cancelPlayerSubscriptions() {
    for (final subscription in _playerPropertySubscriptions.values) {
      subscription.cancel();
    }
    _playerPropertySubscriptions.clear();
    for (final subscription in _playerSeekedSubscriptions.values) {
      subscription.cancel();
    }
    _playerSeekedSubscriptions.clear();
  }

  DBusValue? _unwrapValue(DBusValue? value) {
    if (value is DBusVariant) return value.value;
    return value;
  }

  void _startPositionTicker() {
    _positionTimer ??= Timer.periodic(_positionTickInterval, (_) {
      final anchorTime = _positionAnchorTime;
      final metadata = _metadata;
      if (!_status.isPlaying || anchorTime == null || metadata == null) {
        _stopPositionTicker();
        return;
      }

      var position = _positionAnchor + DateTime.now().difference(anchorTime);
      if (metadata.duration > Duration.zero && position > metadata.duration) {
        position = metadata.duration;
      }
      if (position == _status.position) return;

      _status = MediaPlaybackStatus(isPlaying: true, position: position);
      notifyListeners();
    });
  }

  void _stopPositionTicker() {
    _positionTimer?.cancel();
    _positionTimer = null;
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
    _fallbackTimer?.cancel();
    _nameOwnerSubscription?.cancel();
    _cancelPlayerSubscriptions();
    _stopPositionTicker();
    _client.close();
    super.dispose();
  }
}
