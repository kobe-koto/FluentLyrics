import 'package:string_similarity/string_similarity.dart';
import '../models/lyric_model.dart';
import 'app_logger.dart';

/// Merges word-level timing (inlineParts) from a rich-synced source into a
/// regular synced target, producing a new rich-synced result.
///
/// **Strategy (per target line):**
/// 1. Exact timestamp match against any source line.
/// 2. Text-similarity match (threshold configurable, default 70 %).
/// 3. No match → line kept as-is (no inlineParts).
///
/// The merged result keeps the target's line timestamps and text verbatim;
/// only the `inlineParts` field is borrowed from the source.  The borrowed
/// parts are re-anchored to the target line's start time so playback stays
/// correct even when the two sources have slightly different offsets.
class RichifyHelper {
  /// Similarity threshold (0–100) below which a text match is rejected.
  static const int _kDefaultTextThreshold = 70;

  /// Millisecond window for "close-enough" timestamp matching when no exact
  /// match is found.
  static const int _kTimestampToleranceMs = 300;

  /// Applies rich-sync from [richSource] to [syncedTarget].
  ///
  /// Returns a new [LyricsResult] that:
  /// - Keeps every line from [syncedTarget] (same timestamps, same text).
  /// - Copies [LyricInlinePart]s from the best-matching [richSource] line when
  ///   a confident match is found.
  /// - Has [LyricsResult.isRichSync] == `true` (it will be detected
  ///   automatically by [LyricsResult._checkIfRichSynced]).
  ///
  /// [textThreshold] controls the minimum Dice similarity (0–100) required for
  /// a text-based fallback match.
  static LyricsResult apply({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
    int textThreshold = _kDefaultTextThreshold,
  }) {
    final sourceLines = richSource.lyrics;

    final newLyrics = syncedTarget.lyrics.map((targetLine) {
      if (targetLine.text.trim().isEmpty) return targetLine;

      // 1. Exact timestamp match.
      final exactMatch = _findByTimestamp(targetLine, sourceLines, 0);
      if (exactMatch != null && (exactMatch.inlineParts?.isNotEmpty ?? false)) {
        return _mergeInlineParts(targetLine, exactMatch);
      }

      // 2. Nearest-timestamp match within tolerance.
      final nearMatch = _findByTimestamp(
        targetLine,
        sourceLines,
        _kTimestampToleranceMs,
      );
      if (nearMatch != null && (nearMatch.inlineParts?.isNotEmpty ?? false)) {
        // Only accept if texts are also similar enough.
        final sim = _similarity(targetLine.text, nearMatch.text);
        if (sim >= textThreshold) {
          return _mergeInlineParts(targetLine, nearMatch);
        }
      }

      // 3. Text-similarity fallback (scan all source lines).
      Lyric? bestText;
      int bestSim = textThreshold - 1;
      for (final src in sourceLines) {
        if (src.inlineParts == null || src.inlineParts!.isEmpty) continue;
        final s = _similarity(targetLine.text, src.text);
        if (s > bestSim) {
          bestSim = s;
          bestText = src;
        }
      }
      if (bestText != null) {
        return _mergeInlineParts(targetLine, bestText);
      }

      return targetLine; // No match — keep plain.
    }).toList();

    final richCount = newLyrics
        .where((l) => l.inlineParts != null && l.inlineParts!.isNotEmpty)
        .length;
    final totalContent = newLyrics
        .where((l) => l.text.trim().isNotEmpty)
        .length;

    AppLogger.debug(
      '[RichifyHelper] Richified $richCount / $totalContent lines '
      '(source: ${richSource.source}, target: ${syncedTarget.source})',
    );

    if (richCount == 0) {
      // No line survived alignment; don't pretend we produced a rich result.
      return syncedTarget;
    }

    return syncedTarget.copyWith(
      lyrics: newLyrics,
      isRichSync: true,
      source: '${syncedTarget.source} ✨ Richified',
    );
  }

  /// Returns the coverage fraction (0.0–1.0) of how well [richSource] can
  /// enrich [syncedTarget].  Used by the UI to show a quality indicator before
  /// the user commits.
  static double coverage({
    required LyricsResult syncedTarget,
    required LyricsResult richSource,
    int textThreshold = _kDefaultTextThreshold,
  }) {
    final contentLines = syncedTarget.lyrics
        .where((l) => l.text.trim().isNotEmpty)
        .toList();
    if (contentLines.isEmpty) return 0;

    int matched = 0;
    for (final line in contentLines) {
      // Quick exact-timestamp check.
      final src = _findByTimestamp(
        line,
        richSource.lyrics,
        _kTimestampToleranceMs,
      );
      if (src != null && (src.inlineParts?.isNotEmpty ?? false)) {
        final sim = _similarity(line.text, src.text);
        if (sim >= textThreshold || src.startTime == line.startTime) {
          matched++;
          continue;
        }
      }
      // Fallback: text similarity.
      for (final s in richSource.lyrics) {
        if (s.inlineParts == null || s.inlineParts!.isEmpty) continue;
        if (_similarity(line.text, s.text) >= textThreshold) {
          matched++;
          break;
        }
      }
    }
    return matched / contentLines.length;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Lyric? _findByTimestamp(
    Lyric target,
    List<Lyric> source,
    int toleranceMs,
  ) {
    Lyric? best;
    int bestDiff = toleranceMs + 1;
    for (final s in source) {
      final diff =
          (s.startTime.inMilliseconds - target.startTime.inMilliseconds).abs();
      if (diff <= toleranceMs && diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return best;
  }

  /// Minimum fraction (0..1) of [target.text] characters that must align to
  /// [src]'s concatenated parts text for richification to be attempted.  Below
  /// this, source/target are considered different enough that borrowing the
  /// timing would introduce visible text glitches; we keep the line plain.
  static const double _kMinAlignmentRatio = 0.6;

  /// Maximum runtime duration (per inline part) we'll fall back to when a
  /// part collapses to an empty timing slot.  Keeps karaoke highlight visible.
  static const int _kMinPartMs = 1;

  /// Merge [src]'s inline timings onto [target.text].
  ///
  /// The previous implementation copied [src]'s part texts verbatim, which
  /// caused source-only characters (e.g. an extra trailing comma) to leak into
  /// the rendered rich line.  This version keeps [target.text] authoritative
  /// and projects [src]'s timing onto it via a character-level LCS alignment:
  ///
  /// 1. Build `srcText = parts.map((p) => p.text).join()` plus a char→part
  ///    index map.
  /// 2. LCS-align `srcText` to `target.text` using a case/width/punct-tolerant
  ///    equality so trivial cosmetic differences still match.
  /// 3. For each source part, find the target index range it maps to and slice
  ///    [target.text] for that part's new text.  Target chars with no source
  ///    match (e.g. punctuation target has but source lacks) attach to the
  ///    nearest assigned part; source chars with no target match (e.g. the
  ///    comma you don't want leaking through) are silently dropped.
  /// 4. If the alignment ratio drops below [_kMinAlignmentRatio], bail out and
  ///    return [target] without `inlineParts` — the two texts are too
  ///    different to safely borrow timing.
  ///
  /// Timings are re-anchored by `target.startTime - src.startTime` so the
  /// first highlighted glyph fires at the target line's start.
  static Lyric _mergeInlineParts(Lyric target, Lyric src) {
    final srcParts = src.inlineParts!;
    if (srcParts.isEmpty || target.text.isEmpty) {
      return target;
    }

    final offsetMs =
        target.startTime.inMilliseconds - src.startTime.inMilliseconds;
    final lineEndMs = target.endTime?.inMilliseconds;

    // Build srcText + char→partIndex map.
    final srcBuf = StringBuffer();
    final srcCharToPart = <int>[];
    for (int pi = 0; pi < srcParts.length; pi++) {
      final t = srcParts[pi].text;
      for (int ci = 0; ci < t.length; ci++) {
        srcBuf.write(t[ci]);
        srcCharToPart.add(pi);
      }
    }
    final srcText = srcBuf.toString();
    if (srcText.isEmpty) return target;

    // Character-level LCS using tolerant equality.  Indices are raw indices
    // into srcText / target.text.
    final alignment = _lcsAlign(srcText, target.text);
    final matchedChars = alignment.length;
    final ratio = matchedChars / target.text.length;
    if (ratio < _kMinAlignmentRatio) {
      // Too different — give up rich timing for this line.
      return Lyric(
        startTime: target.startTime,
        endTime: target.endTime,
        text: target.text,
        translation: target.translation,
      );
    }

    // Map each target char to a source part via the alignment.
    final assignedPart = List<int>.filled(target.text.length, -1);
    for (final pair in alignment) {
      final rawSrcIdx = pair[0];
      final rawTgtIdx = pair[1];
      if (rawSrcIdx < 0 || rawSrcIdx >= srcCharToPart.length) continue;
      if (rawTgtIdx < 0 || rawTgtIdx >= assignedPart.length) continue;
      assignedPart[rawTgtIdx] = srcCharToPart[rawSrcIdx];
    }

    // Forward/backward fill unassigned target chars onto the nearest
    // assigned part so every char is owned by some part.
    int firstAssigned = -1;
    for (int ti = 0; ti < target.text.length; ti++) {
      if (assignedPart[ti] != -1) {
        firstAssigned = assignedPart[ti];
        break;
      }
    }
    if (firstAssigned == -1) {
      return Lyric(
        startTime: target.startTime,
        endTime: target.endTime,
        text: target.text,
        translation: target.translation,
      );
    }
    // Backward-fill the head.
    for (int ti = 0; ti < target.text.length; ti++) {
      if (assignedPart[ti] != -1) break;
      assignedPart[ti] = firstAssigned;
    }
    // Forward-fill the rest.
    int lastPart = firstAssigned;
    for (int ti = 0; ti < target.text.length; ti++) {
      if (assignedPart[ti] == -1) {
        assignedPart[ti] = lastPart;
      } else {
        lastPart = assignedPart[ti];
      }
    }

    // Stitch consecutive same-part target chars into new inline parts.
    final newParts = <LyricInlinePart>[];
    int i = 0;
    while (i < target.text.length) {
      final pi = assignedPart[i];
      int j = i + 1;
      while (j < target.text.length && assignedPart[j] == pi) {
        j++;
      }
      final chunk = target.text.substring(i, j);
      final srcPart = srcParts[pi];
      int startMs = srcPart.startTime.inMilliseconds + offsetMs;
      int endMs = srcPart.endTime.inMilliseconds + offsetMs;
      if (startMs < 0) startMs = 0;
      if (endMs < startMs + _kMinPartMs) endMs = startMs + _kMinPartMs;
      if (lineEndMs != null && endMs > lineEndMs) endMs = lineEndMs;
      if (lineEndMs != null && startMs > lineEndMs) startMs = lineEndMs;
      newParts.add(
        LyricInlinePart(
          startTime: Duration(milliseconds: startMs),
          endTime: Duration(milliseconds: endMs),
          text: chunk,
        ),
      );
      i = j;
    }

    // Enforce monotonic startTimes so the karaoke highlight always advances.
    for (int k = 1; k < newParts.length; k++) {
      if (newParts[k].startTime < newParts[k - 1].startTime) {
        final fixedStart = newParts[k - 1].startTime;
        final fixedEnd = newParts[k].endTime < fixedStart
            ? fixedStart + const Duration(milliseconds: _kMinPartMs)
            : newParts[k].endTime;
        newParts[k] = LyricInlinePart(
          startTime: fixedStart,
          endTime: fixedEnd,
          text: newParts[k].text,
        );
      }
    }

    return Lyric(
      startTime: target.startTime,
      endTime: target.endTime,
      text: target.text,
      inlineParts: newParts,
      translation: target.translation,
    );
  }

  /// Tolerant per-char equality: case-insensitive + folds common CJK
  /// punctuation to ASCII equivalents so 「，」 matches "," etc.
  static bool _charsMatch(String a, String b) {
    if (a == b) return true;
    return _fold(a) == _fold(b);
  }

  static String _fold(String ch) {
    const map = {
      '，': ',',
      '。': '.',
      '！': '!',
      '？': '?',
      '：': ':',
      '；': ';',
      '\u201C': '"', // left double quotation mark
      '\u201D': '"', // right double quotation mark
      '\u2018': "'", // left single quotation mark
      '\u2019': "'", // right single quotation mark
      '（': '(',
      '）': ')',
      '【': '[',
      '】': ']',
      '《': '<',
      '》': '>',
      '、': ',',
      '\u3000': ' ',
    };
    return (map[ch] ?? ch).toLowerCase();
  }

  /// Character-level LCS that returns the list of matched (aIdx, bIdx) pairs
  /// using [_charsMatch] for tolerant equality.  O(N*M) DP; lines are short
  /// (<200 chars) so this stays cheap.
  static List<List<int>> _lcsAlign(String a, String b) {
    final n = a.length;
    final m = b.length;
    if (n == 0 || m == 0) return const [];
    final dp = List<int>.filled((n + 1) * (m + 1), 0);
    int idx(int i, int j) => i * (m + 1) + j;
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (_charsMatch(a[i - 1], b[j - 1])) {
          dp[idx(i, j)] = dp[idx(i - 1, j - 1)] + 1;
        } else {
          final up = dp[idx(i - 1, j)];
          final left = dp[idx(i, j - 1)];
          dp[idx(i, j)] = up >= left ? up : left;
        }
      }
    }
    final pairs = <List<int>>[];
    int i = n, j = m;
    while (i > 0 && j > 0) {
      if (_charsMatch(a[i - 1], b[j - 1])) {
        pairs.add([i - 1, j - 1]);
        i--;
        j--;
      } else if (dp[idx(i - 1, j)] >= dp[idx(i, j - 1)]) {
        i--;
      } else {
        j--;
      }
    }
    return pairs.reversed.toList();
  }

  static int _similarity(String a, String b) {
    final ca = a.toLowerCase().trim();
    final cb = b.toLowerCase().trim();
    if (ca.isEmpty || cb.isEmpty) return 0;
    try {
      return (StringSimilarity.compareTwoStrings(ca, cb) * 100).toInt();
    } catch (_) {
      return 0;
    }
  }
}
