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

  LyricsResult({
    required this.lyrics,
    required this.source,
    bool? isSynced,
    this.writtenBy,
    this.contributor,
    this.copyright,
  }) : isSynced = isSynced ?? _checkIfSynced(lyrics);

  static bool _checkIfSynced(List<Lyric> lyrics) {
    if (lyrics.isEmpty) return false;
    if (lyrics.length == 1) return true;
    for (int i = 1; i < lyrics.length; i++) {
      if (lyrics[i].startTime != lyrics[i - 1].startTime) return true;
    }
    return false;
  }

  static LyricsResult empty() =>
      LyricsResult(lyrics: [], source: '', isSynced: false);

  Map<String, dynamic> toJson() => {
    'lyrics': lyrics.map((l) => l.toJson()).toList(),
    'source': source,
    'isSynced': isSynced,
    'writtenBy': writtenBy,
    'contributor': contributor,
    'copyright': copyright,
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
  );
}
