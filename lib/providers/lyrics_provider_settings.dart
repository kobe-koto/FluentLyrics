import '../constants/app_defaults.dart';
import '../models/lyric_provider_type.dart';
import '../models/setting.dart';
import '../services/settings_service.dart';

class LyricsProviderSettings {
  LyricsProviderSettings({
    required this.cacheEnabled,
    required this.linesBefore,
    required this.globalOffsetMs,
    required this.scrollAutoResumeDelay,
    required this.blurEnabled,
    required this.richSyncEnabled,
    required this.trimMetadataProviders,
    required this.fontSize,
    required this.inactiveScale,
    required this.translationHighlightOnly,
    required this.translationEnabled,
    required this.translationTargetLanguages,
    required this.translationIgnoredLanguages,
    required this.translationBias,
    required this.translationAlignmentThreshold,
    required this.translationCoverageThreshold,
    required this.llmApiEndpoint,
    required this.llmApiKey,
    required this.llmModel,
    required this.llmReasoningEffort,
    required this.keepScreenOn,
    required this.backgroundMotionEnabled,
    required this.experimentalRichInlineFontSizeGlitching,
    required this.trayEnabled,
    required this.hideToTrayOnClose,
    required this.lyricsStreamPath,
    required this.translationStreamPath,
    required this.artworkMinSize,
  });

  factory LyricsProviderSettings.defaults() {
    return LyricsProviderSettings(
      cacheEnabled: const Setting(
        current: AppDefaults.cacheEnabled,
        defaultValue: AppDefaults.cacheEnabled,
        changed: false,
      ),
      linesBefore: const Setting(
        current: AppDefaults.linesBefore,
        defaultValue: AppDefaults.linesBefore,
        changed: false,
      ),
      globalOffsetMs: const Setting(
        current: AppDefaults.globalOffsetMs,
        defaultValue: AppDefaults.globalOffsetMs,
        changed: false,
      ),
      scrollAutoResumeDelay: const Setting(
        current: AppDefaults.scrollAutoResumeDelay,
        defaultValue: AppDefaults.scrollAutoResumeDelay,
        changed: false,
      ),
      blurEnabled: const Setting(
        current: AppDefaults.blurEnabled,
        defaultValue: AppDefaults.blurEnabled,
        changed: false,
      ),
      richSyncEnabled: const Setting(
        current: AppDefaults.richSyncEnabled,
        defaultValue: AppDefaults.richSyncEnabled,
        changed: false,
      ),
      trimMetadataProviders: const Setting(
        current: AppDefaults.trimMetadataProviders,
        defaultValue: AppDefaults.trimMetadataProviders,
        changed: false,
      ),
      fontSize: const Setting(
        current: AppDefaults.fontSize,
        defaultValue: AppDefaults.fontSize,
        changed: false,
      ),
      inactiveScale: const Setting(
        current: AppDefaults.inactiveScale,
        defaultValue: AppDefaults.inactiveScale,
        changed: false,
      ),
      translationHighlightOnly: const Setting(
        current: AppDefaults.translationHighlightOnly,
        defaultValue: AppDefaults.translationHighlightOnly,
        changed: false,
      ),
      translationEnabled: const Setting(
        current: AppDefaults.translationEnabled,
        defaultValue: AppDefaults.translationEnabled,
        changed: false,
      ),
      translationTargetLanguages: const Setting(
        current: AppDefaults.translationTargetLanguages,
        defaultValue: AppDefaults.translationTargetLanguages,
        changed: false,
      ),
      translationIgnoredLanguages: const Setting(
        current: AppDefaults.translationIgnoredLanguages,
        defaultValue: AppDefaults.translationIgnoredLanguages,
        changed: false,
      ),
      translationBias: const Setting(
        current: AppDefaults.translationBias,
        defaultValue: AppDefaults.translationBias,
        changed: false,
      ),
      translationAlignmentThreshold: const Setting(
        current: AppDefaults.translationAlignmentThreshold,
        defaultValue: AppDefaults.translationAlignmentThreshold,
        changed: false,
      ),
      translationCoverageThreshold: const Setting(
        current: AppDefaults.translationCoverageThreshold,
        defaultValue: AppDefaults.translationCoverageThreshold,
        changed: false,
      ),
      llmApiEndpoint: const Setting(
        current: AppDefaults.llmApiEndpoint,
        defaultValue: AppDefaults.llmApiEndpoint,
        changed: false,
      ),
      llmApiKey: const Setting(
        current: AppDefaults.llmApiKey,
        defaultValue: AppDefaults.llmApiKey,
        changed: false,
      ),
      llmModel: const Setting(
        current: AppDefaults.llmModel,
        defaultValue: AppDefaults.llmModel,
        changed: false,
      ),
      llmReasoningEffort: const Setting(
        current: AppDefaults.llmReasoningEffort,
        defaultValue: AppDefaults.llmReasoningEffort,
        changed: false,
      ),
      keepScreenOn: const Setting(
        current: AppDefaults.keepScreenOn,
        defaultValue: AppDefaults.keepScreenOn,
        changed: false,
      ),
      backgroundMotionEnabled: const Setting(
        current: AppDefaults.backgroundMotionEnabled,
        defaultValue: AppDefaults.backgroundMotionEnabled,
        changed: false,
      ),
      experimentalRichInlineFontSizeGlitching: const Setting(
        current: AppDefaults.experimentalRichInlineFontSizeGlitching,
        defaultValue: AppDefaults.experimentalRichInlineFontSizeGlitching,
        changed: false,
      ),
      trayEnabled: const Setting(
        current: AppDefaults.trayEnabled,
        defaultValue: AppDefaults.trayEnabled,
        changed: false,
      ),
      hideToTrayOnClose: const Setting(
        current: AppDefaults.hideToTrayOnClose,
        defaultValue: AppDefaults.hideToTrayOnClose,
        changed: false,
      ),
      lyricsStreamPath: const Setting(
        current: AppDefaults.lyricsStreamPath,
        defaultValue: AppDefaults.lyricsStreamPath,
        changed: false,
      ),
      translationStreamPath: const Setting(
        current: AppDefaults.translationStreamPath,
        defaultValue: AppDefaults.translationStreamPath,
        changed: false,
      ),
      artworkMinSize: const Setting(
        current: AppDefaults.artworkMinSize,
        defaultValue: AppDefaults.artworkMinSize,
        changed: false,
      ),
    );
  }

  static Future<LyricsProviderSettings> load(
    SettingsService settingsService,
  ) async {
    return LyricsProviderSettings(
      cacheEnabled: await settingsService.getCacheEnabled(),
      linesBefore: await settingsService.getLinesBefore(),
      globalOffsetMs: await settingsService.getGlobalOffset(),
      scrollAutoResumeDelay: await settingsService.getScrollAutoResumeDelay(),
      blurEnabled: await settingsService.getBlurEnabled(),
      richSyncEnabled: await settingsService.getRichSyncEnabled(),
      trimMetadataProviders: await settingsService.getTrimMetadataProviders(),
      fontSize: await settingsService.getFontSize(),
      inactiveScale: await settingsService.getInactiveScale(),
      translationHighlightOnly: await settingsService
          .getTranslationHighlightOnly(),
      translationEnabled: await settingsService.getTranslationEnabled(),
      translationTargetLanguages: await settingsService
          .getTranslationTargetLanguages(),
      translationIgnoredLanguages: await settingsService
          .getTranslationIgnoredLanguages(),
      translationBias: await settingsService.getTranslationBias(),
      translationAlignmentThreshold: await settingsService
          .getTranslationAlignmentThreshold(),
      translationCoverageThreshold: await settingsService
          .getTranslationCoverageThreshold(),
      llmApiEndpoint: await settingsService.getLlmApiEndpoint(),
      llmApiKey: await settingsService.getLlmApiKey(),
      llmModel: await settingsService.getLlmModel(),
      llmReasoningEffort: await settingsService.getLlmReasoningEffort(),
      keepScreenOn: await settingsService.getKeepScreenOn(),
      backgroundMotionEnabled: await settingsService
          .getBackgroundMotionEnabled(),
      experimentalRichInlineFontSizeGlitching: await settingsService
          .getExperimentalRichInlineFontSizeGlitching(),
      trayEnabled: await settingsService.getTrayEnabled(),
      hideToTrayOnClose: await settingsService.getHideToTrayOnClose(),
      lyricsStreamPath: await settingsService.getLyricsStreamPath(),
      translationStreamPath: await settingsService.getTranslationStreamPath(),
      artworkMinSize: await settingsService.getArtworkMinSize(),
    );
  }

  Setting<bool> cacheEnabled;
  Setting<int> linesBefore;
  Setting<int> globalOffsetMs;
  Setting<int> scrollAutoResumeDelay;
  Setting<bool> blurEnabled;
  Setting<bool> richSyncEnabled;
  Setting<List<LyricProviderType>> trimMetadataProviders;
  Setting<double> fontSize;
  Setting<double> inactiveScale;
  Setting<bool> translationHighlightOnly;
  Setting<bool> translationEnabled;
  Setting<List<String>> translationTargetLanguages;
  Setting<List<String>> translationIgnoredLanguages;
  Setting<int> translationBias;
  Setting<int> translationAlignmentThreshold;
  Setting<int> translationCoverageThreshold;
  Setting<String> llmApiEndpoint;
  Setting<String> llmApiKey;
  Setting<String> llmModel;
  Setting<String> llmReasoningEffort;
  Setting<bool> keepScreenOn;
  Setting<bool> backgroundMotionEnabled;
  Setting<bool> experimentalRichInlineFontSizeGlitching;
  Setting<bool> trayEnabled;
  Setting<bool> hideToTrayOnClose;
  Setting<String> lyricsStreamPath;
  Setting<String> translationStreamPath;
  Setting<int> artworkMinSize;
}
