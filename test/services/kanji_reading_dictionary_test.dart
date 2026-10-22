import 'package:fluent_lyrics/services/kanji_reading_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewer decides when the bundled dictionary overwrites the copy', () {
    test('no extracted copy always extracts', () {
      expect(KanjiReadingDictionary.isNewer('2026-10-22', null), isTrue);
    });

    test('a newer bundled date wins', () {
      expect(
        KanjiReadingDictionary.isNewer('2026-10-22', '2025-01-01'),
        isTrue,
      );
    });

    test('an equal date keeps the extracted copy', () {
      expect(
        KanjiReadingDictionary.isNewer('2026-10-22', '2026-10-22'),
        isFalse,
      );
    });

    test('an older bundled date keeps the extracted copy', () {
      // A downgrade (e.g. older app reinstalled) does not clobber a newer copy.
      expect(
        KanjiReadingDictionary.isNewer('2025-01-01', '2026-10-22'),
        isFalse,
      );
    });

    test('non-date versions overwrite on any difference', () {
      expect(KanjiReadingDictionary.isNewer('v2', 'v1'), isTrue);
      expect(KanjiReadingDictionary.isNewer('v1', 'v1'), isFalse);
    });
  });
}
