import 'package:dbus/dbus.dart';

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
}

abstract class MediaService {
  Future<MediaMetadata?> getMetadata();
  Future<Duration> getPosition();
  Future<bool> isPlaying();
}

class LinuxMediaService implements MediaService {
  final DBusClient _client = DBusClient.session();

  Future<String?> _getBestPlayer() async {
    try {
      // List all available players
      final names = await _client.listNames();
      final players = names
          .where((n) => n.startsWith('org.mpris.MediaPlayer2.'))
          .toList();
      if (players.isEmpty) return null;

      // filter out players that dont have any metadata
      final List<String> validPlayers = [];
      for (final player in players) {
        try {
          final object = DBusRemoteObject(
            _client,
            name: player,
            path: DBusObjectPath('/org/mpris/MediaPlayer2'),
          );
          final metadataValue = await object.getProperty(
            'org.mpris.MediaPlayer2.Player',
            'Metadata',
          );
          if (metadataValue is DBusDict) {
            // if trackid == /org/mpris/MediaPlayer2/TrackList/NoTrack, skip this player
            final trackId = metadataValue
                .asStringVariantDict()['mpris:trackid']
                ?.asString();
            if (trackId != '/org/mpris/MediaPlayer2/TrackList/NoTrack' &&
                trackId != null &&
                trackId.isNotEmpty) {
              validPlayers.add(player);
            }
          }
        } catch (e) {
          // If we can't get metadata, skip this player
        }
      }

      if (validPlayers.isEmpty) return null;

      // Prefer the player that is currently playing
      for (final player in validPlayers) {
        final status = await _getPlaybackStatus(player);
        if (status == 'Playing') return player;
      }

      return validPlayers.first;
    } catch (e) {
      return null;
    }
  }

  Future<String> _getPlaybackStatus(String busName) async {
    try {
      final object = DBusRemoteObject(
        _client,
        name: busName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      final value = await object.getProperty(
        'org.mpris.MediaPlayer2.Player',
        'PlaybackStatus',
      );
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
      final metadataValue = await object.getProperty(
        'org.mpris.MediaPlayer2.Player',
        'Metadata',
      );

      if (metadataValue is! DBusDict) return null;
      final metadata = metadataValue.children.map(
        (key, value) => MapEntry(key.asString(), value),
      );

      // Metadata values are wrapped in Variants (a{sv})
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

      // length is in microseconds (Int64)
      final length = unwrap(metadata['mpris:length'])?.asUint64() ?? 0;
      final duration = Duration(microseconds: length);

      return MediaMetadata(
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        artUrl: artUrl,
      );
    } catch (e) {
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
      final positionValue = await object.getProperty(
        'org.mpris.MediaPlayer2.Player',
        'Position',
      );

      // Position is directly an Int64 property, but getProperty might wrap it?
      // Actually getProperty returns the value directly as the type it is.
      // But if the property itself is a variant... no, Position is 'x'.
      // However, some implementations might be weird.

      DBusValue? unwrap(DBusValue? v) {
        if (v is DBusVariant) return v.value;
        return v;
      }

      return Duration(microseconds: unwrap(positionValue)?.asInt64() ?? 0);
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Future<bool> isPlaying() async {
    final playerBusName = await _getBestPlayer();
    if (playerBusName == null) return false;
    return (await _getPlaybackStatus(playerBusName)) == 'Playing';
  }

  void dispose() {
    _client.close();
  }
}
