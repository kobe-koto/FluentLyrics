import 'furigana_helper.dart';

/// Converts the romanized reading units providers ship (NetEase `romalrc`,
/// QQ `roma`) back to kana, so kanji can be annotated with kana even when the
/// provider only has a romanized track.
///
/// Input is the provider's mora separated form (`shi zu mu yo u ni`,
/// `ka tta de syo u`). Everything is a table lookup: the alignment that
/// produced the reading already told us which kana belong to the kanji, so
/// there is no ambiguity left to resolve beyond picking the common spelling
/// (`shi` -> し rather than し/シ, `ji` -> じ rather than ぢ).
class RomajiHelper {
  const RomajiHelper._();

  /// Longest first, so `kya` wins over `ki` + `ya` style tokenization.
  static final List<MapEntry<String, String>> _reverse = _buildReverse();

  /// Kana for a romanized reading, or null when a unit is not understood
  /// (callers should drop the annotation instead of showing romanization).
  static String? toKana(String romaji) {
    if (romaji.trim().isEmpty) return null;

    final buffer = StringBuffer();
    for (final unit
        in romaji.split(RegExp(r'\s+')).where((u) => u.isNotEmpty)) {
      final kana = _unitToKana(unit);
      if (kana == null) return null;
      buffer.write(kana);
    }
    return buffer.toString();
  }

  static String? _unitToKana(String unit) {
    if (unit == '-') return 'ー';

    // 促音: a doubled consonant (`tta`, `kko`) is っ plus the rest.
    if (unit.length > 1 &&
        unit[0] == unit[1] &&
        !RegExp(r'[aeiou]').hasMatch(unit[0])) {
      final rest = _lookup(unit.substring(1));
      if (rest != null) return 'っ$rest';
    }

    return _lookup(unit);
  }

  static String? _lookup(String unit) {
    final lower = unit.toLowerCase();
    for (final entry in _reverse) {
      if (entry.key == lower) return entry.value;
    }
    return null;
  }

  /// Small kana only ever appear inside a combination (`きゃ`), never as a
  /// lookup result of their own.
  static const Set<String> _smallKana = {
    'ぁ',
    'ぃ',
    'ぅ',
    'ぇ',
    'ぉ',
    'ゃ',
    'ゅ',
    'ょ',
    'ァ',
    'ィ',
    'ゥ',
    'ェ',
    'ォ',
    'ャ',
    'ュ',
    'ョ',
  };

  static List<MapEntry<String, String>> _buildReverse() {
    // Longer kana win (`でぃ` (di) beats `ぢ`); within the same length the table
    // order decides, so the common spelling wins (`じ` before `ぢ`).
    final indexed =
        FuriganaHelper.kanaRomajiTable.entries
            .toList()
            .asMap()
            .entries
            .where(
              (e) =>
                  !(e.value.key.length == 1 &&
                      _smallKana.contains(e.value.key)),
            )
            .toList()
          ..sort((a, b) {
            final byLength = b.value.key.length.compareTo(a.value.key.length);
            return byLength != 0 ? byLength : a.key.compareTo(b.key);
          });

    final map = <String, String>{};
    for (final entry in indexed) {
      for (final romaji in entry.value.value) {
        map.putIfAbsent(romaji.toLowerCase(), () => entry.value.key);
      }
    }
    return map.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
  }
}
