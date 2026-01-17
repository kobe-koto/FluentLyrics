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
  final String? writtenBy;
  final String? contributor;
  final String? copyright;

  LyricsResult({
    required this.lyrics,
    required this.source,
    this.writtenBy,
    this.contributor,
    this.copyright,
  });

  static LyricsResult empty() => LyricsResult(lyrics: [], source: '');

  Map<String, dynamic> toJson() => {
    'lyrics': lyrics.map((l) => l.toJson()).toList(),
    'source': source,
    'writtenBy': writtenBy,
    'contributor': contributor,
    'copyright': copyright,
  };

  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
    lyrics: (json['lyrics'] as List)
        .map((l) => Lyric.fromJson(l as Map<String, dynamic>))
        .toList(),
    source: json['source'] as String,
    writtenBy: json['writtenBy'] as String?,
    contributor: json['contributor'] as String?,
    copyright: json['copyright'] as String?,
  );
}
