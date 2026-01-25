class Lyric {
  final Duration startTime;
  final String text;

  Lyric({required this.startTime, required this.text});

  Map<String, dynamic> toJson() => {
    'startTime': startTime.inMilliseconds,
    'text': text,
  };

  factory Lyric.fromJson(Map<String, dynamic> json) => Lyric(
    startTime: Duration(milliseconds: json['startTime'] as int),
    text: json['text'] as String,
  );
}

class LyricsResult {
  final List<Lyric> lyrics;
  final String source;
  final bool isSynced;
  final String? writtenBy;
  final String? contributor;
  final String? copyright;
  final String? artworkUrl;
  final bool isPureMusic;

  LyricsResult({
    required this.lyrics,
    required this.source,
    bool? isSynced,
    this.writtenBy,
    this.contributor,
    this.copyright,
    this.artworkUrl,
    this.isPureMusic = false,
  }) : isSynced = isSynced ?? _checkIfSynced(lyrics);

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
    String? writtenBy,
    String? contributor,
    String? copyright,
    String? artworkUrl,
    bool? isPureMusic,
  }) {
    return LyricsResult(
      lyrics: lyrics ?? this.lyrics,
      source: source ?? this.source,
      isSynced: isSynced ?? this.isSynced,
      writtenBy: writtenBy ?? this.writtenBy,
      contributor: contributor ?? this.contributor,
      copyright: copyright ?? this.copyright,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      isPureMusic: isPureMusic ?? this.isPureMusic,
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

  static LyricsResult empty() =>
      LyricsResult(lyrics: [], source: '', isSynced: false, artworkUrl: null);

  Map<String, dynamic> toJson() => {
    'lyrics': lyrics.map((l) => l.toJson()).toList(),
    'source': source,
    'isSynced': isSynced,
    'writtenBy': writtenBy,
    'contributor': contributor,
    'copyright': copyright,
    'artworkUrl': artworkUrl,
    'isPureMusic': isPureMusic,
  };

  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
    lyrics: (json['lyrics'] as List)
        .map((l) => Lyric.fromJson(l as Map<String, dynamic>))
        .toList(),
    source: json['source'] as String,
    isSynced: json['isSynced'] as bool? ?? true,
    writtenBy: json['writtenBy'] as String?,
    contributor: json['contributor'] as String?,
    copyright: json['copyright'] as String?,
    artworkUrl: json['artworkUrl'] as String?,
    isPureMusic: json['isPureMusic'] as bool? ?? false,
  );
}
