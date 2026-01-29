import 'package:shared_preferences/shared_preferences.dart';

enum LyricProviderType { lrclib, musixmatch, netease, cache }

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

  Future<List<LyricProviderType>> getAllProvidersOrdered() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPriority = prefs.getStringList(_priorityKey);

    final List<LyricProviderType> defaultOrder = [
      LyricProviderType.lrclib,
      LyricProviderType.musixmatch,
      LyricProviderType.netease,
    ];

    if (savedPriority == null) {
      return defaultOrder;
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

    return savedList;
  }

  Future<int> getEnabledCount() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 100 to enable all if not set, or use a sensible default
    return prefs.getInt(_enabledCountKey) ?? 3;
  }

  Future<void> setEnabledCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_enabledCountKey, count);
  }

  Future<bool> isCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cacheEnabledKey) ?? true;
  }

  Future<void> setCacheEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheEnabledKey, enabled);
  }

  Future<List<LyricProviderType>> getPriority() async {
    final allOrdered = await getAllProvidersOrdered();
    final enabledCount = await getEnabledCount();
    final cacheEnabled = await isCacheEnabled();

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

  Future<String?> getMusixmatchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_musixmatchTokenKey);
  }

  Future<void> setMusixmatchToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_musixmatchTokenKey, token);
  }

  Future<int> getLinesBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_linesBeforeKey) ?? 2;
  }

  Future<void> setLinesBefore(int lines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_linesBeforeKey, lines);
  }

  Future<int> getGlobalOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_globalOffsetKey) ?? 0;
  }

  Future<void> setGlobalOffset(int offsetMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_globalOffsetKey, offsetMs);
  }

  Future<int> getScrollAutoResumeDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scrollAutoResumeDelayKey) ?? 5;
  }

  Future<void> setScrollAutoResumeDelay(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scrollAutoResumeDelayKey, seconds);
  }

  Future<bool> getBlurEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_blurEnabledKey) ?? true;
  }

  Future<void> setBlurEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blurEnabledKey, enabled);
  }

  Future<List<LyricProviderType>> getTrimMetadataProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_trimMetadataProvidersKey);

    // Default: trim metadata only for netease
    final List<LyricProviderType> defaultProviders = [
      LyricProviderType.netease,
    ];

    if (saved == null) {
      return defaultProviders;
    }

    final savedList = saved
        .map((e) => LyricProviderType.values.where((v) => v.name == e))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();

    return savedList.isEmpty ? defaultProviders : savedList;
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

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 36.0;
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<double> getInactiveScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_inactiveScaleKey) ?? 0.85;
  }

  Future<void> setInactiveScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_inactiveScaleKey, scale);
  }

  static const String _richSyncEnabledKey = 'rich_sync_enabled';

  Future<bool> isRichSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_richSyncEnabledKey) ?? true;
  }

  Future<void> setRichSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_richSyncEnabledKey, enabled);
  }
}
