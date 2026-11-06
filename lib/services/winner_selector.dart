import '../models/lyric_model.dart';
import 'lyrics_source_registry.dart';

LyricsResult? selectBetterCandidate(
  LyricsResult candidate,
  LyricsResult? best,
  bool richSyncEnabled,
) {
  if (candidate.isFailure) return best;
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
      !best.isFailure &&
      (best.isPureMusic ||
          (best.lyrics.isNotEmpty &&
              ((best.isRichSync && richSyncEnabled) ||
                  (!richSyncEnabled && best.isSynced)))) &&
      ((translationEnabled && translationReceived) || !translationEnabled);
}

/// Effective sync level of [result] under the rich-sync setting.
LyricsSyncLevel effectiveSyncLevel(LyricsResult result, bool richSyncEnabled) {
  if (result.isRichSync && richSyncEnabled) return LyricsSyncLevel.inline;
  if (result.isSynced) return LyricsSyncLevel.line;
  return LyricsSyncLevel.plain;
}

/// Why a lyrics source was not queried.
class LyricsSkipReason {
  const LyricsSkipReason({
    required this.offered,
    required this.current,
    required this.translationMissing,
  });

  /// Best level the skipped source can return under current settings.
  final LyricsSyncLevel offered;

  /// Effective level of the result that was already chosen.
  final LyricsSyncLevel current;

  /// A translation is still wanted, but the source does not bundle one.
  final bool translationMissing;
}

/// Returns a reason when [capabilities] cannot beat [best] under the rules of
/// [selectBetterCandidate] and cannot supply a translation that the
/// early-stop check ([hasGoodEnoughLyricsResult]) is still waiting for.
/// Returns null when the source should be queried.
LyricsSkipReason? lyricsSkipReasonFor({
  required LyricsResult? best,
  required LyricsSourceCapabilities capabilities,
  required bool richSyncEnabled,
  required bool translationEnabled,
  required bool translationReceived,
}) {
  if (!capabilities.isKnown) return null;
  final offered = capabilities.maxSyncLevel(richSyncEnabled: richSyncEnabled);
  if (offered == null) return null;
  if (best == null || best.isFailure || best.lyrics.isEmpty) return null;

  final current = effectiveSyncLevel(best, richSyncEnabled);
  if (offered.index > current.index) return null;

  final translationMissing = translationEnabled && !translationReceived;
  if (translationMissing && capabilities.bundledTranslation) return null;

  return LyricsSkipReason(
    offered: offered,
    current: current,
    translationMissing: translationMissing,
  );
}
