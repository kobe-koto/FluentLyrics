/// Deterministic, rule-based detection of lines that are not sung lyrics:
/// section/structure markers (`Verse 1`, `[Chorus]`, `【副歌】`, `间奏`) and
/// strong copyright notices (`未经许可，不得翻唱`, `版权所有`, `© ...`).
///
/// These are the categories safe to remove *wherever* they appear. Weaker,
/// position-dependent signals (a bare `作词：` credit, a title/artist line)
/// stay in [LrcParser.trimMetadataLines], which only trims the head and tail.
///
/// The classifier is intentionally conservative: a line is only flagged when
/// its whole (bracket-stripped) content is a known marker, or when it carries
/// a distinctive multi-character copyright phrase. Lyrics that merely contain
/// such a word are kept. Removing a real line is worse than keeping junk.
class NonLyricLineClassifier {
  const NonLyricLineClassifier._();

  /// Opening -> closing bracket pairs that may wrap a whole marker line.
  static const Map<String, String> _bracketPairs = {
    '[': ']',
    '(': ')',
    '{': '}',
    '<': '>',
    '【': '】',
    '（': '）',
    '《': '》',
    '「': '」',
    '『': '』',
    '〔': '〕',
  };

  /// English section markers, optionally followed by a number (`1`), a roman
  /// numeral (`ii`), a repeat count (`x2`) and/or a lettered part (`a`). The
  /// lettered part requires a separator so real words such as `bridged` are
  /// not mistaken for `bridge` + `d`.
  static final RegExp _enStructure = RegExp(
    r'^(verse|chorus|pre[\s\-]?chorus|post[\s\-]?chorus|bridge|intro|outro'
    r'|refrain|interlude|instrumental)'
    r'(?:[\s\-:：.]*(?:[x×]\s*[0-9]+|[0-9]+|[ivxlcdm]+))?'
    r'(?:[\s\-:：.]+[a-d])?'
    r'[\s\-:：.]*$',
    caseSensitive: false,
  );

  /// Chinese section markers, optionally followed by a number
  /// (arabic or 一二三…). Simplified and traditional forms are both listed
  /// because fetched lyrics arrive in either script.
  static final RegExp _zhStructure = RegExp(
    r'^(主歌|副歌|前奏|间奏|間奏|尾奏|过门|過門)'
    r'(?:\s*(?:[0-9]+|[一二三四五六七八九十]+))?$',
  );

  /// Distinctive copyright/legal phrases. Matched as substrings (lower-cased),
  /// so a notice keeps matching when it is wrapped in extra wording.
  static const List<String> _copyrightMarkers = [
    '未经许可',
    '未經許可',
    '未经授权',
    '未經授權',
    '未经著作权',
    '未經著作權',
    '不得翻唱',
    '不得翻录',
    '不得翻錄',
    '不得转载',
    '不得轉載',
    '不得复制',
    '不得複製',
    '版权所有',
    '版權所有',
    '保留所有权利',
    '保留所有權利',
    '版权归',
    '版權歸',
    '侵权必究',
    '侵權必究',
    'all rights reserved',
    '©',
  ];

  /// Whether [line] should be removed wherever it appears.
  static bool isGloballyRemovable(String line) =>
      isStructureMarker(line) || isCopyright(line);

  /// Whether [line] is only a section/structure marker, with or without
  /// surrounding brackets.
  static bool isStructureMarker(String line) {
    final core = _stripOuterBrackets(line);
    if (core.isEmpty) return false;
    return _enStructure.hasMatch(core) || _zhStructure.hasMatch(core);
  }

  /// Whether [line] carries a strong copyright/legal notice.
  static bool isCopyright(String line) {
    final lowered = line.toLowerCase();
    return _copyrightMarkers.any(lowered.contains);
  }

  /// Repeatedly removes one matching outer bracket pair so that `[Verse 1]`,
  /// `【副歌】` and `(Chorus)` reduce to their inner text. A line whose first
  /// character is not an opening bracket, or whose last character does not
  /// close it, is returned trimmed and unchanged.
  static String _stripOuterBrackets(String line) {
    var text = line.trim();
    while (text.length >= 2) {
      final close = _bracketPairs[text[0]];
      if (close != null && text.endsWith(close)) {
        text = text.substring(1, text.length - 1).trim();
      } else {
        break;
      }
    }
    return text;
  }
}
