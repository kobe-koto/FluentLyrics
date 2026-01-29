import 'dart:math';

class StringSimilarity {
  /// Calculates the Jaro-Winkler similarity between two strings.
  /// Returns a value between 0.0 (no similarity) and 1.0 (exact match).
  static double getJaroWinklerScore(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final jaroScore = _getJaroScore(s1, s2);

    // Calculate common prefix length (max 4)
    int prefixLength = 0;
    final minLen = min(s1.length, s2.length);
    for (int i = 0; i < min(4, minLen); i++) {
      if (s1[i] == s2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    // Standard scaling factor is 0.1
    const double scalingFactor = 0.1;

    return jaroScore + (prefixLength * scalingFactor * (1.0 - jaroScore));
  }

  static double _getJaroScore(String s1, String s2) {
    if (s1 == s2) return 1.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final matchDistance = max(0, (max(len1, len2) ~/ 2) - 1);

    final s1Matches = List<bool>.filled(len1, false);
    final s2Matches = List<bool>.filled(len2, false);

    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < len1; i++) {
      final start = max(0, i - matchDistance);
      final end = min(i + matchDistance + 1, len2);

      for (int k = start; k < end; k++) {
        if (s2Matches[k]) continue;
        if (s1[i] != s2[k]) continue;
        s1Matches[i] = true;
        s2Matches[k] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) k++;
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    final double m = matches.toDouble();
    return ((m / len1) + (m / len2) + ((m - transpositions / 2) / m)) / 3.0;
  }
}
