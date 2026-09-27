import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import '../constants/app_defaults.dart';
import 'pref_setting.dart';
import 'secret_migration.dart';
import 'secret_settings.dart';
import 'secret_store.dart';

class SettingsService {
  SettingsService({SecretStore? secretStore})
    : _secrets = SecretSettings(secretStore ?? FlutterSecureSecretStore());

  final SecretSettings _secrets;
  SecretStoreFailure? secretStoreFailure;
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> get _prefs async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  static const String _priorityKey = 'lyric_provider_priority';
  static const String _localeKey = 'app_locale';

  Future<Setting<T>> readSetting<T>(PrefSetting<T> spec) async {
    if (!spec.secure) return spec.settingFrom(await _prefs);
    try {
      return await _readSecure(spec);
    } on SecretStoreException catch (error) {
      secretStoreFailure = error.failure;
      return spec.initial;
    }
  }

  Future<void> writeSetting<T>(PrefSetting<T> spec, T value) async {
    if (spec.secure) {
      await _saveSecret(spec, value is String ? value : null);
      return;
    }
    await spec.save(await _prefs, value);
  }

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

  Future<Setting<int>> getEnabledCount() =>
      readSetting(PrefSettings.enabledProviderCount);

  Future<void> setEnabledCount(int count) =>
      writeSetting(PrefSettings.enabledProviderCount, count);

  Future<Setting<bool>> getCacheEnabled() =>
      readSetting(PrefSettings.cacheEnabled);

  Future<void> setCacheEnabled(bool enabled) =>
      writeSetting(PrefSettings.cacheEnabled, enabled);

  Future<Setting<String?>> getMusixmatchToken() =>
      _readSecure(PrefSettings.musixmatchToken);

  Future<void> setMusixmatchToken(String token) =>
      _saveSecret(PrefSettings.musixmatchToken, token);

  Future<Setting<int>> getLinesBefore() =>
      readSetting(PrefSettings.linesBefore);

  Future<void> setLinesBefore(int lines) =>
      writeSetting(PrefSettings.linesBefore, lines);

  Future<Setting<int>> getLandscapeLeadingSpace() =>
      readSetting(PrefSettings.landscapeLeadingSpace);

  Future<void> setLandscapeLeadingSpace(int percent) =>
      writeSetting(PrefSettings.landscapeLeadingSpace, percent);

  Future<Setting<int>> getRichSyncThresholdMs() =>
      readSetting(PrefSettings.richSyncThresholdMs);

  Future<void> setRichSyncThresholdMs(int ms) =>
      writeSetting(PrefSettings.richSyncThresholdMs, ms);

  Future<Setting<bool>> getAnnotationEnabled() =>
      readSetting(PrefSettings.annotationEnabled);

  Future<void> setAnnotationEnabled(bool enabled) =>
      writeSetting(PrefSettings.annotationEnabled, enabled);

  Future<Setting<int>> getAnnotationBias() =>
      readSetting(PrefSettings.annotationBias);

  Future<void> setAnnotationBias(int ms) =>
      writeSetting(PrefSettings.annotationBias, ms);

  Future<Setting<String>> getZhConversionTarget() =>
      readSetting(PrefSettings.zhConversionTarget);

  Future<void> setZhConversionTarget(String target) =>
      writeSetting(PrefSettings.zhConversionTarget, target);

  Future<Setting<List<String>>> getZhConversionIgnoredLanguages() =>
      readSetting(PrefSettings.zhConversionIgnoredLanguages);

  Future<void> setZhConversionIgnoredLanguages(List<String> languages) =>
      writeSetting(PrefSettings.zhConversionIgnoredLanguages, languages);

  Future<Setting<int>> getGlobalOffset() =>
      readSetting(PrefSettings.globalOffsetMs);

  Future<void> setGlobalOffset(int offsetMs) =>
      writeSetting(PrefSettings.globalOffsetMs, offsetMs);

  Future<Setting<int>> getScrollAutoResumeDelay() =>
      readSetting(PrefSettings.scrollAutoResumeDelay);

  Future<void> setScrollAutoResumeDelay(int seconds) =>
      writeSetting(PrefSettings.scrollAutoResumeDelay, seconds);

  Future<Setting<bool>> getBlurEnabled() =>
      readSetting(PrefSettings.blurEnabled);

  Future<void> setBlurEnabled(bool enabled) =>
      writeSetting(PrefSettings.blurEnabled, enabled);

  Future<Setting<List<LyricProviderType>>> getTrimMetadataProviders() =>
      readSetting(PrefSettings.trimMetadataProviders);

  Future<void> setTrimMetadataProviders(List<LyricProviderType> providers) =>
      writeSetting(PrefSettings.trimMetadataProviders, providers);

  Future<Setting<double>> getFontSize() => readSetting(PrefSettings.fontSize);

  Future<void> setFontSize(double size) =>
      writeSetting(PrefSettings.fontSize, size);

  Future<Setting<double>> getInactiveScale() =>
      readSetting(PrefSettings.inactiveScale);

  Future<void> setInactiveScale(double scale) =>
      writeSetting(PrefSettings.inactiveScale, scale);

  Future<Setting<bool>> getRichSyncEnabled() =>
      readSetting(PrefSettings.richSyncEnabled);

  Future<void> setRichSyncEnabled(bool enabled) =>
      writeSetting(PrefSettings.richSyncEnabled, enabled);

  Future<Setting<bool>> getTranslationEnabled() =>
      readSetting(PrefSettings.translationEnabled);

  Future<void> setTranslationEnabled(bool enabled) =>
      writeSetting(PrefSettings.translationEnabled, enabled);

  Future<Setting<bool>> getTranslationHighlightOnly() =>
      readSetting(PrefSettings.translationHighlightOnly);

  Future<void> setTranslationHighlightOnly(bool highlightOnly) =>
      writeSetting(PrefSettings.translationHighlightOnly, highlightOnly);

  Future<Setting<List<String>>> getTranslationTargetLanguages() =>
      readSetting(PrefSettings.translationTargetLanguages);

  Future<void> setTranslationTargetLanguages(List<String> languages) =>
      writeSetting(PrefSettings.translationTargetLanguages, languages);

  Future<Setting<List<String>>> getTranslationIgnoredLanguages() =>
      readSetting(PrefSettings.translationIgnoredLanguages);

  Future<void> setTranslationIgnoredLanguages(List<String> languages) =>
      writeSetting(PrefSettings.translationIgnoredLanguages, languages);

  Future<Setting<int>> getTranslationBias() =>
      readSetting(PrefSettings.translationBias);

  Future<void> setTranslationBias(int bias) =>
      writeSetting(PrefSettings.translationBias, bias);

  Future<Setting<int>> getTranslationAlignmentThreshold() =>
      readSetting(PrefSettings.translationAlignmentThreshold);

  Future<void> setTranslationAlignmentThreshold(int threshold) =>
      writeSetting(PrefSettings.translationAlignmentThreshold, threshold);

  Future<Setting<int>> getTranslationCoverageThreshold() =>
      readSetting(PrefSettings.translationCoverageThreshold);

  Future<void> setTranslationCoverageThreshold(int threshold) =>
      writeSetting(PrefSettings.translationCoverageThreshold, threshold);

  Future<Setting<String>> getLlmApiEndpoint() =>
      readSetting(PrefSettings.llmApiEndpoint);

  Future<void> setLlmApiEndpoint(String endpoint) =>
      writeSetting(PrefSettings.llmApiEndpoint, endpoint);

  Future<Setting<String>> getLlmApiKey() => _readSecure(PrefSettings.llmApiKey);

  Future<void> setLlmApiKey(String apiKey) =>
      _saveSecret(PrefSettings.llmApiKey, apiKey);

  Future<Setting<String>> getLlmModel() => readSetting(PrefSettings.llmModel);

  Future<void> setLlmModel(String model) =>
      writeSetting(PrefSettings.llmModel, model);

  Future<Setting<String>> getLlmReasoningEffort() =>
      readSetting(PrefSettings.llmReasoningEffort);

  Future<void> setLlmReasoningEffort(String effort) =>
      writeSetting(PrefSettings.llmReasoningEffort, effort);

  Future<Setting<int>> getLlmTimeToFirstTokenSeconds() =>
      readSetting(PrefSettings.llmTimeToFirstTokenSeconds);

  Future<void> setLlmTimeToFirstTokenSeconds(int seconds) =>
      writeSetting(PrefSettings.llmTimeToFirstTokenSeconds, seconds);

  Future<Setting<double>> getLlmMinTokensPerSecond() =>
      readSetting(PrefSettings.llmMinTokensPerSecond);

  Future<void> setLlmMinTokensPerSecond(double tokensPerSecond) =>
      writeSetting(PrefSettings.llmMinTokensPerSecond, tokensPerSecond);

  Future<Setting<bool>> getKeepScreenOn() =>
      readSetting(PrefSettings.keepScreenOn);

  Future<void> setKeepScreenOn(bool enabled) =>
      writeSetting(PrefSettings.keepScreenOn, enabled);

  Future<Setting<bool>> getBackgroundMotionEnabled() =>
      readSetting(PrefSettings.backgroundMotionEnabled);

  Future<void> setBackgroundMotionEnabled(bool enabled) =>
      writeSetting(PrefSettings.backgroundMotionEnabled, enabled);

  Future<Setting<bool>> getExperimentalRichInlineFontSizeGlitching() =>
      readSetting(PrefSettings.experimentalRichInlineFontSizeGlitching);

  Future<void> setExperimentalRichInlineFontSizeGlitching(bool enabled) =>
      writeSetting(
        PrefSettings.experimentalRichInlineFontSizeGlitching,
        enabled,
      );

  Future<Setting<bool>> getExperimentalAnnotationFontSizeGlitching() =>
      readSetting(PrefSettings.experimentalAnnotationFontSizeGlitching);

  Future<void> setExperimentalAnnotationFontSizeGlitching(bool enabled) =>
      writeSetting(
        PrefSettings.experimentalAnnotationFontSizeGlitching,
        enabled,
      );

  Future<Setting<bool>> getTrayEnabled() =>
      readSetting(PrefSettings.trayEnabled);

  Future<void> setTrayEnabled(bool enabled) =>
      writeSetting(PrefSettings.trayEnabled, enabled);

  Future<Setting<bool>> getHideToTrayOnClose() =>
      readSetting(PrefSettings.hideToTrayOnClose);

  Future<void> setHideToTrayOnClose(bool enabled) =>
      writeSetting(PrefSettings.hideToTrayOnClose, enabled);

  Future<Setting<String>> getLyricsStreamPath() =>
      readSetting(PrefSettings.lyricsStreamPath);

  Future<void> setLyricsStreamPath(String path) =>
      writeSetting(PrefSettings.lyricsStreamPath, path);

  Future<Setting<String>> getTranslationStreamPath() =>
      readSetting(PrefSettings.translationStreamPath);

  Future<void> setTranslationStreamPath(String path) =>
      writeSetting(PrefSettings.translationStreamPath, path);

  Future<Setting<int>> getArtworkMinSize() =>
      readSetting(PrefSettings.artworkMinSize);

  Future<void> setArtworkMinSize(int size) =>
      writeSetting(PrefSettings.artworkMinSize, size);

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

  Future<PlaintextSecret> _plain(String key) async {
    final prefs = await _prefs;
    if (!prefs.containsKey(key)) {
      return const PlaintextSecret(present: false);
    }
    return PlaintextSecret(present: true, value: prefs.getString(key));
  }

  Future<void> _removePlain(String key) async {
    await (await _prefs).remove(key);
  }

  Future<Setting<T>> _readSecure<T>(PrefSetting<T> spec) async {
    final plan = await _secrets.resolve(
      key: spec.key,
      plain: await _plain(spec.key),
      placeholders: spec.placeholders,
      deletePlaintext: () => _removePlain(spec.key),
    );
    if (plan.unavailable) {
      throw const SecretStoreException(SecretStoreFailure.read);
    }
    final current = _secretCurrent(spec, plan.value);
    return Setting(
      current: current,
      defaultValue: spec.defaultValue,
      changed: current != spec.defaultValue,
    );
  }

  Future<void> _saveSecret(PrefSetting<dynamic> spec, String? value) async {
    await _secrets.save(
      key: spec.key,
      value: value,
      plain: await _plain(spec.key),
      placeholders: spec.placeholders,
      deletePlaintext: () => _removePlain(spec.key),
    );
  }

  T _secretCurrent<T>(PrefSetting<T> spec, String? value) {
    if (spec.defaultValue is String) {
      return (value ?? spec.defaultValue) as T;
    }
    return value as T;
  }
}
