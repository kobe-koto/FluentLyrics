import '../models/lyric_model.dart';

/// Deduplicated append of a reading track candidate, mirroring
/// [appendTranslationCandidateIfNeeded].
///
/// Returns [candidates] unchanged (identical instance) when [candidate] is
/// already covered, so callers can use identity to detect a no-op.
List<LyricsReading> appendReadingCandidateIfNeeded(
  List<LyricsReading> candidates,
  LyricsReading candidate,
) {
  if (candidate.isEmpty) return candidates;
  final isDuplicate = candidates.any(
    (existing) =>
        existing.lineType == candidate.lineType &&
        existing.kanaRaw == candidate.kanaRaw &&
        _linesEqual(existing.lines, candidate.lines),
  );
  if (isDuplicate) return candidates;
  return List.unmodifiable([...candidates, candidate]);
}

bool _linesEqual(List<Lyric> left, List<Lyric> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i].startTime != right[i].startTime) return false;
    if (left[i].text != right[i].text) return false;
  }
  return true;
}
