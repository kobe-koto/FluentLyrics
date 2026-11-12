import '../models/general_translation_request_data.dart';
import '../models/lyric_model.dart';
import '../models/lyric_provider_type.dart';
import 'lyrics_request_scope.dart';
import 'providers/llm_translation_service.dart';
import 'providers/lrclib_service.dart';
import 'providers/lyrics_cache_service.dart';
import 'providers/musixmatch_service.dart';
import 'providers/netease_service.dart';
import 'providers/qqmusic_service.dart';
import 'providers/kugou_service.dart';
import 'providers/youtube_music_service.dart';

class LyricsFetchRequest {
  const LyricsFetchRequest({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.shouldTrimMetadata,
    required this.translationBias,
    this.onStatusUpdate,
    this.onArtworkUrl,
    this.onTranslation,
    this.scope,
  });

  final String title;
  final List<String> artist;
  final String album;
  final int durationSeconds;
  final bool shouldTrimMetadata;
  final int translationBias;
  final Function(String)? onStatusUpdate;
  final Function(String)? onArtworkUrl;
  final Function(LyricsResult)? onTranslation;
  final LyricsRequestScope? scope;
}

class LyricsTranslationRequest {
  const LyricsTranslationRequest({
    required this.data,
    required this.targetLanguage,
    required this.translationBias,
    this.scope,
  });

  final GeneralTranslationRequestData data;
  final String targetLanguage;
  final int translationBias;
  final LyricsRequestScope? scope;
}

/// Timing granularity a source can return. Word- and syllable-level timing
/// both parse into `Lyric.inlineParts`, so they share [inline].
enum LyricsSyncLevel { plain, line, inline }

/// What a source can return at best. Declared per source and used to skip
/// sources that cannot improve on the current result. A declaration means
/// "may return", not "always returns": a source that supports [inline] can
/// still answer with plain lyrics for a given track.
class LyricsSourceCapabilities {
  const LyricsSourceCapabilities({
    this.syncLevels = const {},
    this.bundledTranslation = false,
    this.onDemandTranslation = false,
    this.readings = const {},
  }) : isKnown = true;

  const LyricsSourceCapabilities._unknown()
    : syncLevels = const {
        LyricsSyncLevel.plain,
        LyricsSyncLevel.line,
        LyricsSyncLevel.inline,
      },
      bundledTranslation = true,
      onDemandTranslation = true,
      readings = const {LyricsReadingType.kana, LyricsReadingType.romaji},
      isKnown = false;

  /// Content depends on what was stored (cache) or is undeclared (fakes).
  /// Such a source is never skipped.
  static const unknown = LyricsSourceCapabilities._unknown();

  /// Empty means the source is not a lyrics catalog (e.g. `llm`).
  final Set<LyricsSyncLevel> syncLevels;

  /// Translation delivered through `LyricsFetchRequest.onTranslation`.
  final bool bundledTranslation;

  /// Translation fetched separately through [LyricsSource.fetchTranslation].
  /// Language support is still decided by
  /// [LyricsSource.checkTranslationSupport].
  final bool onDemandTranslation;

  /// Reading tracks (furigana / romanization) shipped next to the lyrics.
  final Set<LyricsReadingType> readings;

  final bool isKnown;

  bool get providesLyrics => syncLevels.isNotEmpty;

  /// Best level this source can contribute under the current settings.
  /// Inline timing only counts as better than line timing when rich sync is
  /// enabled, matching `selectBetterCandidate`.
  LyricsSyncLevel? maxSyncLevel({required bool richSyncEnabled}) {
    if (syncLevels.contains(LyricsSyncLevel.inline)) {
      return richSyncEnabled ? LyricsSyncLevel.inline : LyricsSyncLevel.line;
    }
    if (syncLevels.contains(LyricsSyncLevel.line)) return LyricsSyncLevel.line;
    if (syncLevels.contains(LyricsSyncLevel.plain)) {
      return LyricsSyncLevel.plain;
    }
    return null;
  }
}

/// Declared capabilities per provider. Exhaustive so a new
/// [LyricProviderType] must declare what it can return. Readable without a
/// service instance, e.g. by settings UI.
LyricsSourceCapabilities declaredCapabilitiesFor(LyricProviderType type) {
  return switch (type) {
    LyricProviderType.lrclib => const LyricsSourceCapabilities(
      syncLevels: {LyricsSyncLevel.plain, LyricsSyncLevel.line},
    ),
    LyricProviderType.musixmatch => const LyricsSourceCapabilities(
      syncLevels: {LyricsSyncLevel.line, LyricsSyncLevel.inline},
      onDemandTranslation: true,
    ),
    LyricProviderType.netease => const LyricsSourceCapabilities(
      syncLevels: {
        LyricsSyncLevel.plain,
        LyricsSyncLevel.line,
        LyricsSyncLevel.inline,
      },
      bundledTranslation: true,
      onDemandTranslation: true,
      readings: {LyricsReadingType.kana, LyricsReadingType.romaji},
    ),
    LyricProviderType.qqmusic => const LyricsSourceCapabilities(
      syncLevels: {
        LyricsSyncLevel.plain,
        LyricsSyncLevel.line,
        LyricsSyncLevel.inline,
      },
      bundledTranslation: true,
      onDemandTranslation: true,
      readings: {LyricsReadingType.kana, LyricsReadingType.romaji},
    ),
    LyricProviderType.kugou => const LyricsSourceCapabilities(
      syncLevels: {
        LyricsSyncLevel.plain,
        LyricsSyncLevel.line,
        LyricsSyncLevel.inline,
      },
    ),
    LyricProviderType.youtubeMusic => const LyricsSourceCapabilities(
      syncLevels: {LyricsSyncLevel.plain, LyricsSyncLevel.line},
    ),
    // Cached rows can hold any provider's payload.
    LyricProviderType.cache => LyricsSourceCapabilities.unknown,
    LyricProviderType.llm => const LyricsSourceCapabilities(
      onDemandTranslation: true,
    ),
  };
}

abstract class LyricsSource {
  LyricProviderType get type;

  LyricsSourceCapabilities get capabilities => LyricsSourceCapabilities.unknown;

  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request);

  bool checkTranslationSupport(String language) => false;

  Future<LyricsResult> fetchTranslation(
    LyricsTranslationRequest request,
  ) async {
    return LyricsResult.empty();
  }
}

class LyricsSourceRegistry {
  LyricsSourceRegistry({required Iterable<LyricsSource> sources})
    : _sources = {for (final source in sources) source.type: source};

  factory LyricsSourceRegistry.fromServices({
    required LrclibService lrclibService,
    required MusixmatchService musixmatchService,
    required NeteaseService neteaseService,
    required QQMusicService qqMusicService,
    required KugouService kugouService,
    required YoutubeMusicService youtubeMusicService,
    required LlmTranslationService llmService,
    required LyricsCacheService cacheService,
  }) {
    return LyricsSourceRegistry(
      sources: [
        CacheLyricsSource(cacheService),
        LrclibLyricsSource(lrclibService),
        MusixmatchLyricsSource(musixmatchService),
        NeteaseLyricsSource(neteaseService),
        QQMusicLyricsSource(qqMusicService),
        KugouLyricsSource(kugouService),
        YoutubeMusicLyricsSource(youtubeMusicService),
        LlmLyricsSource(llmService),
      ],
    );
  }

  final Map<LyricProviderType, LyricsSource> _sources;

  LyricsSource? sourceFor(LyricProviderType type) => _sources[type];
}

class CacheLyricsSource extends LyricsSource {
  CacheLyricsSource(this._service);

  final LyricsCacheService _service;

  @override
  LyricProviderType get type => LyricProviderType.cache;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      album: request.album,
      durationSeconds: request.durationSeconds,
    );
  }
}

class LrclibLyricsSource extends LyricsSource {
  LrclibLyricsSource(this._service);

  final LrclibService _service;

  @override
  LyricProviderType get type => LyricProviderType.lrclib;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      album: request.album,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      scope: request.scope,
    );
  }
}

class MusixmatchLyricsSource extends LyricsSource {
  MusixmatchLyricsSource(this._service);

  final MusixmatchService _service;

  @override
  LyricProviderType get type => LyricProviderType.musixmatch;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      scope: request.scope,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      request.targetLanguage,
      scope: request.scope,
    );
  }
}

class NeteaseLyricsSource extends LyricsSource {
  NeteaseLyricsSource(this._service);

  final NeteaseService _service;

  @override
  LyricProviderType get type => LyricProviderType.netease;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      translationBias: request.translationBias,
      onTranslation: request.onTranslation,
      scope: request.scope,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      translationBias: request.translationBias,
      scope: request.scope,
    );
  }
}

class QQMusicLyricsSource extends LyricsSource {
  QQMusicLyricsSource(this._service);

  final QQMusicService _service;

  @override
  LyricProviderType get type => LyricProviderType.qqmusic;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      translationBias: request.translationBias,
      onTranslation: request.onTranslation,
      scope: request.scope,
    );
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      translationBias: request.translationBias,
      scope: request.scope,
    );
  }
}

class KugouLyricsSource extends LyricsSource {
  KugouLyricsSource(this._service);

  final KugouService _service;

  @override
  LyricProviderType get type => LyricProviderType.kugou;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      onArtworkUrl: request.onArtworkUrl,
      trimMetadata: request.shouldTrimMetadata,
      scope: request.scope,
    );
  }
}

class YoutubeMusicLyricsSource extends LyricsSource {
  YoutubeMusicLyricsSource(this._service);

  final YoutubeMusicService _service;

  @override
  LyricProviderType get type => LyricProviderType.youtubeMusic;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) {
    return _service.fetchLyrics(
      title: request.title,
      artist: request.artist,
      durationSeconds: request.durationSeconds,
      onStatusUpdate: request.onStatusUpdate,
      scope: request.scope,
    );
  }
}

class LlmLyricsSource extends LyricsSource {
  LlmLyricsSource(this._service);

  final LlmTranslationService _service;

  @override
  LyricProviderType get type => LyricProviderType.llm;

  @override
  LyricsSourceCapabilities get capabilities => declaredCapabilitiesFor(type);

  @override
  Future<LyricsResult> fetchLyrics(LyricsFetchRequest request) async {
    return LyricsResult.empty();
  }

  @override
  bool checkTranslationSupport(String language) {
    return _service.checkTranslationSupport(language);
  }

  @override
  Future<LyricsResult> fetchTranslation(LyricsTranslationRequest request) {
    return _service.fetchTranslation(
      request.data,
      request.targetLanguage,
      scope: request.scope,
    );
  }
}
