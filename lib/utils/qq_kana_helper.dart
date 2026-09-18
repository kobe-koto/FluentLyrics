import 'furigana_helper.dart';

/// One entry of QQ's `[kana:...]` payload: [kanjiCount] consecutive kanji of
/// the lyrics are read as [reading].
///
/// The payload is a flat, whole song list of these entries, and the single
/// digit in front of each reading is its kanji count — not a separator. Most
/// entries cover a single kanji (`1よね`), but a compound read as one word
/// covers all of its kanji (`2きょう` is 今日 -> きょう), which is what lets
/// adjacent kanji be annotated separately: `私分からなくて` is 私(わたし) +
/// 分(わ), where a line level reading track can only say わたしわ.
///
/// A run whose reading is empty carries no annotation: QQ emits those for the
/// parts of a line that have no kanji reading (punctuation and latin words).
/// They consume no kanji, so `1し1111きょく` is 詞(し) followed by three of
/// them and 曲(きょく) — the run count of ENDROLL, whose lyrics stay aligned
/// only when the padding is dropped.
class QqKanaRun {
  final int kanjiCount;
  final String reading;

  /// Karaoke start times QQ attached to individual kana of this reading.
  final List<int> timesMs;

  const QqKanaRun({
    required this.kanjiCount,
    required this.reading,
    this.timesMs = const [],
  });

  @override
  String toString() => 'QqKanaRun($kanjiCount -> $reading)';
}

/// A lyric line to annotate, with the timing QQ's payload can be checked
/// against. Both times are optional: without them the alignment falls back to
/// consuming the payload in order.
class QqKanaLine {
  final String text;
  final int? startMs;
  final int? endMs;

  const QqKanaLine(this.text, {this.startMs, this.endMs});
}

/// Aligns QQ's word level kana payload (`[kana:...]`) with the lyric lines.
class QqKanaHelper {
  const QqKanaHelper._();

  static final RegExp _timing = RegExp(r'\((\d+),\d+(?:,\d+)?\)');

  /// Parses the payload into one [QqKanaRun] per reading, dropping the
  /// entries that carry no reading. Returns an empty list when the payload is
  /// not a well formed list of kana readings, so the caller can fall back to
  /// the romanized track.
  static List<QqKanaRun> parseRuns(String kanaRaw) {
    final runs = <QqKanaRun>[];
    var index = 0;

    while (index < kanaRaw.length) {
      final char = kanaRaw[index];
      // Counts are single digits, so consecutive digits are consecutive runs
      // (usually padding entries) and never one large count. A `0` would mean
      // a count of ten or more, which the payload does not use: bail out and
      // let the caller fall back to the romanized track.
      if (char == '0') return const [];
      final count = _digitValue(char);
      if (count == null) {
        index++;
        continue;
      }
      index++;

      final reading = StringBuffer();
      final times = <int>[];
      while (index < kanaRaw.length && _digitValue(kanaRaw[index]) == null) {
        final timing = _timing.matchAsPrefix(kanaRaw, index);
        if (timing != null) {
          times.add(int.parse(timing.group(1)!));
          index = timing.end;
          continue;
        }
        reading.write(kanaRaw[index]);
        index++;
      }

      final text = reading.toString().trim();
      if (text.isEmpty) continue;
      if (!_isKanaOnly(text)) return const [];
      runs.add(QqKanaRun(kanjiCount: count, reading: text, timesMs: times));
    }

    return runs;
  }

  /// Annotates [lines] against [runs].
  ///
  /// The payload covers the whole song in order, metadata lines included, while
  /// [lines] may have had those credit lines trimmed. The offset where the
  /// lyrics start inside the payload is therefore unknown, so every offset is
  /// walked and the one that lines up best wins: the payload should be consumed
  /// to its end, and the kana timings QQ kept must fall inside the line the
  /// run was matched to.
  static List<List<FuriganaAnnotation>> annotateLines({
    required List<QqKanaLine> lines,
    required List<QqKanaRun> runs,
  }) {
    if (lines.isEmpty || runs.isEmpty) {
      return List.filled(lines.length, const []);
    }

    _Walk? best;
    for (var offset = 0; offset <= runs.length; offset++) {
      final walk = _walk(lines, runs, offset);
      if (walk == null) continue;
      if (best == null || walk.isBetterThan(best)) best = walk;
    }

    return best?.perLine ?? List.filled(lines.length, const []);
  }

  static _Walk? _walk(
    List<QqKanaLine> lines,
    List<QqKanaRun> runs,
    int offset,
  ) {
    var position = offset;
    var violations = 0;
    final perLine = <List<FuriganaAnnotation>>[];

    for (final line in lines) {
      final text = line.text;
      final annotations = <FuriganaAnnotation>[];
      var index = 0;

      while (index < text.length) {
        if (!FuriganaHelper.isKanji(text[index])) {
          index++;
          continue;
        }

        // A maximal kanji run may be covered by several payload entries (one
        // per kanji) or by a single one (a word like 今日 -> きょう).
        var runEnd = index;
        while (runEnd < text.length && FuriganaHelper.isKanji(text[runEnd])) {
          runEnd++;
        }
        var need = runEnd - index;
        var start = index;

        while (need > 0) {
          if (position >= runs.length) return null;
          final run = runs[position++];
          if (run.kanjiCount > need) return null;

          // Timings only disambiguate when the line has both bounds; the
          // last line of an LRC has no end time, so it must not be counted
          // as a violation.
          for (final time in run.timesMs) {
            if (line.startMs != null && time < line.startMs!) violations++;
            if (line.endMs != null && time >= line.endMs!) violations++;
          }

          annotations.add(
            FuriganaAnnotation(
              start: start,
              end: start + run.kanjiCount,
              reading: run.reading,
            ),
          );
          start += run.kanjiCount;
          need -= run.kanjiCount;
        }

        index = runEnd;
      }

      perLine.add(annotations);
    }

    return _Walk(
      offset: offset,
      perLine: perLine,
      violations: violations,
      remaining: runs.length - position,
    );
  }

  /// The reading length of a half width digit, or null when [char] is not
  /// one. `0` is not a length: it only shows up inside a multi digit count.
  static int? _digitValue(String char) {
    final code = char.codeUnitAt(0);
    if (code < 0x30 || code > 0x39) return null;
    final value = code - 0x30;
    return value == 0 ? null : value;
  }

  static bool _isKanaOnly(String value) {
    for (var i = 0; i < value.length; i++) {
      if (!_isKana(value[i])) return false;
    }
    return value.isNotEmpty;
  }

  static bool _isKana(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x3041 && code <= 0x3096) ||
        (code >= 0x30A1 && code <= 0x30FA) ||
        code == 0x30FC ||
        (code >= 0x309D && code <= 0x309E) ||
        (code >= 0x30FD && code <= 0x30FE);
  }
}

class _Walk {
  final int offset;
  final List<List<FuriganaAnnotation>> perLine;

  /// Karaoke timings that landed outside the line their run was matched to.
  final int violations;

  /// Payload entries left over after the last line.
  final int remaining;

  const _Walk({
    required this.offset,
    required this.perLine,
    required this.violations,
    required this.remaining,
  });

  bool isBetterThan(_Walk other) {
    if (violations != other.violations) return violations < other.violations;
    if (remaining != other.remaining) return remaining < other.remaining;
    return offset < other.offset;
  }
}
