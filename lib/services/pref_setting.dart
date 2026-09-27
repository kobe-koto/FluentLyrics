import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_defaults.dart';
import '../models/lyric_provider_type.dart';
import '../models/setting.dart';
import 'musixmatch_token.dart';

/// One persisted preference. Add a row here instead of copying a getter and setter.
class PrefSetting<T> {
  const PrefSetting({
    required this.key,
    required this.defaultValue,
    required this.read,
    required this.write,
    this.equals,
    this.secure = false,
    this.placeholders = const <String>{},
    this.placeholderWhen,
  });

  final String key;
  final T defaultValue;
  final T? Function(SharedPreferences prefs, String key) read;
  final Future<void> Function(SharedPreferences prefs, String key, T value)
  write;
  final bool Function(T a, T b)? equals;

  /// When true, [SettingsService] stores this value in the platform secret
  /// store. [read] and [write] remain the plaintext copy used for migration.
  final bool secure;

  /// Values that mean "not configured" and must not be written to the store.
  final Set<String> placeholders;

  /// Extra rejection for values that are not a single exact placeholder.
  final bool Function(String value)? placeholderWhen;

  Setting<T> get initial => settingFromCurrent(defaultValue);

  Setting<T> settingFrom(SharedPreferences prefs) {
    return settingFromCurrent(read(prefs, key) ?? defaultValue);
  }

  /// Builds a [Setting] for this row. Must stay an instance method: a generic
  /// function constructs `Setting<dynamic>`, which the provider cannot cast.
  Setting<T> settingFromCurrent(T current) {
    final same = equals?.call(current, defaultValue) ?? current == defaultValue;
    return Setting(
      current: current,
      defaultValue: defaultValue,
      changed: !same,
    );
  }

  /// [String] null becomes [defaultValue]. [String?] null stays null.
  Setting<T> settingFromSecret(String? value) {
    final current = defaultValue is String
        ? (value ?? defaultValue) as T
        : value as T;
    return settingFromCurrent(current);
  }

  Future<void> save(SharedPreferences prefs, T value) =>
      write(prefs, key, value);
}

bool? _readBool(SharedPreferences prefs, String key) => prefs.getBool(key);
int? _readInt(SharedPreferences prefs, String key) => prefs.getInt(key);
double? _readDouble(SharedPreferences prefs, String key) =>
    prefs.getDouble(key);
String? _readString(SharedPreferences prefs, String key) =>
    prefs.getString(key);

List<String>? _readStringList(SharedPreferences prefs, String key) =>
    prefs.getStringList(key);

Future<void> _writeBool(SharedPreferences prefs, String key, bool value) {
  return prefs.setBool(key, value);
}

Future<void> _writeInt(SharedPreferences prefs, String key, int value) {
  return prefs.setInt(key, value);
}

Future<void> _writeDouble(SharedPreferences prefs, String key, double value) {
  return prefs.setDouble(key, value);
}

Future<void> _writeString(SharedPreferences prefs, String key, String value) {
  return prefs.setString(key, value);
}

Future<void> _writeStringList(
  SharedPreferences prefs,
  String key,
  List<String> value,
) {
  return prefs.setStringList(key, value);
}

List<LyricProviderType>? _readProviderList(
  SharedPreferences prefs,
  String key,
) {
  final saved = prefs.getStringList(key);
  if (saved == null) return null;
  final parsed = saved
      .map(
        (name) => LyricProviderType.values.where((type) => type.name == name),
      )
      .where((matches) => matches.isNotEmpty)
      .map((matches) => matches.first)
      .toList();
  if (parsed.isEmpty) return null;
  return parsed;
}

Future<void> _writeProviderList(
  SharedPreferences prefs,
  String key,
  List<LyricProviderType> value,
) {
  return prefs.setStringList(key, value.map((type) => type.name).toList());
}

bool _listEquals<T>(List<T> a, List<T> b) => listEquals(a, b);

class PrefSettings {
  static final cacheEnabled = PrefSetting<bool>(
    key: 'cache_enabled',
    defaultValue: AppDefaults.cacheEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final linesBefore = PrefSetting<int>(
    key: 'lines_before',
    defaultValue: AppDefaults.linesBefore,
    read: _readInt,
    write: _writeInt,
  );
  static final landscapeLeadingSpace = PrefSetting<int>(
    key: 'landscape_leading_space',
    defaultValue: AppDefaults.landscapeLeadingSpace,
    read: _readInt,
    write: _writeInt,
  );
  static final richSyncThresholdMs = PrefSetting<int>(
    key: 'rich_sync_threshold_ms',
    defaultValue: AppDefaults.richSyncThresholdMs,
    read: _readInt,
    write: _writeInt,
  );
  static final annotationEnabled = PrefSetting<bool>(
    key: 'annotation_enabled',
    defaultValue: AppDefaults.annotationEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final annotationBias = PrefSetting<int>(
    key: 'annotation_bias',
    defaultValue: AppDefaults.annotationBias,
    read: _readInt,
    write: _writeInt,
  );
  static final zhConversionTarget = PrefSetting<String>(
    key: 'zh_conversion_target',
    defaultValue: AppDefaults.zhConversionTarget,
    read: _readString,
    write: _writeString,
  );
  static final zhConversionIgnoredLanguages = PrefSetting<List<String>>(
    key: 'zh_conversion_ignored_languages',
    defaultValue: AppDefaults.zhConversionIgnoredLanguages,
    read: _readStringList,
    write: _writeStringList,
    equals: _listEquals,
  );
  static final globalOffsetMs = PrefSetting<int>(
    key: 'global_offset_ms',
    defaultValue: AppDefaults.globalOffsetMs,
    read: _readInt,
    write: _writeInt,
  );
  static final scrollAutoResumeDelay = PrefSetting<int>(
    key: 'scroll_auto_resume_delay',
    defaultValue: AppDefaults.scrollAutoResumeDelay,
    read: _readInt,
    write: _writeInt,
  );
  static final blurEnabled = PrefSetting<bool>(
    key: 'blur_enabled',
    defaultValue: AppDefaults.blurEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final richSyncEnabled = PrefSetting<bool>(
    key: 'rich_sync_enabled',
    defaultValue: AppDefaults.richSyncEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final trimMetadataProviders = PrefSetting<List<LyricProviderType>>(
    key: 'trim_metadata_providers',
    defaultValue: AppDefaults.trimMetadataProviders,
    read: _readProviderList,
    write: _writeProviderList,
    equals: _listEquals,
  );
  static final fontSize = PrefSetting<double>(
    key: 'font_size',
    defaultValue: AppDefaults.fontSize,
    read: _readDouble,
    write: _writeDouble,
  );
  static final inactiveScale = PrefSetting<double>(
    key: 'inactive_scale',
    defaultValue: AppDefaults.inactiveScale,
    read: _readDouble,
    write: _writeDouble,
  );
  static final translationHighlightOnly = PrefSetting<bool>(
    key: 'translation_highlight_only',
    defaultValue: AppDefaults.translationHighlightOnly,
    read: _readBool,
    write: _writeBool,
  );
  static final translationEnabled = PrefSetting<bool>(
    key: 'translation_enabled',
    defaultValue: AppDefaults.translationEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final translationTargetLanguages = PrefSetting<List<String>>(
    key: 'translation_target_languages',
    defaultValue: AppDefaults.translationTargetLanguages,
    read: _readStringList,
    write: (prefs, key, value) {
      if (value.isEmpty) return prefs.remove(key);
      return prefs.setStringList(key, value);
    },
    equals: _listEquals,
  );
  static final translationIgnoredLanguages = PrefSetting<List<String>>(
    key: 'translation_ignored_languages',
    defaultValue: AppDefaults.translationIgnoredLanguages,
    read: _readStringList,
    write: _writeStringList,
    equals: _listEquals,
  );
  static final translationBias = PrefSetting<int>(
    key: 'translation_bias',
    defaultValue: AppDefaults.translationBias,
    read: _readInt,
    write: _writeInt,
  );
  static final translationAlignmentThreshold = PrefSetting<int>(
    key: 'translation_alignment_threshold',
    defaultValue: AppDefaults.translationAlignmentThreshold,
    read: _readInt,
    write: _writeInt,
  );
  static final translationCoverageThreshold = PrefSetting<int>(
    key: 'translation_coverage_threshold',
    defaultValue: AppDefaults.translationCoverageThreshold,
    read: _readInt,
    write: _writeInt,
  );
  static final llmApiEndpoint = PrefSetting<String>(
    key: 'llm_api_endpoint',
    defaultValue: AppDefaults.llmApiEndpoint,
    read: _readString,
    write: _writeString,
  );
  static final llmApiKey = PrefSetting<String>(
    key: 'llm_api_key',
    defaultValue: AppDefaults.llmApiKey,
    read: _readString,
    write: _writeString,
    secure: true,
    placeholders: {AppDefaults.llmApiKey},
  );
  static final llmModel = PrefSetting<String>(
    key: 'llm_model',
    defaultValue: AppDefaults.llmModel,
    read: _readString,
    write: _writeString,
  );
  static final llmReasoningEffort = PrefSetting<String>(
    key: 'llm_reasoning_effort',
    defaultValue: AppDefaults.llmReasoningEffort,
    read: _readString,
    write: _writeString,
  );
  static final llmTimeToFirstTokenSeconds = PrefSetting<int>(
    key: 'llm_time_to_first_token_seconds',
    defaultValue: AppDefaults.llmTimeToFirstTokenSeconds,
    read: _readInt,
    write: _writeInt,
  );
  static final llmMinTokensPerSecond = PrefSetting<double>(
    key: 'llm_min_tokens_per_second',
    defaultValue: AppDefaults.llmMinTokensPerSecond,
    read: _readDouble,
    write: _writeDouble,
  );
  static final keepScreenOn = PrefSetting<bool>(
    key: 'keep_screen_on',
    defaultValue: AppDefaults.keepScreenOn,
    read: _readBool,
    write: _writeBool,
  );
  static final backgroundMotionEnabled = PrefSetting<bool>(
    key: 'background_motion_enabled',
    defaultValue: AppDefaults.backgroundMotionEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final experimentalRichInlineFontSizeGlitching = PrefSetting<bool>(
    key: 'experimental_rich_inline_font_size_glitching',
    defaultValue: AppDefaults.experimentalRichInlineFontSizeGlitching,
    read: _readBool,
    write: _writeBool,
  );
  static final experimentalAnnotationFontSizeGlitching = PrefSetting<bool>(
    key: 'experimental_annotation_font_size_glitching',
    defaultValue: AppDefaults.experimentalAnnotationFontSizeGlitching,
    read: _readBool,
    write: _writeBool,
  );
  static final trayEnabled = PrefSetting<bool>(
    key: 'tray_enabled',
    defaultValue: AppDefaults.trayEnabled,
    read: _readBool,
    write: _writeBool,
  );
  static final hideToTrayOnClose = PrefSetting<bool>(
    key: 'hide_to_tray_on_close',
    defaultValue: AppDefaults.hideToTrayOnClose,
    read: _readBool,
    write: _writeBool,
  );
  static final lyricsStreamPath = PrefSetting<String>(
    key: 'lyrics_stream_path',
    defaultValue: AppDefaults.lyricsStreamPath,
    read: _readString,
    write: _writeString,
  );
  static final translationStreamPath = PrefSetting<String>(
    key: 'translation_stream_path',
    defaultValue: AppDefaults.translationStreamPath,
    read: _readString,
    write: _writeString,
  );
  static final artworkMinSize = PrefSetting<int>(
    key: 'artwork_min_size',
    defaultValue: AppDefaults.artworkMinSize,
    read: _readInt,
    write: _writeInt,
  );
  static final enabledProviderCount = PrefSetting<int>(
    key: 'enabled_provider_count',
    defaultValue: AppDefaults.enabledProviderCount,
    read: _readInt,
    write: _writeInt,
  );
  static final musixmatchToken = PrefSetting<String?>(
    key: 'musixmatch_token',
    defaultValue: AppDefaults.musixmatchToken,
    read: _readString,
    write: (prefs, key, value) {
      if (value == null) return prefs.remove(key);
      return prefs.setString(key, value);
    },
    secure: true,
    placeholders: {
      musixmatchZeroPlaceholder,
      musixmatchUpgradeOnlyPlaceholder,
      'null',
    },
    placeholderWhen: musixmatchTokenIsPlaceholder,
  );

  /// Settings mirrored into [LyricsProviderSettings]. Adding a row here is enough
  /// for load and defaults; the provider still needs a typed accessor.
  static final List<PrefSetting<dynamic>> mirrored = [
    cacheEnabled,
    linesBefore,
    landscapeLeadingSpace,
    richSyncThresholdMs,
    annotationEnabled,
    annotationBias,
    zhConversionTarget,
    zhConversionIgnoredLanguages,
    globalOffsetMs,
    scrollAutoResumeDelay,
    blurEnabled,
    richSyncEnabled,
    trimMetadataProviders,
    fontSize,
    inactiveScale,
    translationHighlightOnly,
    translationEnabled,
    translationTargetLanguages,
    translationIgnoredLanguages,
    translationBias,
    translationAlignmentThreshold,
    translationCoverageThreshold,
    llmApiEndpoint,
    llmApiKey,
    llmModel,
    llmReasoningEffort,
    llmTimeToFirstTokenSeconds,
    llmMinTokensPerSecond,
    keepScreenOn,
    backgroundMotionEnabled,
    experimentalRichInlineFontSizeGlitching,
    experimentalAnnotationFontSizeGlitching,
    trayEnabled,
    hideToTrayOnClose,
    lyricsStreamPath,
    translationStreamPath,
    artworkMinSize,
  ];
}
