import 'package:string_similarity/string_similarity.dart';
import '../models/lyric_model.dart';
import 'app_logger.dart';

class TranslationHelper {
  static const int maxIndexMove = 3;

  static List<Map<String, String>> pair({
    required List<Lyric> originalLyrics,
    required List<Lyric> translatedLyrics,
    int translationBias = 0,
  }) {
    final List<Map<String, String>> rawTranslation = [];
    // Try to pair with original lyrics based on timestamps
    int nextSearchStartIndex = 0;
    for (var transLine in translatedLyrics) {
      // Find matching original line
      Lyric? bestMatch;

      // 1. Try perfect match first
      for (int i = nextSearchStartIndex; i < originalLyrics.length; i++) {
        final l = originalLyrics[i];
        if (l.startTime.inMilliseconds == transLine.startTime.inMilliseconds) {
          bestMatch = l;
          nextSearchStartIndex = i;
          break;
        }
      }

      // 2. If no perfect match, find closest within tolerance, if strict mode is not enabled (!=0)
      if (bestMatch == null && translationBias != 0) {
        // Use bias magnitude as tolerance window
        final int tolerance = translationBias.abs();
        int minDiff = tolerance;
        for (int i = nextSearchStartIndex; i < originalLyrics.length; i++) {
          final l = originalLyrics[i];
          final diff =
              (l.startTime.inMilliseconds - transLine.startTime.inMilliseconds)
                  .abs();

          if (bestMatch != null && diff > tolerance) {
            // already found a best match, and the current line is outside the tolerance window, so break
            break;
          }

          if (diff <= minDiff) {
            minDiff = diff.toInt();
            bestMatch = l;
            nextSearchStartIndex = i;
          }
        }
      }

      if (bestMatch != null && bestMatch.text.isNotEmpty) {
        rawTranslation.add({
          'original': bestMatch.text,
          'translated': transLine.text,
        });
      }
    }
    return rawTranslation;
  }

  static List<Lyric> align({
    required List<Lyric> originalLyrics,
    required List<Map<String, String>> rawTranslation,
    int similarityThreshold = 80,
  }) {
    if (originalLyrics.isEmpty || rawTranslation.isEmpty) {
      return originalLyrics;
    }

    // debugPrint('rawTranslation: $rawTranslation');

    final List<Lyric> newLyrics = [];
    int nextSearchStartIndex = 0;

    for (var line in originalLyrics) {
      bool matched = false;

      if (line.text.isNotEmpty) {
        for (int i = nextSearchStartIndex; i < rawTranslation.length; i++) {
          final originalText = rawTranslation[i]['original'] ?? '';
          final translatedText = rawTranslation[i]['translated'] ?? '';
          final similarity = _calcLineSimilarity(line.text, originalText);
          // debugPrint(
          //   'similarity: $similarity for current "${line.text}" and source "$originalText"',
          // );

          if (similarity > similarityThreshold) {
            // debugPrint('Match found, transLine: "$translatedText"');
            newLyrics.add(
              Lyric(
                startTime: line.startTime,
                endTime: line.endTime,
                text: line.text,
                inlineParts: line.inlineParts,
                translation: translatedText,
              ),
            );
            if ((i + 1 - nextSearchStartIndex) < maxIndexMove) {
              nextSearchStartIndex = i + 1;
            }
            matched = true;
            break;
          }
        }
      }

      if (!matched) {
        newLyrics.add(line);
      }
    }

    return newLyrics;
  }

  /// Counts how many non-empty lines in [currentLyrics] receive a translation
  /// when paired against [rawTranslation]. Returns `(matched, totalLines)`
  /// where `totalLines` is the number of contentful lines in [currentLyrics].
  static (int matched, int totalLines) coverage({
    required List<Lyric> currentLyrics,
    required List<Map<String, String>> rawTranslation,
    int similarityThreshold = 80,
  }) {
    final contentfulLines = _contentfulLines(currentLyrics);
    final totalLines = contentfulLines.length;
    if (totalLines == 0 || rawTranslation.isEmpty) return (0, totalLines);

    final matched = _countMatches(
      contentfulLines: contentfulLines,
      rawTranslation: rawTranslation,
      similarityThreshold: similarityThreshold,
    );
    return (matched, totalLines);
  }

  /// Returns `true` when [rawTranslation]'s original lines align with
  /// [currentLyrics] well enough that the coverage ratio meets
  /// [coverageThreshold] (interpreted as a percentage), where each line is
  /// considered matched when its similarity exceeds [perLineSimilarityThreshold].
  /// Used to decide whether an existing translation is still valid for a new
  /// lyrics result.
  static bool hasSufficientCoverage({
    required List<Lyric> currentLyrics,
    required List<Map<String, String>>? rawTranslation,
    required int coverageThreshold,
    required int perLineSimilarityThreshold,
  }) {
    if (rawTranslation == null || rawTranslation.isEmpty) return false;
    final contentfulLines = _contentfulLines(currentLyrics);
    final totalLines = contentfulLines.length;
    if (totalLines == 0) return false;
    if (coverageThreshold <= 0) return true;

    // matched * 100 ~/ totalLines >= threshold
    //   <=> matched >= ceil(threshold * totalLines / 100).
    final requiredMatched =
        (coverageThreshold * totalLines + 99) ~/ 100;
    final matched = _countMatches(
      contentfulLines: contentfulLines,
      rawTranslation: rawTranslation,
      similarityThreshold: perLineSimilarityThreshold,
      earlyExitTarget: requiredMatched,
    );
    return matched >= requiredMatched;
  }

  static List<Lyric> _contentfulLines(List<Lyric> lyrics) {
    final out = <Lyric>[];
    for (final l in lyrics) {
      if (l.text.trim().isNotEmpty) out.add(l);
    }
    return out;
  }

  /// Walks [contentfulLines] in order and counts how many pair against
  /// [rawTranslation] above [similarityThreshold]. Mirrors [align]'s pairing
  /// logic without allocating a result `List<Lyric>`. When [earlyExitTarget]
  /// is supplied, stops as soon as the answer is determined — either the
  /// target is reached or the remaining lines can no longer reach it.
  static int _countMatches({
    required List<Lyric> contentfulLines,
    required List<Map<String, String>> rawTranslation,
    required int similarityThreshold,
    int? earlyExitTarget,
  }) {
    final n = contentfulLines.length;
    int matched = 0;
    int nextSearchStartIndex = 0;
    for (int idx = 0; idx < n; idx++) {
      // Normalize the outer line once per outer iteration instead of once per
      // (outer, inner) pair.
      final cleanLine = contentfulLines[idx].text.toLowerCase().trim();
      if (cleanLine.isNotEmpty) {
        for (int i = nextSearchStartIndex; i < rawTranslation.length; i++) {
          final originalText = rawTranslation[i]['original'] ?? '';
          final similarity = _calcLineSimilarityFromClean(
            cleanLine,
            originalText,
          );
          if (similarity > similarityThreshold) {
            matched++;
            if ((i + 1 - nextSearchStartIndex) < maxIndexMove) {
              nextSearchStartIndex = i + 1;
            }
            break;
          }
        }
      }
      if (earlyExitTarget != null) {
        if (matched >= earlyExitTarget) return matched;
        final remaining = n - idx - 1;
        if (matched + remaining < earlyExitTarget) return matched;
      }
    }
    return matched;
  }

  static int _calcLineSimilarity(String line1, String line2) {
    if (line1.isEmpty || line2.isEmpty) return 0;
    final clean1 = line1.toLowerCase().trim();
    if (clean1.isEmpty) return 0;
    return _calcLineSimilarityFromClean(clean1, line2);
  }

  static int _calcLineSimilarityFromClean(String cleanLine1, String line2) {
    if (cleanLine1.isEmpty || line2.isEmpty) return 0;
    final clean2 = line2.toLowerCase().trim();
    if (clean2.isEmpty) return 0;
    try {
      // StringSimilarity.compareTwoStrings returns 0.0 to 1.0
      final similarity = StringSimilarity.compareTwoStrings(cleanLine1, clean2);
      return (similarity * 100).toInt();
    } catch (e) {
      AppLogger.debug('[LyricAligner] Error calculating similarity: $e');
      return 0;
    }
  }
}
