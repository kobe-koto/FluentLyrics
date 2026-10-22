import 'dart:convert';

import 'package:fluent_lyrics/utils/kanji_readings_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanReading matches the build-time script', () {
    test('cuts kun readings at the okurigana marker', () {
      expect(KanjiReadingConverter.cleanReading('た.べる'), 'た');
    });

    test('strips bound-form hyphens', () {
      expect(KanjiReadingConverter.cleanReading('-がわ'), 'がわ');
      expect(KanjiReadingConverter.cleanReading('お-'), 'お');
    });

    test('leaves a plain on reading untouched', () {
      expect(KanjiReadingConverter.cleanReading('カン'), 'カン');
    });
  });

  group('convert parses KANJIDIC2 XML into trimmed JSON', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kanjidic2>
  <header>
    <file_version>4</file_version>
    <database_version>2026-301</database_version>
    <date_of_creation>2026-10-22</date_of_creation>
  </header>
  <character>
    <literal>勇</literal>
    <reading_meaning>
      <rmgroup>
        <reading r_type="pinyin">yong3</reading>
        <reading r_type="ja_on">ユウ</reading>
        <reading r_type="ja_kun">いさ.む</reading>
      </rmgroup>
      <meaning>courage</meaning>
    </reading_meaning>
  </character>
  <character>
    <literal>気</literal>
    <reading_meaning>
      <rmgroup>
        <reading r_type="ja_on">キ</reading>
        <reading r_type="ja_on">ケ</reading>
      </rmgroup>
    </reading_meaning>
  </character>
  <character>
    <literal>々</literal>
    <reading_meaning>
      <rmgroup>
        <reading r_type="pinyin">x</reading>
      </rmgroup>
    </reading_meaning>
  </character>
</kanjidic2>
''';

    test('keeps only ja_on/ja_kun, cleaned and deduplicated', () {
      final result = KanjiReadingConverter.convert(xml);
      final decoded = jsonDecode(result.json) as Map<String, dynamic>;

      expect(decoded['勇'], ['ユウ', 'いさ']);
      expect(decoded['気'], ['キ', 'ケ']);
    });

    test('drops kanji with no Japanese readings', () {
      final result = KanjiReadingConverter.convert(xml);
      final decoded = jsonDecode(result.json) as Map<String, dynamic>;
      expect(decoded.containsKey('々'), isFalse);
    });

    test('reads the version from date_of_creation', () {
      expect(KanjiReadingConverter.convert(xml).version, '2026-10-22');
    });

    test('keys are sorted for a stable output', () {
      final result = KanjiReadingConverter.convert(xml);
      final keys = (jsonDecode(result.json) as Map<String, dynamic>).keys
          .toList();
      final sorted = [...keys]..sort();
      expect(keys, sorted);
    });
  });
}
