import '../../models/lyric_model.dart';
import '../../utils/script_detector.dart';
import 'zh_converter.dart';

/// User-facing target script for the optional Simplified/Traditional Chinese
/// conversion. The setting value doubles as the language code shown to users.
enum ZhConversionTarget {
  off('off', null),
  simplified('zh_CN', ZhConfig.t2s),
  traditionalTaiwan('zh_TW', ZhConfig.s2twp),
  traditionalHongKong('zh_HK', ZhConfig.s2hk);

  const ZhConversionTarget(this.settingValue, this.config);

  final String settingValue;

  /// OpenCC config used for this target, or null when conversion is disabled.
  final ZhConfig? config;

  static ZhConversionTarget fromSetting(String? value) {
    for (final target in values) {
      if (target.settingValue == value) return target;
    }
    return ZhConversionTarget.off;
  }
}

/// Pure conversion helpers shared by the provider and tests.
class ZhConversion {
  const ZhConversion._();

  /// Whether conversion should be skipped for [lyrics].
  ///
  /// Japanese is never converted by default: Japanese lyrics contain kanji
  /// that OpenCC would rewrite (`研究会` -> `研究會`, `日本の漢字` -> `日本の汉字`),
  /// while the characters unique to Japanese are passed through anyway. The
  /// decision is per document so a single song is never half-converted.
  ///
  /// [ignoredLanguages] is the user-maintained list of language codes to leave
  /// alone (defaults to Japanese); [languageHint] is the language reported by
  /// the lyrics provider, when it reports one.
  static bool shouldSkip({
    required List<Lyric> lyrics,
    required List<String> ignoredLanguages,
    String? languageHint,
  }) {
    final skipJapanese = ignoredLanguages.any(
      ScriptDetector.isJapaneseLanguageCode,
    );
    if (!skipJapanese) return false;
    if (ScriptDetector.isJapaneseLanguageCode(languageHint)) return true;
    return ScriptDetector.looksJapaneseLines(_textsOf(lyrics));
  }

  /// Converts every displayed string of [lyrics] (line text, translation and
  /// rich-sync inline parts). Returns the input list unchanged when no string
  /// is affected, so callers can keep using identity to detect changes.
  static List<Lyric> convert(
    List<Lyric> lyrics, {
    required ZhConverter converter,
  }) {
    var changed = false;
    final converted = <Lyric>[];
    for (final lyric in lyrics) {
      final text = converter.convert(lyric.text);
      final translation = switch (lyric.translation) {
        final String value => converter.convert(value),
        null => null,
      };
      final inlineParts = switch (lyric.inlineParts) {
        final List<LyricInlinePart> parts => [
          for (final part in parts)
            LyricInlinePart(
              startTime: part.startTime,
              endTime: part.endTime,
              text: converter.convert(part.text),
            ),
        ],
        null => null,
      };

      final partsChanged =
          inlineParts != null && _partsDiffer(inlineParts, lyric.inlineParts!);
      if (text != lyric.text ||
          translation != lyric.translation ||
          partsChanged) {
        changed = true;
        converted.add(
          Lyric(
            startTime: lyric.startTime,
            endTime: lyric.endTime,
            text: text,
            inlineParts: inlineParts,
            translation: translation,
          ),
        );
      } else {
        converted.add(lyric);
      }
    }
    return changed ? converted : lyrics;
  }

  static Iterable<String> _textsOf(List<Lyric> lyrics) sync* {
    for (final lyric in lyrics) {
      yield lyric.text;
      if (lyric.translation case final String translation) yield translation;
      if (lyric.inlineParts case final List<LyricInlinePart> parts) {
        for (final part in parts) {
          yield part.text;
        }
      }
    }
  }

  static bool _partsDiffer(List<LyricInlinePart> a, List<LyricInlinePart> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].text != b[i].text) return true;
    }
    return false;
  }
}
