import '../models/lyric_provider_type.dart';

class AppDefaults {
  static const int linesBefore = 1;
  static const int globalOffsetMs = 0;
  static const int scrollAutoResumeDelay = 5;
  static const bool blurEnabled = true;
  static const bool richSyncEnabled = true;
  static const List<LyricProviderType> trimMetadataProviders = [
    LyricProviderType.netease,
  ];
  static const double fontSize = 36.0;
  static const double inactiveScale = 0.85;
  static const List<LyricProviderType> providerPriority = [
    LyricProviderType.lrclib,
    LyricProviderType.musixmatch,
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
  ];
  static const int enabledProviderCount = 3;
  static const bool cacheEnabled = true;
  static const String? musixmatchToken = null;
}
