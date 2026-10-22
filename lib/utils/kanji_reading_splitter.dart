import 'furigana_helper.dart';

/// Splits a kanji run and its whole-run kana reading into per-kanji readings,
/// using a bundled single-kanji reading dictionary.
///
/// The line-level reading tracks providers ship (NetEase `romalrc`/`klyric`)
/// only tell us the reading of a whole kanji run: `勇気` reads `ゆうき`, with no
/// boundary between 勇 and 気. [FuriganaHelper.align] recovers the run, and this
/// splitter tries to subdivide it so adjacent kanji can be annotated
/// separately (勇 -> ゆう, 気 -> き).
///
/// This is a heuristic with no provider ground truth: unlike QQ's `[kana:...]`
/// payload, nothing here guarantees where a run splits. So a run that cannot be
/// split unambiguously keeps its single whole-run annotation. We would rather
/// show a correct coarse reading than a confident wrong one.
class KanjiReadingSplitter {
  /// Single-kanji readings in hiragana, longest-first per kanji is not
  /// required; [split] sorts candidates itself. Keys are single kanji.
  final Map<String, List<String>> dictionary;

  const KanjiReadingSplitter(this.dictionary);

  /// Subdivides the kanji run `text[start..end]`, read as [reading] (kana), into
  /// one [FuriganaAnnotation] per kanji.
  ///
  /// Returns null when the run is not all kanji, the dictionary cannot account
  /// for it, or more than one subdivision fits (ambiguous). The caller keeps
  /// the original whole-run annotation in every one of those cases.
  List<FuriganaAnnotation>? split({
    required String text,
    required int start,
    required int end,
    required String reading,
  }) {
    if (reading.isEmpty || end - start <= 1) return null;

    // Operate on the run's kanji as a list of (offset, char): surrogate pairs
    // make the string index and the kanji count differ.
    final kanji = <(int, String)>[];
    var index = start;
    while (index < end) {
      final length = text.codeUnitAt(index) >= 0x10000 ? 2 : 1;
      final char = text.substring(index, index + length);
      if (!FuriganaHelper.isKanji(char)) return null;
      kanji.add((index, char));
      index += length;
    }
    if (kanji.length <= 1) return null;

    final readingHira = _toHiragana(reading);
    final solutions = <List<String>>[];
    _solve(kanji, 0, readingHira, 0, <String>[], solutions);

    // No split found, or more than one plausible split: keep the whole run.
    if (solutions.length != 1) return null;

    final parts = solutions.first;
    final annotations = <FuriganaAnnotation>[];
    for (var i = 0; i < kanji.length; i++) {
      final (offset, char) = kanji[i];
      final length = char.length;
      annotations.add(
        FuriganaAnnotation(
          start: offset,
          end: offset + length,
          reading: parts[i],
        ),
      );
    }
    return annotations;
  }

  /// Depth-first assignment of reading slices to each kanji. Collects every
  /// complete solution so the caller can reject ambiguity; bails out once a
  /// second solution appears, since one is all it takes to keep the whole run.
  void _solve(
    List<(int, String)> kanji,
    int kanjiIndex,
    String reading,
    int readingIndex,
    List<String> chosen,
    List<List<String>> solutions,
  ) {
    if (solutions.length > 1) return;
    if (kanjiIndex == kanji.length) {
      if (readingIndex == reading.length) {
        solutions.add(List<String>.of(chosen));
      }
      return;
    }
    // Not enough reading left for the remaining kanji (each needs >= 1 kana).
    if (reading.length - readingIndex < kanji.length - kanjiIndex) return;

    final char = kanji[kanjiIndex].$2;
    final base = dictionary[char];
    if (base == null || base.isEmpty) return;

    // Longest readings first: a greedy-looking order does not change which
    // solutions exist, but surfaces the common split sooner.
    final candidates = <String>{};
    for (final entry in base) {
      candidates.addAll(_soundVariants(_toHiragana(entry)));
    }
    final sorted = candidates.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final candidate in sorted) {
      if (candidate.isEmpty) continue;
      if (!_startsWith(reading, readingIndex, candidate)) continue;
      chosen.add(candidate);
      _solve(
        kanji,
        kanjiIndex + 1,
        reading,
        readingIndex + candidate.length,
        chosen,
        solutions,
      );
      chosen.removeLast();
      if (solutions.length > 1) return;
    }
  }

  static bool _startsWith(String text, int index, String prefix) {
    if (index + prefix.length > text.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (text.codeUnitAt(index + i) != prefix.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// Common sound changes a kanji reading undergoes inside a compound:
  /// gemination (促音便, trailing く/つ/ち/き/う -> っ) and sequential voicing
  /// (連濁, voicing or half-voicing the leading kana).
  static Set<String> _soundVariants(String reading) {
    final variants = <String>{reading};
    if (reading.isEmpty) return variants;

    // 促音便: a reading ending in these kana can geminate to っ before the next
    // kanji (学 がく -> がっ in 学校 がっこう).
    if (reading.length > 1 && 'くつちきう'.contains(reading[reading.length - 1])) {
      variants.add('${reading.substring(0, reading.length - 1)}っ');
    }

    // 連濁: the first kana of a non-initial kanji can voice or half-voice
    // (時 とき -> どき, 手 て -> で).
    final first = reading[0];
    final voiced = _rendaku[first];
    if (voiced != null) {
      for (final replacement in voiced) {
        variants.add('$replacement${reading.substring(1)}');
      }
    }
    return variants;
  }

  static String _toHiragana(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      // Katakana block maps to hiragana by a fixed -0x60 offset.
      if (rune >= 0x30A1 && rune <= 0x30F6) {
        buffer.writeCharCode(rune - 0x60);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Leading-kana voicing (連濁). Half-voiced forms are listed where the
  /// consonant can take either (は-row -> ば-row or ぱ-row).
  static const Map<String, List<String>> _rendaku = {
    'か': ['が'],
    'き': ['ぎ'],
    'く': ['ぐ'],
    'け': ['げ'],
    'こ': ['ご'],
    'さ': ['ざ'],
    'し': ['じ'],
    'す': ['ず'],
    'せ': ['ぜ'],
    'そ': ['ぞ'],
    'た': ['だ'],
    'ち': ['ぢ'],
    'つ': ['づ'],
    'て': ['で'],
    'と': ['ど'],
    'は': ['ば', 'ぱ'],
    'ひ': ['び', 'ぴ'],
    'ふ': ['ぶ', 'ぷ'],
    'へ': ['べ', 'ぺ'],
    'ほ': ['ぼ', 'ぽ'],
  };
}
