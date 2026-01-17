import 'package:shared_preferences/shared_preferences.dart';

enum LyricProviderType { lrclib, musixmatch }

class SettingsService {
  static const String _priorityKey = 'lyric_provider_priority';
  static const String _musixmatchTokenKey = 'musixmatch_token';
  static const String _linesBeforeKey = 'lines_before';
  static const String _globalOffsetKey = 'global_offset_ms';

  Future<List<LyricProviderType>> getPriority() async {
    final prefs = await SharedPreferences.getInstance();
    final priority = prefs.getStringList(_priorityKey);
    if (priority == null) {
      return [LyricProviderType.lrclib, LyricProviderType.musixmatch];
    }
    return priority
        .map((e) => LyricProviderType.values.firstWhere((v) => v.name == e))
        .toList();
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
}
