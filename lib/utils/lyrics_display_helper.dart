import '../models/lyric_model.dart';
import 'translation_helper.dart';

class LyricsDisplayHelper {
  const LyricsDisplayHelper._();

  /// Clears line and inline timestamps for the unsynced render test path.
  /// Text, translation, and annotations are kept. Already-clear lines keep
  /// their instance, and an unchanged list is returned as-is.
  static List<Lyric> stripTimestamps(List<Lyric> source) {
    var changed = false;
    final stripped = <Lyric>[];
    for (final lyric in source) {
      final next = _withoutTimestamps(lyric);
      if (!identical(next, lyric)) changed = true;
      stripped.add(next);
    }
    return changed ? stripped : source;
  }

  static Lyric _withoutTimestamps(Lyric lyric) {
    final parts = lyric.inlineParts;
    List<LyricInlinePart>? strippedParts;
    var partsChanged = false;
    if (parts != null) {
      strippedParts = <LyricInlinePart>[
        for (final part in parts)
          if (part.startTime == Duration.zero && part.endTime == Duration.zero)
            part
          else
            LyricInlinePart(
              startTime: Duration.zero,
              endTime: Duration.zero,
              text: part.text,
            ),
      ];
      for (var i = 0; i < parts.length; i++) {
        if (!identical(parts[i], strippedParts[i])) {
          partsChanged = true;
          break;
        }
      }
    }
    final timesClear =
        lyric.startTime == Duration.zero && lyric.endTime == null;
    if (timesClear && !partsChanged) return lyric;
    return Lyric(
      startTime: Duration.zero,
      endTime: null,
      text: lyric.text,
      inlineParts: partsChanged ? strippedParts : parts,
      translation: lyric.translation,
      annotations: lyric.annotations,
    );
  }

  static List<Lyric> stripRichSync(List<Lyric> source) {
    return source.map((lyric) {
      if (lyric.inlineParts != null && lyric.inlineParts!.isNotEmpty) {
        return Lyric(
          startTime: lyric.startTime,
          endTime: lyric.endTime,
          text: lyric.text,
          inlineParts: null,
          translation: lyric.translation,
        );
      }
      return lyric;
    }).toList();
  }

  static List<Lyric> buildDisplayedLyrics({
    required LyricsResult lyricsResult,
    required bool richSyncEnabled,
    bool translationEnabled = false,
    LyricsResult? translationResult,
    int translationAlignmentThreshold = 80,
  }) {
    final baseLyrics = richSyncEnabled
        ? lyricsResult.lyrics
        : stripRichSync(lyricsResult.lyrics);

    if (!translationEnabled || translationResult?.rawTranslation == null) {
      return baseLyrics;
    }

    return TranslationHelper.align(
      originalLyrics: baseLyrics,
      rawTranslation: translationResult!.rawTranslation!,
      similarityThreshold: translationAlignmentThreshold,
    );
  }

  static bool canReuseStrippedLyrics({
    required List<Lyric>? cachedStrippedLyrics,
    required LyricsResult? lastLyricsResultForStripping,
    required LyricsResult lyricsResult,
  }) {
    return cachedStrippedLyrics != null &&
        lastLyricsResultForStripping == lyricsResult;
  }

  static bool canReuseAlignedLyrics({
    required List<Lyric>? cachedAlignedLyrics,
    required LyricsResult? lastLyricsResultForAlignment,
    required LyricsResult lyricsResult,
    required LyricsResult? lastTranslationResultForAlignment,
    required LyricsResult? translationResult,
    required bool? lastRichSyncEnabledForAlignment,
    required bool richSyncEnabled,
  }) {
    return cachedAlignedLyrics != null &&
        lastLyricsResultForAlignment == lyricsResult &&
        lastTranslationResultForAlignment == translationResult &&
        lastRichSyncEnabledForAlignment == richSyncEnabled;
  }

  static bool isInterlude(List<Lyric> lyrics, int currentIndex) {
    if (lyrics.isEmpty) return false;
    if (currentIndex < 0 || currentIndex >= lyrics.length) return false;
    return lyrics[currentIndex].text.trim().isEmpty;
  }

  static double interludeProgressForPosition({
    required List<Lyric> lyrics,
    required int currentIndex,
    required Duration position,
    required Duration globalOffset,
    required Duration trackOffset,
    required Duration interludeOffset,
  }) {
    if (!isInterlude(lyrics, currentIndex)) return 0.0;
    if (currentIndex >= lyrics.length - 1) return 0.0;

    final adjustedPosition = position + globalOffset + trackOffset;
    final currentStartTime = lyrics[currentIndex].startTime;
    final nextStartTime = lyrics[currentIndex + 1].startTime;
    final duration =
        nextStartTime.inMilliseconds -
        currentStartTime.inMilliseconds -
        interludeOffset.inMilliseconds;

    if (duration <= 0) return 0.0;

    return ((adjustedPosition.inMilliseconds -
                currentStartTime.inMilliseconds) /
            duration)
        .clamp(0.0, 1.0);
  }

  static Duration interludeDuration({
    required List<Lyric> lyrics,
    required int currentIndex,
    required Duration interludeOffset,
  }) {
    if (!isInterlude(lyrics, currentIndex)) return Duration.zero;
    if (currentIndex >= lyrics.length - 1) return Duration.zero;

    final currentStartTime = lyrics[currentIndex].startTime;
    final nextStartTime = lyrics[currentIndex + 1].startTime;
    return nextStartTime - currentStartTime - interludeOffset;
  }
}
