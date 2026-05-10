import 'package:fluent_lyrics/models/lyric_provider_type.dart';

class Lyric {
  final Duration startTime;
  final Duration? endTime;
  final String text;
  final List<LyricInlinePart>? inlineParts;
  final String? translation;

  Lyric({
    required this.startTime,
    required this.text,
    this.endTime,
    this.inlineParts,
    this.translation,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.inMilliseconds,
    if (endTime != null) 'endTime': endTime!.inMilliseconds,
    'text': text,
    if (inlineParts != null)
      'inlineParts': inlineParts!.map((p) => p.toJson()).toList(),
    if (translation != null) 'translation': translation,
  };

  factory Lyric.fromJson(Map<String, dynamic> json) => Lyric(
    startTime: Duration(milliseconds: json['startTime'] as int),
    endTime: json['endTime'] != null
        ? Duration(milliseconds: json['endTime'] as int)
        : null,
    text: json['text'] as String,
    inlineParts: json['inlineParts'] != null
        ? (json['inlineParts'] as List)
              .map((p) => LyricInlinePart.fromJson(p as Map<String, dynamic>))
              .toList()
        : null,
    translation: json['translation'] as String?,
  );
}

class LyricInlinePart {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricInlinePart({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'text': text,
  };

  factory LyricInlinePart.fromJson(Map<String, dynamic> json) =>
      LyricInlinePart(
        startTime: Duration(milliseconds: json['startTime'] as int),
        endTime: Duration(milliseconds: json['endTime'] as int),
        text: json['text'] as String,
      );
}

class LyricsResult {
  final List<Lyric> lyrics;
  final String source;
  final bool isSynced;
  final bool isRichSync;
  final String? writtenBy;
  final String? composer;
  final String? contributor;
  final String? copyright;
  final bool isPureMusic;
  final Map<String, String>? metadata;
  final List<Map<String, String>>? rawTranslation;
  final List<String>? artworkUrls;

  // Translation fields
  final String? language;
  final bool translation;
  final String? translationProvider;
  final String? translationContributor;
  final LyricProviderType? sourceProvider;

  LyricsResult({
    required this.lyrics,
    required this.source,
    bool? isSynced,
    bool? isRichSync,
    this.writtenBy,
    this.composer,
    this.contributor,
    this.copyright,
    this.isPureMusic = false,
    this.metadata,
    this.language,
    this.translation = false,
    this.translationProvider,
    this.translationContributor,
    this.rawTranslation,
    this.artworkUrls,
    this.sourceProvider,
  }) : isSynced = isSynced ?? _checkIfSynced(lyrics),
       isRichSync = isRichSync ?? _checkIfRichSynced(lyrics);

  LyricsResult trim() {
    if (lyrics.isEmpty) return this;

    List<Lyric> newLyrics = List<Lyric>.from(lyrics);
    bool changed = false;

    // Trim head
    while (newLyrics.isNotEmpty && newLyrics.first.text.trim().isEmpty) {
      newLyrics.removeAt(0);
      changed = true;
    }

    // Trim tail
    while (newLyrics.isNotEmpty && newLyrics.last.text.trim().isEmpty) {
      newLyrics.removeLast();
      changed = true;
    }

    // Merge continuous empty lines
    if (newLyrics.isNotEmpty) {
      final List<Lyric> compacted = [];
      bool lastWasEmpty = false;

      for (final lyric in newLyrics) {
        final isEmpty = lyric.text.trim().isEmpty;
        if (isEmpty) {
          if (!lastWasEmpty) {
            compacted.add(lyric);
            lastWasEmpty = true;
          } else {
            changed = true;
          }
        } else {
          compacted.add(lyric);
          lastWasEmpty = false;
        }
      }
      newLyrics = compacted;
    }

    if (changed) {
      return copyWith(lyrics: newLyrics);
    }
    return this;
  }

  LyricsResult copyWith({
    List<Lyric>? lyrics,
    String? source,
    bool? isSynced,
    bool? isRichSync,
    String? writtenBy,
    String? composer,
    String? contributor,
    String? copyright,
    bool? isPureMusic,
    Map<String, String>? metadata,
    String? language,
    bool? translation,
    String? translationProvider,
    String? translationContributor,
    List<Map<String, String>>? rawTranslation,
    List<String>? artworkUrls,
    LyricProviderType? sourceProvider,
  }) {
    return LyricsResult(
      lyrics: lyrics ?? this.lyrics,
      source: source ?? this.source,
      isSynced: isSynced ?? this.isSynced,
      isRichSync: isRichSync ?? this.isRichSync,
      writtenBy: writtenBy ?? this.writtenBy,
      composer: composer ?? this.composer,
      contributor: contributor ?? this.contributor,
      copyright: copyright ?? this.copyright,
      isPureMusic: isPureMusic ?? this.isPureMusic,
      metadata: metadata ?? this.metadata,
      language: language ?? this.language,
      translation: translation ?? this.translation,
      translationProvider: translationProvider ?? this.translationProvider,
      translationContributor:
          translationContributor ?? this.translationContributor,
      rawTranslation: rawTranslation ?? this.rawTranslation,
      artworkUrls: artworkUrls ?? this.artworkUrls,
      sourceProvider: sourceProvider ?? this.sourceProvider,
    );
  }

  static bool _checkIfSynced(List<Lyric> lyrics) {
    if (lyrics.isEmpty) return false;
    if (lyrics.length == 1) return true;
    for (int i = 1; i < lyrics.length; i++) {
      if (lyrics[i].startTime != lyrics[i - 1].startTime) return true;
    }
    return false;
  }

  static bool _checkIfRichSynced(List<Lyric> lyrics) {
    if (lyrics.isEmpty) return false;
    for (final lyric in lyrics) {
      if (lyric.inlineParts != null && lyric.inlineParts!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static LyricsResult empty() =>
      LyricsResult(lyrics: [], source: '', isSynced: false);

  Map<String, dynamic> toJson() => {
    'lyrics': lyrics.map((l) => l.toJson()).toList(),
    'source': source,
    'isSynced': isSynced,
    'isRichSync': isRichSync,
    'writtenBy': writtenBy,
    'composer': composer,
    'contributor': contributor,
    'copyright': copyright,
    'isPureMusic': isPureMusic,
    if (metadata != null) 'metadata': metadata,
    if (language != null) 'language': language,
    'translation': translation,
    if (translationProvider != null) 'translationProvider': translationProvider,
    if (translationContributor != null)
      'translationContributor': translationContributor,
    if (rawTranslation != null) 'rawTranslation': rawTranslation,
    if (artworkUrls != null) 'artworkUrls': artworkUrls,
    if (sourceProvider != null) 'sourceProvider': sourceProvider!.name,
  };

  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
    lyrics: (json['lyrics'] as List)
        .map((l) => Lyric.fromJson(l as Map<String, dynamic>))
        .toList(),
    source: json['source'] as String,
    isSynced: json['isSynced'] as bool? ?? true,
    isRichSync: json['isRichSync'] as bool? ?? false,
    writtenBy: json['writtenBy'] as String?,
    composer: json['composer'] as String?,
    contributor: json['contributor'] as String?,
    copyright: json['copyright'] as String?,
    isPureMusic: json['isPureMusic'] as bool? ?? false,
    metadata: json['metadata'] != null
        ? Map<String, String>.from(json['metadata'])
        : null,
    language: json['language'] as String?,
    translation: json['translation'] as bool? ?? false,
    translationProvider: json['translationProvider'] as String?,
    translationContributor: json['translationContributor'] as String?,
    rawTranslation: json['rawTranslation'] != null
        ? (json['rawTranslation'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList()
        : null,
    artworkUrls: json['artworkUrls'] != null
        ? List<String>.from(json['artworkUrls'])
        : null,
    sourceProvider: lyricProviderTypeFromName(
      json['sourceProvider'] as String?,
    ),
  );
}
