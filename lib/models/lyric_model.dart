class Lyric {
  final Duration startTime;
  final String text;

  Lyric({required this.startTime, required this.text});
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
}
