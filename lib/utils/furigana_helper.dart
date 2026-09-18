/// A reading attached to a run of the original line: `text.substring(start, end)`
/// is read as [reading].
class FuriganaAnnotation {
  final int start;
  final int end;
  final String reading;

  const FuriganaAnnotation({
    required this.start,
    required this.end,
    required this.reading,
  });

  @override
  bool operator ==(Object other) =>
      other is FuriganaAnnotation &&
      other.start == start &&
      other.end == end &&
      other.reading == reading;

  @override
  int get hashCode => Object.hash(start, end, reading);

  @override
  String toString() => 'FuriganaAnnotation($start..$end -> $reading)';
}

/// Aligns a provider's reading track with the original line so kanji runs can
/// be annotated with their reading.
///
/// Both the kana and the romanized flavours are supported: the algorithm walks
/// the original text and matches the kana it already contains against the
/// reading, and whatever reading is left over belongs to the kanji run in front
/// of it. Anything that does not line up makes the whole line bail out with no
/// annotations rather than showing wrong readings.
class FuriganaHelper {
  const FuriganaHelper._();

  /// How far a reading unit may be from where we expect it. Kanji compounds
  /// read long (`満員電車` is 7 units) and providers merge small kana into the
  /// previous unit, so the window is generous; a mismatch anywhere still
  /// discards the whole line.
  static const int _maxSkip = 8;

  static List<FuriganaAnnotation> align({
    required String text,
    required String reading,
    required bool readingIsRomaji,
  }) {
    if (text.isEmpty || reading.isEmpty) return const [];

    // Providers separate mora with spaces, ん from a following vowel with an
    // apostrophe (`ma n'i n de n`), and punctuation is its own unit.
    final units =
        (readingIsRomaji
                ? reading
                      // Everything that is not a letter, digit or hyphen
                      // separates units: providers keep quotes and brackets in
                      // the track, and a hyphen stands for ー.
                      .split(RegExp(r'[^\p{L}\p{N}\-]+', unicode: true))
                      .where((unit) => unit.isNotEmpty)
                : _kanaUnits(reading).where((unit) => unit.isNotEmpty))
            // Providers sometimes keep the punctuation of the line (quotes,
            // brackets) in the reading track; it carries no sound.
            .where((unit) => _isNoise(unit) == false)
            .toList();
    if (units.isEmpty) return const [];

    final annotations = <FuriganaAnnotation>[];
    final runUnits = <String>[];
    var position = 0; // index into `units`
    var index = 0; // index into `text`
    var runStart = -1;
    var runEnd = -1;

    void closeRun() {
      if (runStart >= 0 && runEnd > runStart && runUnits.isNotEmpty) {
        annotations.add(
          FuriganaAnnotation(
            start: runStart,
            end: runEnd,
            reading: readingIsRomaji ? runUnits.join(' ') : runUnits.join(),
          ),
        );
      }
      runStart = -1;
      runEnd = -1;
      runUnits.clear();
    }

    while (index < text.length) {
      final char = text[index];

      if (_isKanji(char)) {
        if (runStart < 0) runStart = index;
        runEnd = index + _charLength(text, index);
        index = runEnd;
        continue;
      }

      if (!_isKanaOrMark(char)) {
        if (_isLatinRunChar(char)) {
          final consumed = _consumeLatinRun(text, index, units, position);
          index = consumed.$1;
          position = consumed.$2;
        } else {
          // Punctuation and the like are not read; they only end a run.
          index += _charLength(text, index);
        }
        continue;
      }

      final expected = _expectedUnits(text, index, readingIsRomaji);
      // While a kanji run is still waiting for its reading the anchor can be
      // arbitrarily far away (`満員電車触` is 8 units before ん), so the search
      // is unbounded there; between kana the window stays tight.
      final window = runStart >= 0 && runUnits.isEmpty
          ? units.length
          : _maxSkip;
      final candidates = _candidates(units, position, expected, window);
      if (candidates.isEmpty) {
        // Providers merge a long vowel into the previous unit (`su kaa to`),
        // so a ー the reading already covered is skipped.
        if (char == 'ー') {
          index += _charLength(text, index);
          continue;
        }
        return const [];
      }

      // Repeated kana make several anchors plausible: take the one the rest of
      // the line continues from, closest first.
      final nextIndex = index + _charLength(text, index);
      final runEndsHere =
          nextIndex >= text.length || !_isKanji(text[nextIndex]);
      final match = _bestMatch(
        text,
        index,
        units,
        position,
        candidates,
        // A kanji run that ends on this kana may be racing it for the reading
        // (`私は` = わたし + は), so give the run the reading and the kana the
        // last occurrence. Inside a run, or when another kanji follows, the
        // nearest anchor is the right one.
        preferLast: runStart >= 0 && runUnits.isEmpty && runEndsHere,
      );

      runUnits.addAll(
        units.sublist(position, match).where((unit) => unit.isNotEmpty),
      );
      position = match + 1;

      // Romanized っ and small kana merge with the following kana (`tta` for
      // った, `syo` for しょ), so that kana must not look for its own reading.
      final merged = readingIsRomaji && _mergesWithNext(text, index);
      index += _charLength(text, index);
      if (merged && index < text.length && _isKanaOrMark(text[index])) {
        index += _charLength(text, index);
      }
      closeRun();
    }

    // The line may end with a kanji run: hand it whatever reading is left.
    if (position < units.length) {
      runUnits.addAll(units.sublist(position).where((unit) => unit.isNotEmpty));
      position = units.length;
    }
    closeRun();

    return annotations;
  }

  /// Picks the anchor whose reading leaves the following text the least to
  /// travel to. When the line ends there ([preferLast]) a kanji run that has no
  /// reading yet takes the furthest anchor instead, so the kana in front of it
  /// (`私は` -> `wa ta shi wa`) is not mistaken for the run's own reading.
  static int _bestMatch(
    String text,
    int index,
    List<String> units,
    int position,
    List<int> candidates, {
    required bool preferLast,
  }) {
    if (candidates.length == 1) return candidates.first;

    final nextIndex = index + _charLength(text, index);
    if (nextIndex < text.length && _isKanaOrMark(text[nextIndex])) {
      final nextExpected = _expectedUnits(text, nextIndex, true);
      int? best;
      var bestGap = 1 << 30;
      for (final candidate in candidates) {
        final next = _findMatch(units, candidate + 1, nextExpected, _maxSkip);
        if (next == null) continue;
        final gap = next - candidate;
        if (gap < bestGap) {
          bestGap = gap;
          best = candidate;
        }
      }
      if (best != null) return best;
    }

    return preferLast ? candidates.last : candidates.first;
  }

  static List<int> _candidates(
    List<String> units,
    int position,
    List<String> expected,
    int window,
  ) {
    final candidates = <int>[];
    for (
      var skip = 0;
      skip <= window && position + skip < units.length;
      skip++
    ) {
      final unit = units[position + skip];
      if (unit.isEmpty) continue;
      if (expected.contains(_toHiragana(unit))) candidates.add(position + skip);
    }
    return candidates;
  }

  /// Nearest reading unit matching [expected] within [_maxSkip], or null.
  static int? _findMatch(
    List<String> units,
    int position,
    List<String> expected,
    int window,
  ) {
    if (expected.isEmpty) return null;
    final candidates = _candidates(units, position, expected, window);
    return candidates.isEmpty ? null : candidates.first;
  }

  static bool _mergesWithNext(String text, int index) {
    final char = text[index];
    if (char == 'っ' || char == 'ッ') return true;
    final next = _nextChar(text, index);
    if (next == null || !_isSmallKana(next)) return false;
    return kanaRomajiTable.containsKey(
      '${_toHiragana(char)}${_toHiragana(next)}',
    );
  }

  /// Accepted readings for the kana at [index], including the っ merge with the
  /// following kana, small kana combinations and long vowels.
  static List<String> _expectedUnits(String text, int index, bool romaji) {
    final char = text[index];
    if (!romaji) return [_toHiragana(char)];

    if (char == 'っ' || char == 'ッ') {
      final next = _nextKana(text, index);
      if (next == null) return const ['tsu', 'tu'];
      final merged = kanaRomajiTable[_toHiragana(next)];
      if (merged == null || merged.isEmpty) return const ['tsu', 'tu'];
      final forms = <String>[];
      for (final unit in merged) {
        forms.add(unit[0] + unit);
        // Hepburn doubles `ch` and `ts` with a `t` prefix (matcha, tsupparu).
        if (unit.startsWith('ch') || unit.startsWith('ts')) {
          forms.add('t$unit');
        }
      }
      return forms;
    }
    if (char == 'ー') {
      final previous = _previousKana(text, index);
      if (previous == null) return const ['-'];
      final forms = kanaRomajiTable[_toHiragana(previous)];
      if (forms == null || forms.isEmpty) return const ['-'];
      return [...forms.map((form) => form[form.length - 1]), '-'];
    }

    final next = _nextChar(text, index);
    if (next != null && _isSmallKana(next)) {
      final combined =
          kanaRomajiTable['${_toHiragana(char)}${_toHiragana(next)}'];
      if (combined != null && combined.isNotEmpty) return combined;
    }

    final forms = kanaRomajiTable[_toHiragana(char)];
    if (forms == null) return const [];
    // Providers merge a long vowel into the previous unit (`su kaa to`), so the
    // vowel-doubled spelling is accepted too.
    return [
      for (final form in forms) ...[form, if (next == 'ー') _vowelDoubled(form)],
    ];
  }

  static String? _nextKana(String text, int index) {
    for (var i = index + _charLength(text, index); i < text.length; i++) {
      if (_isKana(text[i])) return text[i];
      if (_isKanji(text[i])) return null;
    }
    return null;
  }

  static String? _previousKana(String text, int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (_isKana(text[i])) return text[i];
      if (_isKanji(text[i])) return null;
    }
    return null;
  }

  /// Reading units the line's own kana must consume, in the provider's script.
  static List<String> _kanaUnits(String reading) {
    final units = <String>[];
    for (var i = 0; i < reading.length; i++) {
      final char = reading[i];
      if (_isKanaOrMark(char)) units.add(char);
    }
    return units;
  }

  /// Latin words (and numbers) are written the same way in the lyrics and in
  /// the reading track, so consume the matching units: `gimme` covers one unit,
  /// while a unit the provider merged with a following kana (`BeRealde`) keeps
  /// the leftover for that kana.
  static (int, int) _consumeLatinRun(
    String text,
    int index,
    List<String> units,
    int position,
  ) {
    var end = index;
    while (end < text.length && _isLatinRunChar(text[end])) {
      end += _charLength(text, end);
    }

    final run = text.substring(index, end).toLowerCase();
    // Repeated words (`gimme gimme`) take the next occurrence, so scan a little
    // ahead instead of only looking at the current unit.
    for (var i = position; i < units.length && i <= position + 8; i++) {
      final unit = units[i].toLowerCase();
      if (unit.isEmpty) continue;
      if (unit == run) {
        units[i] = '';
        return (end, i + 1);
      }
      if (unit.startsWith(run)) {
        units[i] = units[i].substring(run.length);
        return (end, i);
      }
    }
    return (end, position);
  }

  static int _charLength(String text, int index) =>
      text.codeUnitAt(index) >= 0x10000 ? 2 : 1;

  static String _toHiragana(String char) {
    final code = char.codeUnitAt(0);
    if (code >= 0x30A1 && code <= 0x30F6) {
      return String.fromCharCode(code - 0x60);
    }
    return char;
  }

  static String _vowelDoubled(String form) {
    final last = form[form.length - 1];
    return RegExp(r'[aeiou]').hasMatch(last) ? '$form$last' : form;
  }

  static bool _isKana(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x3041 && code <= 0x3096) ||
        (code >= 0x30A1 && code <= 0x30FA);
  }

  /// Kana plus the prolonged sound mark, which consumes a reading unit too.
  static bool _isKanaOrMark(String char) => _isKana(char) || char == 'ー';

  static bool _isSmallKana(String char) =>
      const {'ゃ', 'ゅ', 'ょ', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'}.contains(char) ||
      const {'ャ', 'ュ', 'ョ', 'ァ', 'ィ', 'ゥ', 'ェ', 'ォ'}.contains(char);

  /// Parts of a Latin word (`Wi-Fi`, `BeReal`), which the reading track spells
  /// out the same way.
  static final RegExp _latinRunChar = RegExp(r"[A-Za-z0-9'.&-]");

  static bool _isLatinRunChar(String char) => _latinRunChar.hasMatch(char);

  static String? _nextChar(String text, int index) {
    final next = index + _charLength(text, index);
    return next < text.length ? text[next] : null;
  }

  /// Reading units that carry no sound: punctuation, quotes and symbols the
  /// provider kept in the romanized track.
  static final RegExp _noiseUnit = RegExp(r'^[\p{P}\p{S}]+$', unicode: true);

  static bool _isNoise(String unit) => _noiseUnit.hasMatch(unit);

  /// Whether [char] is a kanji (々/〻 included: they read as the kanji before).
  static bool isKanji(String char) => _isKanji(char);

  static bool _isKanji(String char) {
    // 々/〻 iterate the kanji before them and are read with it.
    if (char == '々' || char == '〻') return true;
    final code = char.codeUnitAt(0);
    return (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0xF900 && code <= 0xFAFF);
  }

  static const Map<String, List<String>> kanaRomajiTable = {
    'あ': ['a'],
    'い': ['i'],
    'う': ['u'],
    'え': ['e'],
    'お': ['o'],
    'か': ['ka'],
    'き': ['ki'],
    'く': ['ku'],
    'け': ['ke'],
    'こ': ['ko'],
    'さ': ['sa'],
    'し': ['shi', 'si'],
    'す': ['su'],
    'せ': ['se'],
    'そ': ['so'],
    'た': ['ta'],
    'ち': ['chi', 'ti'],
    'つ': ['tsu', 'tu'],
    'て': ['te'],
    'と': ['to'],
    'な': ['na'],
    'に': ['ni'],
    'ぬ': ['nu'],
    'ね': ['ne'],
    'の': ['no'],
    'は': ['ha', 'wa'],
    'ひ': ['hi'],
    'ふ': ['fu', 'hu'],
    'へ': ['he', 'e'],
    'ほ': ['ho'],
    'ま': ['ma'],
    'み': ['mi'],
    'む': ['mu'],
    'め': ['me'],
    'も': ['mo'],
    'や': ['ya'],
    'ゆ': ['yu'],
    'よ': ['yo'],
    'ら': ['ra'],
    'り': ['ri'],
    'る': ['ru'],
    'れ': ['re'],
    'ろ': ['ro'],
    'わ': ['wa'],
    'を': ['wo', 'o'],
    'ん': ['n', 'nn'],
    'が': ['ga'],
    'ぎ': ['gi'],
    'ぐ': ['gu'],
    'げ': ['ge'],
    'ご': ['go'],
    'ざ': ['za'],
    'じ': ['ji', 'zi'],
    'ず': ['zu', 'du'],
    'ぜ': ['ze'],
    'ぞ': ['zo'],
    'だ': ['da'],
    'ぢ': ['ji', 'di'],
    'づ': ['zu', 'du'],
    'で': ['de'],
    'ど': ['do'],
    'ば': ['ba'],
    'び': ['bi'],
    'ぶ': ['bu'],
    'べ': ['be'],
    'ぼ': ['bo'],
    'ぱ': ['pa'],
    'ぴ': ['pi'],
    'ぷ': ['pu'],
    'ぺ': ['pe'],
    'ぽ': ['po'],
    'ぁ': ['a'],
    'ぃ': ['i'],
    'ぅ': ['u'],
    'ぇ': ['e'],
    'ぉ': ['o'],
    'ゃ': ['ya'],
    'ゅ': ['yu'],
    'ょ': ['yo'],
    'きゃ': ['kya'],
    'きゅ': ['kyu'],
    'きょ': ['kyo'],
    'しゃ': ['sha', 'sya'],
    'しゅ': ['shu', 'syu'],
    'しょ': ['sho', 'syo'],
    'ちゃ': ['cha', 'tya', 'cya'],
    'ちゅ': ['chu', 'tyu'],
    'ちょ': ['cho', 'tyo'],
    'にゃ': ['nya'],
    'にゅ': ['nyu'],
    'にょ': ['nyo'],
    'ひゃ': ['hya'],
    'ひゅ': ['hyu'],
    'ひょ': ['hyo'],
    'じゃ': ['ja', 'zya'],
    'じゅ': ['ju', 'zyu'],
    'じょ': ['jo', 'zyo'],
    'びゃ': ['bya'],
    'びゅ': ['byu'],
    'びょ': ['byo'],
    'ぴゃ': ['pya'],
    'ぴゅ': ['pyu'],
    'ぴょ': ['pyo'],
    'みゃ': ['mya'],
    'みゅ': ['myu'],
    'みょ': ['myo'],
    'りゃ': ['rya'],
    'りゅ': ['ryu'],
    'りょ': ['ryo'],
    'ぎゃ': ['gya'],
    'ぎゅ': ['gyu'],
    'ぎょ': ['gyo'],
    'ふぁ': ['fa'],
    'ふぃ': ['fi'],
    'ふぇ': ['fe'],
    'ふぉ': ['fo'],
    'でぃ': ['di'],
    'てぃ': ['ti'],
    'でゅ': ['dyu'],
    'てゅ': ['tyu'],
    'うぃ': ['wi'],
    'うぇ': ['we'],
    'うぉ': ['wo'],
    'しぇ': ['she', 'sye'],
    'じぇ': ['je', 'zye'],
    'ちぇ': ['che', 'tye'],
    'つぁ': ['tsa'],
    'つぃ': ['tsi'],
    'つぇ': ['tse'],
    'つぉ': ['tso'],
  };
}
