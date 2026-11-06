import '../models/lyric_model.dart';
import '../models/lyric_provider_type.dart';
import '../services/winner_selector.dart';

enum SkippedLyricsSourceState { skipped, fetching, empty }

/// A provider [LyricsService.fetchLyrics] did not query because its declared
/// capabilities could not improve on the chosen result. Shown in the
/// candidate sheet as a non-selectable card with a manual fetch action.
class SkippedLyricsSource {
  const SkippedLyricsSource({
    required this.provider,
    required this.reason,
    this.state = SkippedLyricsSourceState.skipped,
  });

  final LyricProviderType provider;
  final LyricsSkipReason reason;
  final SkippedLyricsSourceState state;

  SkippedLyricsSource withState(SkippedLyricsSourceState state) =>
      SkippedLyricsSource(provider: provider, reason: reason, state: state);
}

/// Adds or replaces the entry for [entry.provider], keeping list order.
List<SkippedLyricsSource> upsertSkippedSource(
  List<SkippedLyricsSource> entries,
  SkippedLyricsSource entry,
) {
  final index = entries.indexWhere((e) => e.provider == entry.provider);
  if (index < 0) return List.unmodifiable([...entries, entry]);
  return List.unmodifiable([...entries]..[index] = entry);
}

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
        existing.failureMessage == candidate.failureMessage &&
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
        existing.isRichSync == candidate.isRichSync &&
        existing.failureMessage == candidate.failureMessage,
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
