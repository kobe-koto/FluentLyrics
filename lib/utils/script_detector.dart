/// Script heuristics used to decide whether freshly fetched lyrics or
/// translations should go through Simplified/Traditional Chinese conversion.
///
/// Japanese is detected by kana: Chinese text essentially never uses hiragana
/// or katakana, while Japanese lyrics almost always do. Detection is
/// deliberately kana-only. A "Japanese-only kanji" table does not work for this
/// purpose: the characters OpenCC actually rewrites in Japanese text are shared
/// with Chinese (`研究会` -> `研究會`, `毎日新聞` -> `毎日新闻` under t2s), while
/// characters unique to Japanese (`発`, `変`, `図`) are absent from OpenCC's
/// Chinese dictionaries and pass through unchanged anyway.
///
/// Known limitation: kanji-only Japanese (a bare title such as `研究会` or
/// `日本語`) contains no kana and is not detected here. Callers can combine this
/// with the language reported by the lyrics provider or a user-maintained
/// ignore list.
class ScriptDetector {
  const ScriptDetector._();

  /// `の` is the one kana Chinese text borrows stylistically ("奈雪の茶"), so a
  /// single `の` is not evidence of Japanese on its own.
  static const int _noHiragana = 0x306E;

  /// Whether [text] looks like Japanese.
  static bool looksJapanese(String text) {
    var kana = 0;
    var decisiveKana = 0;
    for (final rune in text.runes) {
      if (!_isKanaLetter(rune)) continue;
      kana++;
      if (rune != _noHiragana) decisiveKana++;
    }
    return _isJapanese(kana, decisiveKana);
  }

  /// Whether any line in [lines] looks Japanese, evaluated over the whole
  /// document so a single kana across two lines still counts.
  static bool looksJapaneseLines(Iterable<String> lines) {
    var kana = 0;
    var decisiveKana = 0;
    for (final line in lines) {
      for (final rune in line.runes) {
        if (!_isKanaLetter(rune)) continue;
        kana++;
        if (rune != _noHiragana) decisiveKana++;
      }
    }
    return _isJapanese(kana, decisiveKana);
  }

  /// Whether [language] - a language tag as reported by a lyrics provider, e.g.
  /// `ja`, `ja-JP`, `jpn` - denotes Japanese.
  static bool isJapaneseLanguageCode(String? language) {
    if (language == null) return false;
    final normalized = language.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.isEmpty) return false;
    final primary = normalized.split('-').first;
    return primary == 'ja' || primary == 'jp' || primary == 'jpn';
  }

  static bool _isJapanese(int kana, int decisiveKana) =>
      decisiveKana >= 1 || kana >= 2;

  /// Kana letters only: the prolonged sound mark (`ー`) and middle dot (`・`)
  /// double as dashes/separators in Chinese text, and the iteration marks are
  /// too rare to be useful, so all of them are ignored on purpose.
  static bool _isKanaLetter(int rune) {
    const hiraganaStart = 0x3041; // ぁ
    const hiraganaEnd = 0x3096; // ゖ
    const katakanaStart = 0x30A1; // ァ
    const katakanaEnd = 0x30FA; // ヺ
    return (rune >= hiraganaStart && rune <= hiraganaEnd) ||
        (rune >= katakanaStart && rune <= katakanaEnd);
  }
}
