import '../models/lyric_provider_type.dart';

class AppDefaults {
  static const int linesBefore = 1;
  static const int globalOffsetMs = 0;
  static const int scrollAutoResumeDelay = 5;
  static const bool blurEnabled = true;
  static const bool richSyncEnabled = true;
  static const List<LyricProviderType> trimMetadataProviders = [
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
  ];
  static const double fontSize = 36.0;
  static const double inactiveScale = 0.85;
  static const List<LyricProviderType> providerPriority = [
    LyricProviderType.musixmatch,
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
    LyricProviderType.lrclib,
    LyricProviderType.llm,
  ];
  static const int enabledProviderCount = 3;
  static const bool cacheEnabled = true;
  static const bool translationEnabled = false;
  static const List<String> translationTargetLanguages = ['zht', 'zh_CN'];
  static const bool translationHighlightOnly = true;
  static const List<String> translationIgnoredLanguages = [];
  static const int translationBias = 50;
  static const int translationAlignmentThreshold = 80;
  static const int translationCoverageThreshold = 80;
  static const String? musixmatchToken = null;
  static const String llmApiEndpoint = 'https://dummy.endpoint.example/v1';
  static const String llmApiKey = 'sk-dummy';
  static const String llmModel = 'gpt-oss-120b';
  static const String llmReasoningEffort = 'auto';
  static const bool keepScreenOn = true;
  static const bool backgroundMotionEnabled = true;
  static const bool experimentalRichInlineFontSizeGlitching = false;
  static const bool trayEnabled = false;
  static const bool hideToTrayOnClose = false;
  static const String lyricsStreamPath = '';
  static const String translationStreamPath = '';
  static const int artworkMinSize = 300;
}
