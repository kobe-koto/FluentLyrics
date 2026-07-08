part of '../media_service.dart';

class MacOSMediaService extends MediaService implements MediaController {
  static const MethodChannel _channel = MethodChannel(
    'cc.koto.fluent_lyrics/media',
  );
  static const EventChannel _eventsChannel = EventChannel(
    'cc.koto.fluent_lyrics/media_events',
  );
  static const Duration _positionTickInterval = Duration(milliseconds: 250);
  static const Duration _fallbackRefreshInterval = Duration(seconds: 5);
  static const Duration _disconnectedPollInterval = Duration(seconds: 2);
  static const Duration _seekConfirmationTimeout = Duration(seconds: 2);
  static const Duration _seekConfirmationTolerance = Duration(seconds: 2);

  StreamSubscription<dynamic>? _eventSubscription;
  Timer? _fallbackTimer;
  Timer? _positionTimer;
  Timer? _seekConfirmationTimer;
  MediaMetadata? _metadata;
  MediaPlaybackStatus _status = MediaPlaybackStatus.empty();
  MediaControlAbility _controlAbility = MediaControlAbility.none();
  bool _isUpdating = false;
  bool _isPolling = false;
  int _pollSession = 0;
  DateTime? _positionAnchorTime;
  Duration _positionAnchor = Duration.zero;
  Duration? _pendingSeekTarget;

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
    _eventSubscription?.cancel();
    _eventSubscription = _eventsChannel.receiveBroadcastStream().listen(
      (event) {
        if (!_isPolling || session != _pollSession) return;
        _applyStatusResult(
          event,
          isSeekConfirmationEvent: _isSeekConfirmationEvent(event),
        );
      },
      onError: (Object error) {
        AppLogger.debug('macOS media event stream failed: $error');
      },
    );
    _refreshState(session);
  }

  @override
  void stopPolling() {
    _pollSession++;
    _isPolling = false;
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _clearPendingSeek();
    _stopPositionTicker();
  }

  void _scheduleFallbackRefresh(Duration delay, int session) {
    if (!_isPolling || session != _pollSession) return;
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(delay, () => _refreshState(session));
  }

  Duration _nextFallbackDelay({required bool hasMetadata}) {
    return hasMetadata ? _fallbackRefreshInterval : _disconnectedPollInterval;
  }

  Future<void> _refreshState(int session) async {
    if (session != _pollSession) {
      return;
    }
    if (_isUpdating) {
      return;
    }

    _isUpdating = true;
    try {
      final Map? result = await _channel.invokeMethod('getStatus');
      _applyStatusResult(result);
    } catch (e) {
      AppLogger.debug('Failed to get macOS media info: $e');
    } finally {
      _isUpdating = false;
      _scheduleFallbackRefresh(
        _nextFallbackDelay(hasMetadata: _metadata != null),
        session,
      );
    }
  }

  void _applyStatusResult(
    dynamic result, {
    bool isSeekConfirmationEvent = false,
  }) {
    if (result == null) {
      _clearPendingSeek();
      _stopPositionTicker();
      if (_metadata != null || _status != MediaPlaybackStatus.empty()) {
        _metadata = null;
        _status = MediaPlaybackStatus.empty();
        _controlAbility = MediaControlAbility.none();
        _positionAnchor = Duration.zero;
        _positionAnchorTime = null;
        notifyListeners();
      }
      return;
    }

    final resultMap = result as Map;
    final metadataMap = resultMap['metadata'] as Map?;
    MediaMetadata? newMetadata;
    if (metadataMap != null) {
      final rawArtist = metadataMap['artist'];
      List<String> artist = ['Unknown Artist'];
      if (rawArtist is String && rawArtist.isNotEmpty) {
        artist = [rawArtist];
      } else if (rawArtist is List) {
        artist = rawArtist.map((e) => e.toString()).toList();
      }

      final rawDuration = metadataMap['duration'];
      final durationMs = rawDuration is num ? rawDuration.toInt() : 0;

      newMetadata = MediaMetadata(
        title: metadataMap['title'] ?? 'Unknown Title',
        artist: artist,
        album: metadataMap['album'] ?? 'Unknown Album',
        duration: Duration(milliseconds: durationMs),
        artUrl:
            (metadataMap['artUrl'] == null ||
                (metadataMap['artUrl'] as String).isEmpty)
            ? 'fallback'
            : metadataMap['artUrl'],
      );
    }

    final abilityMap = resultMap['controlAbility'] as Map?;
    final rawPosition = resultMap['position'];
    final positionMs = rawPosition is num ? rawPosition.toInt() : 0;
    var newStatus = MediaPlaybackStatus(
      isPlaying: resultMap['isPlaying'] ?? false,
      position: Duration(milliseconds: positionMs),
    );
    final newAbility = abilityMap != null
        ? MediaControlAbility(
            canPlayPause: abilityMap['canPlayPause'] ?? false,
            canGoNext: abilityMap['canGoNext'] ?? false,
            canGoPrevious: abilityMap['canGoPrevious'] ?? false,
            canSeek: abilityMap['canSeek'] ?? false,
          )
        : MediaControlAbility.none();

    final pendingSeekTarget = _pendingSeekTarget;
    final trackChanged =
        _metadata != null &&
        newMetadata != null &&
        !newMetadata.isSameTrack(_metadata);
    if (trackChanged) {
      _clearPendingSeek();
    } else if (pendingSeekTarget != null) {
      if (isSeekConfirmationEvent &&
          _isPositionNear(newStatus.position, pendingSeekTarget)) {
        _clearPendingSeek();
      } else {
        newStatus = MediaPlaybackStatus(
          isPlaying: newStatus.isPlaying,
          position: pendingSeekTarget,
        );
      }
    }

    if (_pendingSeekTarget != null) {
      _positionAnchor = newStatus.position;
      _positionAnchorTime = null;
      _stopPositionTicker();
    } else {
      final now = DateTime.now();
      final interpolated = (_positionAnchorTime != null && _status.isPlaying)
          ? _positionAnchor + now.difference(_positionAnchorTime!)
          : newStatus.position;
      final isSmallBackward = newStatus.isPlaying &&
          newStatus.position < interpolated &&
          (interpolated - newStatus.position) <=
              const Duration(seconds: 1) &&
          !trackChanged;
      if (isSmallBackward) {
        newStatus = MediaPlaybackStatus(
          isPlaying: newStatus.isPlaying,
          position: interpolated,
        );
      }
      _positionAnchor = newStatus.position;
      _positionAnchorTime = now;
      if (newStatus.isPlaying && newMetadata != null) {
        _startPositionTicker();
      } else {
        _stopPositionTicker();
      }
    }

    if (_metadata != newMetadata ||
        _status != newStatus ||
        _controlAbility != newAbility) {
      _metadata = newMetadata;
      _status = newStatus;
      _controlAbility = newAbility;
      notifyListeners();
    }
  }

  void _startPositionTicker() {
    _positionTimer ??= Timer.periodic(_positionTickInterval, (_) {
      if (_pendingSeekTarget != null) return;
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

  bool _isSeekConfirmationEvent(dynamic event) {
    return event is Map && event['event'] == 'adapterStream';
  }

  bool _isPositionNear(Duration position, Duration target) {
    final delta = position - target;
    return delta.abs() <= _seekConfirmationTolerance;
  }

  void _holdSeekPosition(Duration position) {
    final metadata = _metadata;
    final clampedPosition =
        metadata != null &&
            metadata.duration > Duration.zero &&
            position > metadata.duration
        ? metadata.duration
        : position;
    _pendingSeekTarget = clampedPosition;
    _positionAnchor = clampedPosition;
    _positionAnchorTime = null;
    _status = MediaPlaybackStatus(
      isPlaying: _status.isPlaying,
      position: clampedPosition,
    );
    _stopPositionTicker();
    _seekConfirmationTimer?.cancel();
    _seekConfirmationTimer = Timer(_seekConfirmationTimeout, () {
      _clearPendingSeek();
      if (_isPolling) {
        _refreshState(_pollSession);
      }
    });
    notifyListeners();
  }

  void _clearPendingSeek() {
    _pendingSeekTarget = null;
    _seekConfirmationTimer?.cancel();
    _seekConfirmationTimer = null;
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
    _holdSeekPosition(position);
    try {
      final didSeek = await _channel.invokeMethod<bool>('seek', {
        'position': position.inMilliseconds,
      });
      if (didSeek == true) return;

      _clearPendingSeek();
      if (_isPolling) {
        await _refreshState(_pollSession);
      }
    } catch (_) {
      _clearPendingSeek();
      if (_isPolling) {
        await _refreshState(_pollSession);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _fallbackTimer?.cancel();
    _clearPendingSeek();
    _stopPositionTicker();
    super.dispose();
  }
}
