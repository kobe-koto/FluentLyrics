import '../models/lyric_model.dart';

LyricsResult? selectBetterCandidate(
  LyricsResult candidate,
  LyricsResult? best,
  bool richSyncEnabled,
) {
  if (best == null) {
    return candidate.copyWith(
      lyrics: candidate.lyrics,
      source: candidate.source,
      isSynced: candidate.isSynced,
      writtenBy: candidate.writtenBy,
      composer: candidate.composer,
      contributor: candidate.contributor,
      copyright: candidate.copyright,
      isPureMusic: candidate.isPureMusic,
      artworkUrls: candidate.artworkUrls,
    );
  }

  final bool candidateIsBetter;
  if (candidate.isPureMusic && !best.isPureMusic) {
    candidateIsBetter = false;
  } else if (candidate.lyrics.isNotEmpty && best.lyrics.isEmpty) {
    candidateIsBetter = true;
  } else if (candidate.lyrics.isNotEmpty &&
      candidate.isRichSync &&
      richSyncEnabled &&
      !best.isRichSync) {
    candidateIsBetter = true;
  } else if (candidate.lyrics.isNotEmpty &&
      candidate.isSynced &&
      !best.isSynced) {
    candidateIsBetter = true;
  } else {
    candidateIsBetter = false;
  }

  if (!candidateIsBetter) {
    return best;
  }

  return candidate.copyWith(
    lyrics: candidate.lyrics,
    source: candidate.source,
    isSynced: candidate.isSynced,
    writtenBy: candidate.writtenBy,
    composer: candidate.composer,
    contributor: candidate.contributor,
    copyright: candidate.copyright,
    isPureMusic: candidate.isPureMusic,
    artworkUrls: candidate.artworkUrls,
  );
}

bool hasGoodEnoughLyricsResult(
  LyricsResult? best,
  bool richSyncEnabled,
  bool translationEnabled,
  bool translationReceived,
) {
  return best != null &&
      (best.isPureMusic ||
          (best.lyrics.isNotEmpty &&
              ((best.isRichSync && richSyncEnabled) ||
                  (!richSyncEnabled && best.isSynced)))) &&
      ((translationEnabled && translationReceived) || !translationEnabled);
}
