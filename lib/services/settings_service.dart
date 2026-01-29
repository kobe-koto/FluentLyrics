import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setting.dart';
import '../models/lyric_provider_type.dart';
import '../constants/app_defaults.dart';

class SettingsService {
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

  Future<Setting<List<LyricProviderType>>> getAllProvidersOrdered() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getInt(_enabledCountKey) ?? AppDefaults.enabledProviderCount;
    return Setting(
      current: current,
      defaultValue: AppDefaults.enabledProviderCount,
      changed: current != AppDefaults.enabledProviderCount,
    );
  }

  Future<void> setEnabledCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_enabledCountKey, count);
  }

  Future<Setting<bool>> getCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(_cacheEnabledKey) ?? AppDefaults.cacheEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.cacheEnabled,
      changed: current != AppDefaults.cacheEnabled,
    );
  }

  Future<void> setCacheEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _priorityKey,
      priority.map((e) => e.name).toList(),
    );
  }

  Future<Setting<String?>> getMusixmatchToken() async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getString(_musixmatchTokenKey) ?? AppDefaults.musixmatchToken;
    return Setting(
      current: current,
      defaultValue: AppDefaults.musixmatchToken,
      changed: current != AppDefaults.musixmatchToken,
    );
  }

  Future<void> setMusixmatchToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_musixmatchTokenKey, token);
  }

  Future<Setting<int>> getLinesBefore() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_linesBeforeKey) ?? AppDefaults.linesBefore;
    return Setting(
      current: current,
      defaultValue: AppDefaults.linesBefore,
      changed: current != AppDefaults.linesBefore,
    );
  }

  Future<void> setLinesBefore(int lines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_linesBeforeKey, lines);
  }

  Future<Setting<int>> getGlobalOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getInt(_globalOffsetKey) ?? AppDefaults.globalOffsetMs;
    return Setting(
      current: current,
      defaultValue: AppDefaults.globalOffsetMs,
      changed: current != AppDefaults.globalOffsetMs,
    );
  }

  Future<void> setGlobalOffset(int offsetMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_globalOffsetKey, offsetMs);
  }

  Future<Setting<int>> getScrollAutoResumeDelay() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scrollAutoResumeDelayKey, seconds);
  }

  Future<Setting<bool>> getBlurEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(_blurEnabledKey) ?? AppDefaults.blurEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.blurEnabled,
      changed: current != AppDefaults.blurEnabled,
    );
  }

  Future<void> setBlurEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blurEnabledKey, enabled);
  }

  Future<Setting<List<LyricProviderType>>> getTrimMetadataProviders() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _trimMetadataProvidersKey,
      providers.map((e) => e.name).toList(),
    );
  }

  Future<Setting<double>> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_fontSizeKey) ?? AppDefaults.fontSize;
    return Setting(
      current: current,
      defaultValue: AppDefaults.fontSize,
      changed: current != AppDefaults.fontSize,
    );
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<Setting<double>> getInactiveScale() async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getDouble(_inactiveScaleKey) ?? AppDefaults.inactiveScale;
    return Setting(
      current: current,
      defaultValue: AppDefaults.inactiveScale,
      changed: current != AppDefaults.inactiveScale,
    );
  }

  Future<void> setInactiveScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_inactiveScaleKey, scale);
  }

  Future<Setting<bool>> getRichSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getBool(_richSyncEnabledKey) ?? AppDefaults.richSyncEnabled;
    return Setting(
      current: current,
      defaultValue: AppDefaults.richSyncEnabled,
      changed: current != AppDefaults.richSyncEnabled,
    );
  }

  Future<void> setRichSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_richSyncEnabledKey, enabled);
  }
}
