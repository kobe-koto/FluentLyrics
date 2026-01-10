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
  @override
  Future<MediaMetadata?> getMetadata() async {
    try {
      final titleResult = await Process.run('playerctl', ['metadata', 'title']);
      final artistResult = await Process.run('playerctl', [
        'metadata',
        'artist',
      ]);
      final albumResult = await Process.run('playerctl', ['metadata', 'album']);
      final durationResult = await Process.run('playerctl', [
        'metadata',
        'mpris:length',
      ]);
      final artUrlResult = await Process.run('playerctl', [
        'metadata',
        'mpris:artUrl',
      ]);

      if (titleResult.exitCode != 0) return null;

      final title = titleResult.stdout.toString().trim();
      final artist = artistResult.stdout.toString().trim();
      final album = albumResult.stdout.toString().trim();

      // playerctl returns length in microseconds
      final rawDuration =
          int.tryParse(durationResult.stdout.toString().trim()) ?? 0;
      final duration = Duration(microseconds: rawDuration);

      final artUrl = artUrlResult.stdout.toString().trim();

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
      final result = await Process.run('playerctl', ['position']);
      if (result.exitCode != 0) return Duration.zero;

      // playerctl returns position in seconds (double)
      final seconds = double.tryParse(result.stdout.toString().trim()) ?? 0.0;
      return Duration(milliseconds: (seconds * 1000).toInt());
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Future<bool> isPlaying() async {
    try {
      final result = await Process.run('playerctl', ['status']);
      return result.stdout.toString().trim().toLowerCase() == 'playing';
    } catch (e) {
      return false;
    }
  }
}
