import 'package:fluent_lyrics/utils/script_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScriptDetector.looksJapanese', () {
    test('detects Japanese by kana', () {
      expect(ScriptDetector.looksJapanese('君の名は'), isTrue);
      expect(ScriptDetector.looksJapanese('東京は晴れ'), isTrue);
      expect(ScriptDetector.looksJapanese('夜に駆ける'), isTrue);
      expect(ScriptDetector.looksJapanese('メロディー'), isTrue);
      expect(ScriptDetector.looksJapanese('すごい'), isTrue);
      expect(ScriptDetector.looksJapanese('カタカナとひらがな'), isTrue);
      // A single non-`の` kana is already decisive (okurigana, particles).
      expect(ScriptDetector.looksJapanese('予定通り'), isTrue);
      expect(ScriptDetector.looksJapanese('あ'), isTrue);
      expect(ScriptDetector.looksJapanese('ヶ'), isTrue);
    });

    test('does not flag Chinese text', () {
      expect(ScriptDetector.looksJapanese('简体中文测试'), isFalse);
      expect(ScriptDetector.looksJapanese('開放中文轉換'), isFalse);
      expect(ScriptDetector.looksJapanese('这首歌的副歌很好听'), isFalse);
      // A single borrowed `の` is not enough.
      expect(ScriptDetector.looksJapanese('奈雪の茶'), isFalse);
      expect(ScriptDetector.looksJapanese('の'), isFalse);
    });

    test('ignores kana-like marks used by Chinese text', () {
      expect(ScriptDetector.looksJapanese(''), isFalse);
      expect(ScriptDetector.looksJapanese('   '), isFalse);
      expect(ScriptDetector.looksJapanese('hello 123, 汉字! 🎵'), isFalse);
      expect(ScriptDetector.looksJapanese('ー'), isFalse);
      expect(ScriptDetector.looksJapanese('・'), isFalse);
      expect(ScriptDetector.looksJapanese('ヽヾゝゞ'), isFalse);
    });

    test('detects kanji-heavy Japanese lyrics', () {
      // Real lyrics mix kanji with kana; the kana carries the signal.
      expect(ScriptDetector.looksJapanese('日本 の 漢字 を 書く'), isTrue);
    });

    test('notes the kanji-only limitation', () {
      // Documented limitation: no kana means no detection.
      expect(ScriptDetector.looksJapanese('研究会'), isFalse);
      expect(ScriptDetector.looksJapanese('日本語'), isFalse);
    });
  });

  group('ScriptDetector.looksJapaneseLines', () {
    test('evaluates the whole document', () {
      expect(ScriptDetector.looksJapaneseLines(['中文歌词第一行', '君の名は']), isTrue);
      expect(ScriptDetector.looksJapaneseLines(['中文歌词', '另一行']), isFalse);
      // Two `の` spread across lines still count as Japanese.
      expect(ScriptDetector.looksJapaneseLines(['奈雪の茶', '恋の季節']), isTrue);
      expect(ScriptDetector.looksJapaneseLines(const []), isFalse);
    });
  });

  group('ScriptDetector.isJapaneseLanguageCode', () {
    test('accepts common Japanese tags', () {
      for (final code in ['ja', 'JA', 'ja-JP', 'ja_JP', 'jp', 'jpn', ' jpn ']) {
        expect(
          ScriptDetector.isJapaneseLanguageCode(code),
          isTrue,
          reason: code,
        );
      }
    });

    test('rejects other languages', () {
      for (final code in ['zh', 'zh_CN', 'zht', 'en', 'ko', '', null]) {
        expect(
          ScriptDetector.isJapaneseLanguageCode(code),
          isFalse,
          reason: '$code',
        );
      }
    });
  });
}
