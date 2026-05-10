import 'package:isar_community/isar.dart';
import 'lyric_model.dart';
import 'lyric_provider_type.dart';

part 'lyric_cache.g.dart';

@Collection()
class LyricCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  String? sourceProvider;
  late bool isSynced;
  late bool isRichSync;
  String? writtenBy;
  String? composer;
  String? contributor;
  String? copyright;
  List<String>? artworkUrls;
  late bool isPureMusic;
  late List<LyricItem> lyrics;

  LyricsResult toLyricsResult() {
    return LyricsResult(
      lyrics: lyrics
          .map(
            (l) => Lyric(
              startTime: Duration(milliseconds: l.startTimeMs),
              endTime: l.endTimeMs != null
                  ? Duration(milliseconds: l.endTimeMs!)
                  : null,
              text: l.text,
              inlineParts: l.inlineParts
                  ?.map(
                    (p) => LyricInlinePart(
                      startTime: Duration(milliseconds: p.startTimeMs),
                      endTime: Duration(milliseconds: p.endTimeMs),
                      text: p.text,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      source: source,
      sourceProvider:
          lyricProviderTypeFromName(sourceProvider) ??
          lyricProviderTypeFromSource(source),
      isSynced: isSynced,
      isRichSync: isRichSync,
      writtenBy: writtenBy,
      composer: composer,
      contributor: contributor,
      copyright: copyright,
      isPureMusic: isPureMusic,
      artworkUrls: artworkUrls,
    );
  }

  static LyricCache fromLyricsResult(String cacheId, LyricsResult result) {
    final cache = LyricCache();
    cache.cacheId = cacheId;
    cache.source = result.source;
    cache.sourceProvider = result.sourceProvider?.name;
    cache.isSynced = result.isSynced;
    cache.isRichSync = result.isRichSync;
    cache.writtenBy = result.writtenBy;
    cache.composer = result.composer;
    cache.contributor = result.contributor;
    cache.copyright = result.copyright;
    cache.isPureMusic = result.isPureMusic;
    cache.artworkUrls = result.artworkUrls;
    cache.lyrics = result.lyrics
        .map(
          (l) => LyricItem()
            ..startTimeMs = l.startTime.inMilliseconds
            ..endTimeMs = l.endTime?.inMilliseconds
            ..text = l.text
            ..inlineParts = l.inlineParts
                ?.map(
                  (p) => LyricItemInlinePart()
                    ..startTimeMs = p.startTime.inMilliseconds
                    ..endTimeMs = p.endTime.inMilliseconds
                    ..text = p.text,
                )
                .toList(),
        )
        .toList();
    return cache;
  }
}

@Collection()
class TranslationCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheId;

  late String source;
  String? sourceProvider;
  late String translationProvider;
  late String? translationContributor;
  late String language;
  late List<TranslationItem> lyrics;
  late List<RawTranslationPair>? rawTranslation;

  LyricsResult toLyricsResult() {
    return LyricsResult(
      lyrics: lyrics
          .map(
            (l) => Lyric(
              startTime: Duration(milliseconds: l.startTimeMs),
              endTime: l.endTimeMs != null
                  ? Duration(milliseconds: l.endTimeMs!)
                  : null,
              text: l.text,
            ),
          )
          .toList(),
      rawTranslation: rawTranslation
          ?.map(
            (e) => {
              'original': e.original ?? '',
              'translated': e.translated ?? '',
            },
          )
          .toList(),
      source: source,
      sourceProvider: lyricProviderTypeFromName(sourceProvider),
      language: language,
      translation: true,
      translationProvider: translationProvider,
      translationContributor: translationContributor,
    );
  }

  static TranslationCache fromLyricsResult(
    String cacheId,
    LyricsResult result,
  ) {
    return TranslationCache()
      ..cacheId = cacheId
      ..source = result.source
      ..sourceProvider = result.sourceProvider?.name
      ..translationProvider = result.translationProvider ?? 'unknown'
      ..translationContributor = result.translationContributor ?? 'unknown'
      ..language = result.language ?? 'en'
      ..lyrics = result.lyrics
          .map(
            (l) => TranslationItem()
              ..startTimeMs = l.startTime.inMilliseconds
              ..endTimeMs = l.endTime?.inMilliseconds
              ..text = l.text,
          )
          .toList()
      ..rawTranslation = result.rawTranslation
          ?.map(
            (e) => RawTranslationPair()
              ..original = e['original']
              ..translated = e['translated'],
          )
          .toList();
  }
}

@embedded
class RawTranslationPair {
  String? original;
  String? translated;
}

@embedded
class LyricItem {
  late int startTimeMs;
  int? endTimeMs;
  late String text;
  List<LyricItemInlinePart>? inlineParts;
}

@embedded
class LyricItemInlinePart {
  late int startTimeMs;
  late int endTimeMs;
  late String text;
}

@embedded
class TranslationItem {
  late int startTimeMs;
  int? endTimeMs;
  late String text;
}
