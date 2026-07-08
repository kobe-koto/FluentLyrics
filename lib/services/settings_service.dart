import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import '../constants/app_defaults.dart';

class SettingsService {
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  static const String _priorityKey = 'lyric_provider_priority';
  static const String _musixmatchTokenKey = 'musixmatch_token';
  static const String _linesBeforeKey = 'lines_before';
  static const String _globalOffsetKey = 'global_offset_ms';
  static const String _scrollAutoResumeDelayKey = 'scroll_auto_resume_delay';
  static const String _blurEnabledKey = 'blur_enabled';
  static const String _trimMetadataProvidersKey = 'trim_metadata_providers';
  static const String _enabledCountKey = 'enabled_provider_count';
  static const String _cacheEnabledKey = 'cache_enabled';
  static const String _fontSizeKey = 'font_size';
  static const String _inactiveScaleKey = 'inactive_scale';
  static const String _richSyncEnabledKey = 'rich_sync_enabled';
  static const String _llmEndpointKey = 'llm_api_endpoint';
  static const String _llmApiKeyKey = 'llm_api_key';
  static const String _llmModelKey = 'llm_model';
  static const String _keepScreenOnKey = 'keep_screen_on';
  static const String _backgroundMotionEnabledKey = 'background_motion_enabled';
  static const String _experimentalRichInlineFontSizeGlitchingKey =
      'experimental_rich_inline_font_size_glitching';
  static const String _trayEnabledKey = 'tray_enabled';
  static const String _hideToTrayOnCloseKey = 'hide_to_tray_on_close';
  static const String _lyricsStreamPathKey = 'lyrics_stream_path';
  static const String _translationStreamPathKey = 'translation_stream_path';
  static const String _artworkMinSizeKey = 'artwork_min_size';
  static const String _localeKey = 'app_locale';

  Future<Setting<List<LyricProviderType>>> getAllProvidersOrdered() async {
    final prefs = await _prefs;
    final savedPriority = prefs.getStringList(_priorityKey);

    if (savedPriority == null) {
      return const Setting(
        current: AppDefaults.providerPriority,
        defaultValue: AppDefaults.providerPriority,
        changed: false,
      );
    }

    final savedList = savedPriority
        .map((e) => LyricProviderType.values.where((v) => v.name == e))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .where((v) => v != LyricProviderType.cache)
        .toList();

    // Find missing providers and append them
    final Set<LyricProviderType> savedSet = savedList.toSet();
    for (var provider in LyricProviderType.values) {
      if (provider != LyricProviderType.cache && !savedSet.contains(provider)) {
        savedList.add(provider);
      }
    }

    return Setting(
      current: savedList,
      defaultValue: AppDefaults.providerPriority,
      changed: !listEquals(savedList, AppDefaults.providerPriority),
    );
  }

  Future<Setting<int>> getEnabledCount() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_enabledCountKey) ?? AppDefaults.enabledProviderCount;
    return Setting(
      current: current,
      defaultValue: AppDefaults.enabledProviderCount,
      changed: current != AppDefaults.enabledProviderCount,
    );
  }

  Future<void> setEnabledCount(int count) async {
    final prefs = await _prefs;
    await prefs.setInt(_enabledCountKey, count);
  }

  Future<Setting<bool>> getCacheEnabled() async {
    final prefs = await _prefs;
    final current = prefs.getBool(_cacheEnabledKey) ?? AppDefaults.cacheEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.cacheEnabled,
      changed: current != AppDefaults.cacheEnabled,
    );
  }

  Future<void> setCacheEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_cacheEnabledKey, enabled);
  }

  Future<List<LyricProviderType>> getPriority() async {
    final allOrderedSetting = await getAllProvidersOrdered();
    final enabledCountSetting = await getEnabledCount();
    final cacheEnabledSetting = await getCacheEnabled();

    final allOrdered = allOrderedSetting.current;
    final enabledCount = enabledCountSetting.current;
    final cacheEnabled = cacheEnabledSetting.current;

    final List<LyricProviderType> priority = [];
    if (cacheEnabled) {
      priority.add(LyricProviderType.cache);
    }

    priority.addAll(allOrdered.take(enabledCount));
    return priority;
  }

  Future<void> setPriority(List<LyricProviderType> priority) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _priorityKey,
      priority.map((e) => e.name).toList(),
    );
  }

  Future<Setting<String?>> getMusixmatchToken() async {
    final prefs = await _prefs;
    final current =
        prefs.getString(_musixmatchTokenKey) ?? AppDefaults.musixmatchToken;
    return Setting(
      current: current,
      defaultValue: AppDefaults.musixmatchToken,
      changed: current != AppDefaults.musixmatchToken,
    );
  }

  Future<void> setMusixmatchToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_musixmatchTokenKey, token);
  }

  Future<Setting<int>> getLinesBefore() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_linesBeforeKey) ?? AppDefaults.linesBefore;
    return Setting(
      current: current,
      defaultValue: AppDefaults.linesBefore,
      changed: current != AppDefaults.linesBefore,
    );
  }

  Future<void> setLinesBefore(int lines) async {
    final prefs = await _prefs;
    await prefs.setInt(_linesBeforeKey, lines);
  }

  Future<Setting<int>> getGlobalOffset() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_globalOffsetKey) ?? AppDefaults.globalOffsetMs;
    return Setting(
      current: current,
      defaultValue: AppDefaults.globalOffsetMs,
      changed: current != AppDefaults.globalOffsetMs,
    );
  }

  Future<void> setGlobalOffset(int offsetMs) async {
    final prefs = await _prefs;
    await prefs.setInt(_globalOffsetKey, offsetMs);
  }

  Future<Setting<int>> getScrollAutoResumeDelay() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_scrollAutoResumeDelayKey) ??
        AppDefaults.scrollAutoResumeDelay;
    return Setting(
      current: current,
      defaultValue: AppDefaults.scrollAutoResumeDelay,
      changed: current != AppDefaults.scrollAutoResumeDelay,
    );
  }

  Future<void> setScrollAutoResumeDelay(int seconds) async {
    final prefs = await _prefs;
    await prefs.setInt(_scrollAutoResumeDelayKey, seconds);
  }

  Future<Setting<bool>> getBlurEnabled() async {
    final prefs = await _prefs;
    final current = prefs.getBool(_blurEnabledKey) ?? AppDefaults.blurEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.blurEnabled,
      changed: current != AppDefaults.blurEnabled,
    );
  }

  Future<void> setBlurEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_blurEnabledKey, enabled);
  }

  Future<Setting<List<LyricProviderType>>> getTrimMetadataProviders() async {
    final prefs = await _prefs;
    final saved = prefs.getStringList(_trimMetadataProvidersKey);

    if (saved == null) {
      return const Setting(
        current: AppDefaults.trimMetadataProviders,
        defaultValue: AppDefaults.trimMetadataProviders,
        changed: false,
      );
    }

    final savedList = saved
        .map((e) => LyricProviderType.values.where((v) => v.name == e))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();

    final current = savedList.isEmpty
        ? AppDefaults.trimMetadataProviders
        : savedList;

    return Setting(
      current: current,
      defaultValue: AppDefaults.trimMetadataProviders,
      changed: !listEquals(current, AppDefaults.trimMetadataProviders),
    );
  }

  Future<void> setTrimMetadataProviders(
    List<LyricProviderType> providers,
  ) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      _trimMetadataProvidersKey,
      providers.map((e) => e.name).toList(),
    );
  }

  Future<Setting<double>> getFontSize() async {
    final prefs = await _prefs;
    final current = prefs.getDouble(_fontSizeKey) ?? AppDefaults.fontSize;
    return Setting(
      current: current,
      defaultValue: AppDefaults.fontSize,
      changed: current != AppDefaults.fontSize,
    );
  }

  Future<void> setFontSize(double size) async {
    final prefs = await _prefs;
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<Setting<double>> getInactiveScale() async {
    final prefs = await _prefs;
    final current =
        prefs.getDouble(_inactiveScaleKey) ?? AppDefaults.inactiveScale;
    return Setting(
      current: current,
      defaultValue: AppDefaults.inactiveScale,
      changed: current != AppDefaults.inactiveScale,
    );
  }

  Future<void> setInactiveScale(double scale) async {
    final prefs = await _prefs;
    await prefs.setDouble(_inactiveScaleKey, scale);
  }

  Future<Setting<bool>> getRichSyncEnabled() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_richSyncEnabledKey) ?? AppDefaults.richSyncEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.richSyncEnabled,
      changed: current != AppDefaults.richSyncEnabled,
    );
  }

  Future<void> setRichSyncEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_richSyncEnabledKey, enabled);
  }

  static const String _translationEnabledKey = 'translation_enabled';
  static const String _translationHighlightOnlyKey =
      'translation_highlight_only';
  static const String _translationTargetLanguagesKey =
      'translation_target_languages';

  Future<Setting<bool>> getTranslationEnabled() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_translationEnabledKey) ?? AppDefaults.translationEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationEnabled,
      changed: current != AppDefaults.translationEnabled,
    );
  }

  Future<void> setTranslationEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_translationEnabledKey, enabled);
  }

  Future<Setting<bool>> getTranslationHighlightOnly() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_translationHighlightOnlyKey) ??
        AppDefaults.translationHighlightOnly;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationHighlightOnly,
      changed: current != AppDefaults.translationHighlightOnly,
    );
  }

  Future<void> setTranslationHighlightOnly(bool highlightOnly) async {
    final prefs = await _prefs;
    await prefs.setBool(_translationHighlightOnlyKey, highlightOnly);
  }

  static const String _translationIgnoredLanguagesKey =
      'translation_ignored_languages';
  static const String _translationBiasKey = 'translation_bias';
  static const String _translationAlignmentThresholdKey =
      'translation_alignment_threshold';
  static const String _translationCoverageThresholdKey =
      'translation_coverage_threshold';

  Future<Setting<List<String>>> getTranslationTargetLanguages() async {
    final prefs = await _prefs;
    final current =
        prefs.getStringList(_translationTargetLanguagesKey) ??
        AppDefaults.translationTargetLanguages;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationTargetLanguages,
      changed: !listEquals(current, AppDefaults.translationTargetLanguages),
    );
  }

  Future<void> setTranslationTargetLanguages(List<String> languages) async {
    final prefs = await _prefs;
    if (languages.isEmpty) {
      await prefs.remove(_translationTargetLanguagesKey);
    } else {
      await prefs.setStringList(_translationTargetLanguagesKey, languages);
    }
  }

  Future<Setting<List<String>>> getTranslationIgnoredLanguages() async {
    final prefs = await _prefs;
    final saved = prefs.getStringList(_translationIgnoredLanguagesKey);
    final current = saved ?? AppDefaults.translationIgnoredLanguages;

    return Setting(
      current: current,
      defaultValue: AppDefaults.translationIgnoredLanguages,
      changed: !listEquals(current, AppDefaults.translationIgnoredLanguages),
    );
  }

  Future<void> setTranslationIgnoredLanguages(List<String> languages) async {
    final prefs = await _prefs;
    await prefs.setStringList(_translationIgnoredLanguagesKey, languages);
  }

  Future<Setting<int>> getTranslationBias() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_translationBiasKey) ?? AppDefaults.translationBias;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationBias,
      changed: current != AppDefaults.translationBias,
    );
  }

  Future<void> setTranslationBias(int bias) async {
    final prefs = await _prefs;
    await prefs.setInt(_translationBiasKey, bias);
  }

  Future<Setting<int>> getTranslationAlignmentThreshold() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_translationAlignmentThresholdKey) ??
        AppDefaults.translationAlignmentThreshold;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationAlignmentThreshold,
      changed: current != AppDefaults.translationAlignmentThreshold,
    );
  }

  Future<void> setTranslationAlignmentThreshold(int threshold) async {
    final prefs = await _prefs;
    await prefs.setInt(_translationAlignmentThresholdKey, threshold);
  }

  Future<Setting<int>> getTranslationCoverageThreshold() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_translationCoverageThresholdKey) ??
        AppDefaults.translationCoverageThreshold;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationCoverageThreshold,
      changed: current != AppDefaults.translationCoverageThreshold,
    );
  }

  Future<void> setTranslationCoverageThreshold(int threshold) async {
    final prefs = await _prefs;
    await prefs.setInt(_translationCoverageThresholdKey, threshold);
  }

  Future<Setting<String>> getLlmApiEndpoint() async {
    final prefs = await _prefs;
    final current =
        prefs.getString(_llmEndpointKey) ?? AppDefaults.llmApiEndpoint;

    return Setting(
      current: current,
      defaultValue: AppDefaults.llmApiEndpoint,
      changed: current != AppDefaults.llmApiEndpoint,
    );
  }

  Future<void> setLlmApiEndpoint(String endpoint) async {
    final prefs = await _prefs;
    await prefs.setString(_llmEndpointKey, endpoint);
  }

  Future<Setting<String>> getLlmApiKey() async {
    final prefs = await _prefs;
    final current = prefs.getString(_llmApiKeyKey) ?? AppDefaults.llmApiKey;

    return Setting(
      current: current,
      defaultValue: AppDefaults.llmApiKey,
      changed: current != AppDefaults.llmApiKey,
    );
  }

  Future<void> setLlmApiKey(String apiKey) async {
    final prefs = await _prefs;
    await prefs.setString(_llmApiKeyKey, apiKey);
  }

  Future<Setting<String>> getLlmModel() async {
    final prefs = await _prefs;
    final current = prefs.getString(_llmModelKey) ?? AppDefaults.llmModel;

    return Setting(
      current: current,
      defaultValue: AppDefaults.llmModel,
      changed: current != AppDefaults.llmModel,
    );
  }

  Future<void> setLlmModel(String model) async {
    final prefs = await _prefs;
    await prefs.setString(_llmModelKey, model);
  }

  static const String _llmReasoningEffortKey = 'llm_reasoning_effort';

  Future<Setting<String>> getLlmReasoningEffort() async {
    final prefs = await _prefs;
    final current =
        prefs.getString(_llmReasoningEffortKey) ??
        AppDefaults.llmReasoningEffort;

    return Setting(
      current: current,
      defaultValue: AppDefaults.llmReasoningEffort,
      changed: current != AppDefaults.llmReasoningEffort,
    );
  }

  Future<void> setLlmReasoningEffort(String effort) async {
    final prefs = await _prefs;
    await prefs.setString(_llmReasoningEffortKey, effort);
  }

  Future<Setting<bool>> getKeepScreenOn() async {
    final prefs = await _prefs;
    final current = prefs.getBool(_keepScreenOnKey) ?? AppDefaults.keepScreenOn;

    return Setting(
      current: current,
      defaultValue: AppDefaults.keepScreenOn,
      changed: current != AppDefaults.keepScreenOn,
    );
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keepScreenOnKey, enabled);
  }

  Future<Setting<bool>> getBackgroundMotionEnabled() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_backgroundMotionEnabledKey) ??
        AppDefaults.backgroundMotionEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.backgroundMotionEnabled,
      changed: current != AppDefaults.backgroundMotionEnabled,
    );
  }

  Future<void> setBackgroundMotionEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_backgroundMotionEnabledKey, enabled);
  }

  Future<Setting<bool>> getExperimentalRichInlineFontSizeGlitching() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_experimentalRichInlineFontSizeGlitchingKey) ??
        AppDefaults.experimentalRichInlineFontSizeGlitching;
    return Setting(
      current: current,
      defaultValue: AppDefaults.experimentalRichInlineFontSizeGlitching,
      changed: current != AppDefaults.experimentalRichInlineFontSizeGlitching,
    );
  }

  Future<void> setExperimentalRichInlineFontSizeGlitching(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_experimentalRichInlineFontSizeGlitchingKey, enabled);
  }

  Future<Setting<bool>> getTrayEnabled() async {
    final prefs = await _prefs;
    final current = prefs.getBool(_trayEnabledKey) ?? AppDefaults.trayEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.trayEnabled,
      changed: current != AppDefaults.trayEnabled,
    );
  }

  Future<void> setTrayEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_trayEnabledKey, enabled);
  }

  Future<Setting<bool>> getHideToTrayOnClose() async {
    final prefs = await _prefs;
    final current =
        prefs.getBool(_hideToTrayOnCloseKey) ?? AppDefaults.hideToTrayOnClose;
    return Setting(
      current: current,
      defaultValue: AppDefaults.hideToTrayOnClose,
      changed: current != AppDefaults.hideToTrayOnClose,
    );
  }

  Future<void> setHideToTrayOnClose(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_hideToTrayOnCloseKey, enabled);
  }

  Future<Setting<String>> getLyricsStreamPath() async {
    final prefs = await _prefs;
    final current =
        prefs.getString(_lyricsStreamPathKey) ?? AppDefaults.lyricsStreamPath;
    return Setting(
      current: current,
      defaultValue: AppDefaults.lyricsStreamPath,
      changed: current != AppDefaults.lyricsStreamPath,
    );
  }

  Future<void> setLyricsStreamPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString(_lyricsStreamPathKey, path);
  }

  Future<Setting<String>> getTranslationStreamPath() async {
    final prefs = await _prefs;
    final current =
        prefs.getString(_translationStreamPathKey) ??
        AppDefaults.translationStreamPath;
    return Setting(
      current: current,
      defaultValue: AppDefaults.translationStreamPath,
      changed: current != AppDefaults.translationStreamPath,
    );
  }

  Future<void> setTranslationStreamPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString(_translationStreamPathKey, path);
  }

  Future<Setting<int>> getArtworkMinSize() async {
    final prefs = await _prefs;
    final current =
        prefs.getInt(_artworkMinSizeKey) ?? AppDefaults.artworkMinSize;
    return Setting(
      current: current,
      defaultValue: AppDefaults.artworkMinSize,
      changed: current != AppDefaults.artworkMinSize,
    );
  }

  Future<void> setArtworkMinSize(int size) async {
    final prefs = await _prefs;
    await prefs.setInt(_artworkMinSizeKey, size);
  }

  /// Returns the saved locale tag (e.g. 'en', 'zh_CN'), or null for system default.
  Future<String?> getLocale() async {
    final prefs = await _prefs;
    return prefs.getString(_localeKey);
  }

  Future<void> setLocale(String? localeTag) async {
    final prefs = await _prefs;
    if (localeTag == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, localeTag);
    }
  }
}
