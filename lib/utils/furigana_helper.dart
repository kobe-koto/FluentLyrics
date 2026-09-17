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
/// of it. Anything that does not line up (a different reading, romanization the
/// table does not know, a line the provider mistimed) makes the whole line bail
/// out with no annotations rather than showing wrong readings.
class FuriganaHelper {
  const FuriganaHelper._();

  /// How far a reading unit may be from where we expect it before giving up.
  /// Covers particles romanized the way they are spoken and small kana a
  /// provider merged into the previous unit.
  static const int _maxSkip = 3;

  static List<FuriganaAnnotation> align({
    required String text,
    required String reading,
    required bool readingIsRomaji,
  }) {
    if (text.isEmpty || reading.isEmpty) return const [];

    final units = readingIsRomaji
        ? reading.split(RegExp(r'\s+')).where((u) => u.isNotEmpty).toList()
        : _kanaUnits(reading);
    if (units.isEmpty) return const [];

    final annotations = <FuriganaAnnotation>[];
    final runUnits = <String>[];
    var position = 0; // index into `units`
    var index = 0; // index into `text`
    var runStart = -1;

    void closeRun(int end) {
      if (runStart >= 0 && runUnits.isNotEmpty) {
        annotations.add(
          FuriganaAnnotation(
            start: runStart,
            end: end,
            reading: readingIsRomaji ? runUnits.join(' ') : runUnits.join(),
          ),
        );
      }
      runStart = -1;
      runUnits.clear();
    }

    while (index < text.length) {
      final char = text[index];
      if (!_isKanaOrMark(char)) {
        if (_isKanji(char) && runStart < 0) runStart = index;
        index += _charLength(text, index);
        continue;
      }

      final kanaStart = index;
      final expected = _expectedUnits(text, index, readingIsRomaji);
      var match = _findMatch(units, position, expected);
      if (match == null) return const [];

      // A kanji run that is still empty may be waiting for the reading the
      // nearest match would consume (particles written as spoken: `は` -> `wa`).
      // Take a later occurrence when there is one.
      if (match == position && runStart >= 0 && runUnits.isEmpty) {
        final farther = _findMatch(units, position + 1, expected);
        if (farther != null) match = farther;
      }

      // Reading the kana skipped over belongs to the kanji run before it.
      runUnits.addAll(units.sublist(position, match));
      position = match + 1;

      // Romanized っ and small kana merge with the following kana (`tta` for
      // った, `syo` for しょ), so that kana must not look for its own reading.
      final merged = readingIsRomaji && _mergesWithNext(text, index);
      index += _charLength(text, index);
      if (merged && index < text.length && _isKanaOrMark(text[index])) {
        index += _charLength(text, index);
      }
      closeRun(kanaStart);
    }

    if (annotations.isEmpty) return const [];

    if (position < units.length) {
      // Trailing reading no kanji claimed: hand it to the last annotation
      // instead of dropping it silently.
      final extra = units.sublist(position);
      final last = annotations.removeLast();
      annotations.add(
        FuriganaAnnotation(
          start: last.start,
          end: last.end,
          reading: readingIsRomaji
              ? '${last.reading} ${extra.join(' ')}'
              : last.reading + extra.join(),
        ),
      );
    }
    return annotations;
  }

  /// Nearest reading unit matching [expected] within [_maxSkip], or null.
  static int? _findMatch(
    List<String> units,
    int position,
    List<String> expected,
  ) {
    if (expected.isEmpty) return null;
    for (
      var skip = 0;
      skip <= _maxSkip && position + skip < units.length;
      skip++
    ) {
      if (expected.contains(_toHiragana(units[position + skip]))) {
        return position + skip;
      }
    }
    return null;
  }

  static bool _mergesWithNext(String text, int index) {
    final char = text[index];
    if (char == 'っ' || char == 'ッ') return true;
    final next = _nextChar(text, index);
    if (next == null || !_isSmallKana(next)) return false;
    return _table.containsKey('${_toHiragana(char)}${_toHiragana(next)}');
  }

  /// Accepted readings for the kana at [index], including the っ merge with the
  /// following kana, small kana combinations and ー repeating the last vowel.
  static List<String> _expectedUnits(String text, int index, bool romaji) {
    final char = text[index];
    if (!romaji) return [_toHiragana(char)];

    if (char == 'っ' || char == 'ッ') {
      final next = _nextKana(text, index);
      if (next == null) return const ['tsu', 'tu'];
      final merged = _table[_toHiragana(next)];
      if (merged == null || merged.isEmpty) return const ['tsu', 'tu'];
      return merged.map((unit) => unit[0] + unit).toList();
    }
    if (char == 'ー') {
      final previous = _previousKana(text, index);
      if (previous == null) return const ['-'];
      final forms = _table[_toHiragana(previous)];
      if (forms == null || forms.isEmpty) return const ['-'];
      return [...forms.map((form) => form[form.length - 1]), '-'];
    }

    final next = _nextChar(text, index);
    if (next != null && _isSmallKana(next)) {
      final combined = _table['${_toHiragana(char)}${_toHiragana(next)}'];
      if (combined != null && combined.isNotEmpty) return combined;
    }
    return _table[_toHiragana(char)] ?? const [];
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

  /// Reading units the line's own kana must consume, in the provider's script
  /// (katakana stays katakana so annotations match the source).
  static List<String> _kanaUnits(String reading) {
    final units = <String>[];
    for (var i = 0; i < reading.length; i++) {
      final char = reading[i];
      if (_isKanaOrMark(char)) units.add(char);
    }
    return units;
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

  static String? _nextChar(String text, int index) {
    final next = index + _charLength(text, index);
    return next < text.length ? text[next] : null;
  }

  static bool _isKanji(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x3400 && code <= 0x4DBF) ||
        (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0xF900 && code <= 0xFAFF);
  }

  static const Map<String, List<String>> _table = {
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
