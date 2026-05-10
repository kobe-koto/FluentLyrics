import '../models/lyric_model.dart';

bool matchesTranslationTargetLanguage(
  List<String> targetLanguages,
  String language,
) {
  final lowercaseLanguage = language.toLowerCase();
  for (final target in targetLanguages) {
    if (target.toLowerCase() == lowercaseLanguage) {
      return true;
    }
  }
  return false;
}

List<LyricsResult> appendTranslationCandidateIfNeeded(
  List<LyricsResult> candidates,
  LyricsResult candidate,
) {
  final isDuplicate = candidates.any(
    (existing) =>
        existing.translationProvider == candidate.translationProvider &&
        existing.language == candidate.language &&
        existing.source == candidate.source &&
        _rawTranslationEquals(
          existing.rawTranslation,
          candidate.rawTranslation,
        ),
  );
  if (isDuplicate) return candidates;
  return List.unmodifiable([...candidates, candidate]);
}

bool _rawTranslationEquals(
  List<Map<String, String>>? left,
  List<Map<String, String>>? right,
) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return false;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final leftLine = left[i];
    final rightLine = right[i];
    if (leftLine.length != rightLine.length) return false;
    for (final entry in leftLine.entries) {
      if (rightLine[entry.key] != entry.value) return false;
    }
  }
  return true;
}

List<LyricsResult> appendCandidateIfNeeded(
  List<LyricsResult> candidates,
  LyricsResult candidate,
) {
  final isDuplicate = candidates.any(
    (existing) =>
        existing.source == candidate.source &&
        existing.isSynced == candidate.isSynced &&
        existing.isRichSync == candidate.isRichSync,
  );
  if (isDuplicate) return candidates;
  return List.unmodifiable([...candidates, candidate]);
}

LyricsResult prepareLyricsResultForDisplay(LyricsResult result) {
  var prepared = result.trim();
  if (prepared.lyrics.isNotEmpty &&
      prepared.lyrics[0].startTime > const Duration(seconds: 3)) {
    final newLyrics = List<Lyric>.from(prepared.lyrics)
      ..insert(
        0,
        Lyric(
          text: '',
          startTime: Duration.zero,
          endTime: prepared.lyrics[0].startTime,
        ),
      );
    prepared = prepared.copyWith(lyrics: newLyrics);
  }
  return prepared;
}
