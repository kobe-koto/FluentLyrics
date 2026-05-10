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
  /// when paired against [rawTranslation] using [align]. Returns
  /// `(matched, totalLines)` where `totalLines` is the number of contentful
  /// lines in [currentLyrics].
  static (int matched, int totalLines) coverage({
    required List<Lyric> currentLyrics,
    required List<Map<String, String>> rawTranslation,
    int similarityThreshold = 80,
  }) {
    final contentfulLines = currentLyrics
        .where((l) => l.text.trim().isNotEmpty)
        .toList();
    final totalLines = contentfulLines.length;
    if (totalLines == 0 || rawTranslation.isEmpty) return (0, totalLines);

    final aligned = align(
      originalLyrics: contentfulLines,
      rawTranslation: rawTranslation,
      similarityThreshold: similarityThreshold,
    );
    final matched = aligned.where((l) => l.translation != null).length;
    return (matched, totalLines);
  }

  /// Returns `true` when [rawTranslation]'s original lines align with
  /// [currentLyrics] well enough that the coverage ratio meets
  /// [similarityThreshold] (interpreted as a percentage). Used to decide
  /// whether an existing translation is still valid for a new lyrics result.
  static bool hasSufficientCoverage({
    required List<Lyric> currentLyrics,
    required List<Map<String, String>>? rawTranslation,
    required int similarityThreshold,
  }) {
    if (rawTranslation == null || rawTranslation.isEmpty) return false;
    final (matched, totalLines) = coverage(
      currentLyrics: currentLyrics,
      rawTranslation: rawTranslation,
      similarityThreshold: similarityThreshold,
    );
    if (totalLines == 0) return false;
    final coveragePercent = matched * 100 ~/ totalLines;
    return coveragePercent >= similarityThreshold;
  }

  static int _calcLineSimilarity(String line1, String line2) {
    if (line1.isEmpty || line2.isEmpty) return 0;

    // 1. Simple normalization
    String clean1 = line1.toLowerCase().trim();
    String clean2 = line2.toLowerCase().trim();

    if (clean1.isEmpty || clean2.isEmpty) return 0;

    // 2. Calculate similarity (0-100)
    try {
      // StringSimilarity.compareTwoStrings returns 0.0 to 1.0
      final similarity = StringSimilarity.compareTwoStrings(clean1, clean2);
      return (similarity * 100).toInt();
    } catch (e) {
      AppLogger.debug('[LyricAligner] Error calculating similarity: $e');
      return 0;
    }
  }
}
