import 'package:flutter/foundation.dart';

import '../models/lyric_model.dart';
import '../services/opencc/zh_conversion.dart';
import '../services/opencc/zh_conversion_service.dart';
import '../utils/app_logger.dart';
import '../utils/furigana_helper.dart';
import '../utils/lyrics_display_helper.dart';
import '../utils/lyrics_reading_helper.dart';
import '../utils/qq_kana_helper.dart';
import '../utils/romaji_helper.dart';

/// Memoized display transforms: rich-sync stripping, translation alignment,
/// Simplified/Traditional conversion, and kanji annotation.
class LyricsDisplayPipeline {
  List<Lyric>? _cachedAlignedLyrics;
  LyricsResult? _lastLyricsResultForAlignment;
  LyricsResult? _lastTranslationResultForAlignment;
  bool? _lastRichSyncEnabledForAlignment;

  List<Lyric>? _cachedStrippedLyrics;
  LyricsResult? _lastLyricsResultForStripping;

  List<Lyric>? _convertedLyrics;
  List<Lyric>? _convertedLyricsSource;
  String? _convertedLyricsTarget;
  List<String>? _convertedLyricsIgnoredLanguages;
  String? _convertedLyricsLanguageHint;

  List<Lyric>? _annotatedLyrics;
  List<Lyric>? _annotatedLyricsSource;
  LyricsReading? _annotatedLyricsReading;
  int? _annotatedLyricsBias;

  void invalidateAlignment() {
    _cachedAlignedLyrics = null;
    _lastTranslationResultForAlignment = null;
    _lastRichSyncEnabledForAlignment = null;
  }

  List<Lyric> build({
    required LyricsResult lyricsResult,
    required LyricsResult? translationResult,
    required LyricsReading? reading,
    required bool richSyncEnabled,
    required bool translationEnabled,
    required bool annotationEnabled,
    required int annotationBias,
    required String zhConversionTarget,
    required List<String> zhConversionIgnoredLanguages,
    required int translationAlignmentThreshold,
  }) {
    final displayed = _buildDisplayedLyrics(
      lyricsResult: lyricsResult,
      translationResult: translationResult,
      richSyncEnabled: richSyncEnabled,
      translationEnabled: translationEnabled,
      translationAlignmentThreshold: translationAlignmentThreshold,
    );
    final converted = _applyZhConversion(
      displayed,
      targetSetting: zhConversionTarget,
      ignoredLanguages: zhConversionIgnoredLanguages,
      languageHint: lyricsResult.language ?? translationResult?.language,
    );
    return _applyReadingAnnotations(
      converted,
      reading: reading,
      annotationEnabled: annotationEnabled,
      annotationBias: annotationBias,
    );
  }

  List<Lyric> _applyZhConversion(
    List<Lyric> lyrics, {
    required String targetSetting,
    required List<String> ignoredLanguages,
    required String? languageHint,
  }) {
    final target = ZhConversionTarget.fromSetting(targetSetting);
    if (target == ZhConversionTarget.off) return lyrics;

    if (identical(_convertedLyricsSource, lyrics) &&
        _convertedLyricsTarget == target.settingValue &&
        _convertedLyricsLanguageHint == languageHint &&
        listEquals(_convertedLyricsIgnoredLanguages, ignoredLanguages)) {
      return _convertedLyrics!;
    }

    final converted = ZhConversionService.instance.convertLyrics(
      lyrics,
      target: target,
      ignoredLanguages: ignoredLanguages,
      languageHint: languageHint,
    );
    _convertedLyricsSource = lyrics;
    _convertedLyrics = converted;
    _convertedLyricsTarget = target.settingValue;
    _convertedLyricsIgnoredLanguages = ignoredLanguages;
    _convertedLyricsLanguageHint = languageHint;
    return converted;
  }

  List<Lyric> _applyReadingAnnotations(
    List<Lyric> lyrics, {
    required LyricsReading? reading,
    required bool annotationEnabled,
    required int annotationBias,
  }) {
    if (!annotationEnabled) return lyrics;
    if (reading == null || reading.lines.isEmpty || lyrics.isEmpty) {
      return lyrics;
    }
    if (identical(_annotatedLyricsSource, lyrics) &&
        identical(_annotatedLyricsReading, reading) &&
        _annotatedLyricsBias == annotationBias) {
      return _annotatedLyrics!;
    }

    final kanaRaw = reading.kanaRaw;
    if (kanaRaw != null && kanaRaw.trim().isNotEmpty) {
      final perLine = QqKanaHelper.annotateLines(
        lines: [
          for (final lyric in lyrics)
            QqKanaLine(
              lyric.text,
              startMs: lyric.startTime.inMilliseconds,
              endMs: lyric.endTime?.inMilliseconds,
            ),
        ],
        runs: QqKanaHelper.parseRuns(kanaRaw),
      );
      final annotatedLines = perLine.where((line) => line.isNotEmpty).length;
      if (annotatedLines > 0) {
        AppLogger.debug(
          '[Annotations] QQ kana path: $annotatedLines/${lyrics.length} lines',
        );
        var changed = false;
        final annotated = <Lyric>[];
        for (var i = 0; i < lyrics.length; i++) {
          final annotations = perLine[i];
          if (annotations.isEmpty) {
            annotated.add(lyrics[i]);
            continue;
          }
          changed = true;
          annotated.add(
            Lyric(
              startTime: lyrics[i].startTime,
              endTime: lyrics[i].endTime,
              text: lyrics[i].text,
              inlineParts: lyrics[i].inlineParts,
              translation: lyrics[i].translation,
              annotations: annotations,
            ),
          );
        }
        _annotatedLyricsSource = lyrics;
        _annotatedLyricsReading = reading;
        _annotatedLyricsBias = annotationBias;
        _annotatedLyrics = changed ? annotated : lyrics;
        return _annotatedLyrics!;
      }
    }

    AppLogger.debug(
      '[Annotations] romanized path (kana payload: '
      '${reading.kanaRaw == null ? 'absent' : 'unusable'})',
    );
    final readings = LyricsReadingHelper.pairReadings(
      lyrics,
      reading.lines,
      toleranceMs: annotationBias,
    );
    var changed = false;
    final annotated = <Lyric>[
      for (var i = 0; i < lyrics.length; i++)
        _annotateLyric(
          lyrics[i],
          readings[i],
          reading.lineType,
          changed: () => changed = true,
        ),
    ];
    _annotatedLyricsSource = lyrics;
    _annotatedLyricsReading = reading;
    _annotatedLyricsBias = annotationBias;
    _annotatedLyrics = changed ? annotated : lyrics;
    return _annotatedLyrics!;
  }

  Lyric _annotateLyric(
    Lyric lyric,
    String? reading,
    LyricsReadingType? lineType, {
    required void Function() changed,
  }) {
    if (lyric.text.isEmpty || lyric.annotations != null) return lyric;
    if (reading == null || reading.isEmpty) return lyric;

    final isKana = lineType == LyricsReadingType.kana;
    final annotations = FuriganaHelper.align(
      text: lyric.text,
      reading: reading,
      readingIsRomaji: !isKana,
    );
    if (annotations.isEmpty) return lyric;

    final readings = <FuriganaAnnotation>[];
    for (final annotation in annotations) {
      final text = isKana
          ? annotation.reading
          : RomajiHelper.toKana(annotation.reading);
      if (text == null || text.isEmpty) return lyric;
      readings.add(
        FuriganaAnnotation(
          start: annotation.start,
          end: annotation.end,
          reading: text,
        ),
      );
    }

    changed();
    return Lyric(
      startTime: lyric.startTime,
      endTime: lyric.endTime,
      text: lyric.text,
      inlineParts: lyric.inlineParts,
      translation: lyric.translation,
      annotations: readings,
    );
  }

  List<Lyric> _buildDisplayedLyrics({
    required LyricsResult lyricsResult,
    required LyricsResult? translationResult,
    required bool richSyncEnabled,
    required bool translationEnabled,
    required int translationAlignmentThreshold,
  }) {
    List<Lyric> baseLyrics;
    if (richSyncEnabled) {
      baseLyrics = lyricsResult.lyrics;
    } else if (LyricsDisplayHelper.canReuseStrippedLyrics(
      cachedStrippedLyrics: _cachedStrippedLyrics,
      lastLyricsResultForStripping: _lastLyricsResultForStripping,
      lyricsResult: lyricsResult,
    )) {
      baseLyrics = _cachedStrippedLyrics!;
    } else {
      baseLyrics = LyricsDisplayHelper.buildDisplayedLyrics(
        lyricsResult: lyricsResult,
        richSyncEnabled: false,
      );
      _cachedStrippedLyrics = baseLyrics;
      _lastLyricsResultForStripping = lyricsResult;
    }

    if (translationEnabled && translationResult?.rawTranslation != null) {
      if (LyricsDisplayHelper.canReuseAlignedLyrics(
        cachedAlignedLyrics: _cachedAlignedLyrics,
        lastLyricsResultForAlignment: _lastLyricsResultForAlignment,
        lyricsResult: lyricsResult,
        lastTranslationResultForAlignment: _lastTranslationResultForAlignment,
        translationResult: translationResult,
        lastRichSyncEnabledForAlignment: _lastRichSyncEnabledForAlignment,
        richSyncEnabled: richSyncEnabled,
      )) {
        return _cachedAlignedLyrics!;
      }
      _cachedAlignedLyrics = LyricsDisplayHelper.buildDisplayedLyrics(
        lyricsResult: lyricsResult,
        richSyncEnabled: richSyncEnabled,
        translationEnabled: true,
        translationResult: translationResult,
        translationAlignmentThreshold: translationAlignmentThreshold,
      );
      _lastLyricsResultForAlignment = lyricsResult;
      _lastTranslationResultForAlignment = translationResult;
      _lastRichSyncEnabledForAlignment = richSyncEnabled;
      return _cachedAlignedLyrics!;
    }

    return baseLyrics;
  }
}
