import 'package:isar/isar.dart';
import 'lyric_model.dart';

part 'lyric_cache.g.dart';

@Collection()
class LyricCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  late bool isSynced;
  String? writtenBy;
  String? contributor;
  String? copyright;
  String? artworkUrl;
  late bool isPureMusic;

  late List<LyricItem> lyrics;

  LyricsResult toLyricsResult() {
    return LyricsResult(
      lyrics: lyrics
          .map(
            (l) => Lyric(
              startTime: Duration(milliseconds: l.startTimeMs),
              text: l.text,
            ),
          )
          .toList(),
      source: source,
      isSynced: isSynced,
      writtenBy: writtenBy,
      contributor: contributor,
      copyright: copyright,
      artworkUrl: artworkUrl,
      isPureMusic: isPureMusic,
    );
  }

  static LyricCache fromLyricsResult(String cacheId, LyricsResult result) {
    final cache = LyricCache();
    cache.cacheId = cacheId;
    cache.source = result.source;
    cache.isSynced = result.isSynced;
    cache.writtenBy = result.writtenBy;
    cache.contributor = result.contributor;
    cache.copyright = result.copyright;
    cache.artworkUrl = result.artworkUrl;
    cache.isPureMusic = result.isPureMusic;
    cache.lyrics = result.lyrics
        .map(
          (l) => LyricItem()
            ..startTimeMs = l.startTime.inMilliseconds
            ..text = l.text,
        )
        .toList();
    return cache;
  }
}

@embedded
class LyricItem {
  late int startTimeMs;
  late String text;
}
