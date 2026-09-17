import '../models/lyric_model.dart';
import 'lrc_parser.dart';
import 'rich_lrc_parser.dart';

/// Extracts the kanji/kana reading tracks providers ship next to the lyrics.
///
/// Providers do not label these consistently: NetEase returns separate
/// `klyric` (kana) and `romalrc` (romanized) tracks in its lyric payload, while
/// QQ returns a romanized track and hides a word level kana payload inside a
/// `[kana:...]` metadata line of the lyrics themselves.
class LyricsReadingHelper {
  const LyricsReadingHelper._();

  /// Reads NetEase's `klyric` / `romalrc` sub-objects. The kana track wins when
  /// both are present; `romalrc` is what NetEase actually serves for most
  /// songs (its `klyric` is usually empty).
  static LyricsReading? fromNeteasePayload(Map<String, dynamic> lyricData) {
    final kana = (lyricData['klyric'] as Map?)?['lyric'] as String?;
    if (kana != null && kana.trim().isNotEmpty) {
      final lines = _parseLrc(kana);
      if (lines.isNotEmpty) {
        return LyricsReading(lineType: LyricsReadingType.kana, lines: lines);
      }
    }

    final romaji = (lyricData['romalrc'] as Map?)?['lyric'] as String?;
    if (romaji != null && romaji.trim().isNotEmpty) {
      final lines = _parseLrc(romaji);
      if (lines.isNotEmpty) {
        return LyricsReading(lineType: LyricsReadingType.romaji, lines: lines);
      }
    }

    return null;
  }

  /// Reads QQ's decoded lyric payload: the romanized track plus the word level
  /// kana data embedded in a `[kana:...]` line of the lyric track.
  static LyricsReading? fromQqPayload({String? lyric, String? roma}) {
    final kanaRaw = extractQqKanaMetadata(lyric);
    final lines = _parseRichOrLrc(roma);
    if (lines.isEmpty && kanaRaw == null) return null;
    return LyricsReading(
      lineType: lines.isEmpty ? null : LyricsReadingType.romaji,
      lines: lines,
      kanaRaw: kanaRaw,
    );
  }

  /// QQ stores per-word kana readings in a single `[kana:...]` metadata line.
  static String? extractQqKanaMetadata(String? lyricPayload) {
    if (lyricPayload == null || lyricPayload.isEmpty) return null;
    for (final rawLine in lyricPayload.split('\n')) {
      final line = rawLine.trim();
      if (!line.startsWith('[kana:')) continue;
      final end = line.lastIndexOf(']');
      final value = end > '[kana:'.length
          ? line.substring('[kana:'.length, end)
          : '';
      if (value.trim().isEmpty) return null;
      return value;
    }
    return null;
  }

  /// QQ serves word level payloads (`[startMs,durationMs](wordMs,dur)...`),
  /// while NetEase's tracks are plain LRC.
  static List<Lyric> _parseRichOrLrc(String? content) {
    if (content == null || content.trim().isEmpty) return const [];
    final rich = QQRichParser.parse(content);
    if (rich.isNotEmpty) return rich;
    return _parseLrc(content);
  }

  static List<Lyric> _parseLrc(String content) => LrcParser.parse(
    content,
  ).lyrics.where((l) => l.text.trim().isNotEmpty).toList();

  /// Pairs [lyrics] with the provider's [readingLines].
  ///
  /// Timestamps are the primary signal, but providers rarely agree exactly:
  /// QQ serves the reading track from the word level (QRC) payload while the
  /// lyrics can come from the line level one, which shifts line starts by tens
  /// to hundreds of milliseconds. So: exact timestamp, then nearest within
  /// [tolerance], then positional when both tracks have the same line count.
  /// Returns null for lines that stay unpaired.
  static List<String?> pairReadings(
    List<Lyric> lyrics,
    List<Lyric> readingLines, {
    int toleranceMs = 500,
  }) {
    if (lyrics.isEmpty || readingLines.isEmpty) {
      return List<String?>.filled(lyrics.length, null);
    }

    final byTime = <int, String>{
      for (final line in readingLines)
        line.startTime.inMilliseconds: line.text.trim(),
    };
    final sortedTimes = byTime.keys.toList()..sort();
    final positional = lyrics.length == readingLines.length;

    return [
      for (var i = 0; i < lyrics.length; i++)
        _readingsFor(
          lyrics[i],
          byTime,
          sortedTimes,
          toleranceMs,
          positional ? readingLines[i].text.trim() : null,
        ),
    ];
  }

  static String? _readingsFor(
    Lyric lyric,
    Map<int, String> byTime,
    List<int> sortedTimes,
    int toleranceMs,
    String? positional,
  ) {
    final ms = lyric.startTime.inMilliseconds;
    final exact = byTime[ms];
    if (exact != null && exact.isNotEmpty) return exact;

    final nearest = _nearestTime(sortedTimes, ms, toleranceMs);
    if (nearest != null) {
      final value = byTime[nearest];
      if (value != null && value.isNotEmpty) return value;
    }

    return (positional != null && positional.isNotEmpty) ? positional : null;
  }

  static int? _nearestTime(List<int> times, int ms, int toleranceMs) {
    int? best;
    var bestDelta = toleranceMs + 1;
    for (final time in times) {
      final delta = (time - ms).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = time;
      }
    }
    return bestDelta <= toleranceMs ? best : null;
  }
}
