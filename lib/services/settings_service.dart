import 'package:shared_preferences/shared_preferences.dart';

enum LyricProviderType { lrclib, musixmatch, netease }

class SettingsService {
  static const String _priorityKey = 'lyric_provider_priority';
  static const String _musixmatchTokenKey = 'musixmatch_token';
  static const String _linesBeforeKey = 'lines_before';
  static const String _globalOffsetKey = 'global_offset_ms';
  static const String _scrollAutoResumeDelayKey = 'scroll_auto_resume_delay';
  static const String _blurEnabledKey = 'blur_enabled';
  static const String _trimMetadataProvidersKey = 'trim_metadata_providers';

  Future<List<LyricProviderType>> getPriority() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPriority = prefs.getStringList(_priorityKey);

    final List<LyricProviderType> defaultPriority = [
      LyricProviderType.lrclib,
      LyricProviderType.musixmatch,
      LyricProviderType.netease,
    ];

    if (savedPriority == null) {
      return defaultPriority;
    }

    final savedList = savedPriority
        .map((e) => LyricProviderType.values.where((v) => v.name == e))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();

    // Find missing providers and append them
    final Set<LyricProviderType> savedSet = savedList.toSet();
    for (var provider in LyricProviderType.values) {
      if (!savedSet.contains(provider)) {
        savedList.add(provider);
      }
    }

    return savedList;
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
    final List<LyricProviderType> defaultProviders = [LyricProviderType.netease];

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

  Future<void> setTrimMetadataProviders(List<LyricProviderType> providers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _trimMetadataProvidersKey,
      providers.map((e) => e.name).toList(),
    );
  }
}
