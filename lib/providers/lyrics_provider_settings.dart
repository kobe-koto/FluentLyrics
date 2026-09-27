import '../models/lyric_provider_type.dart';
import '../models/setting.dart';
import '../services/pref_setting.dart';
import '../services/settings_service.dart';

class LyricsProviderSettings {
  LyricsProviderSettings._(this._values);

  final Map<PrefSetting<dynamic>, Setting<dynamic>> _values;

  factory LyricsProviderSettings.defaults() {
    return LyricsProviderSettings._({
      for (final spec in PrefSettings.mirrored) spec: spec.initial,
    });
  }

  static Future<LyricsProviderSettings> load(
    SettingsService settingsService,
  ) async {
    final values = <PrefSetting<dynamic>, Setting<dynamic>>{};
    for (final spec in PrefSettings.mirrored) {
      values[spec] = await settingsService.readSetting(spec);
    }
    return LyricsProviderSettings._(values);
  }

  Setting<T> _get<T>(PrefSetting<T> spec) {
    final stored = _values[spec]!;
    if (stored is Setting<T>) return stored;
    return spec.settingFromCurrent(stored.current as T);
  }

  void _set<T>(PrefSetting<T> spec, Setting<T> value) {
    _values[spec] = value;
  }

  Setting<bool> get cacheEnabled => _get(PrefSettings.cacheEnabled);
  set cacheEnabled(Setting<bool> value) =>
      _set(PrefSettings.cacheEnabled, value);

  Setting<int> get linesBefore => _get(PrefSettings.linesBefore);
  set linesBefore(Setting<int> value) => _set(PrefSettings.linesBefore, value);

  Setting<int> get landscapeLeadingSpace =>
      _get(PrefSettings.landscapeLeadingSpace);
  set landscapeLeadingSpace(Setting<int> value) =>
      _set(PrefSettings.landscapeLeadingSpace, value);

  Setting<int> get richSyncThresholdMs =>
      _get(PrefSettings.richSyncThresholdMs);
  set richSyncThresholdMs(Setting<int> value) =>
      _set(PrefSettings.richSyncThresholdMs, value);

  Setting<bool> get annotationEnabled => _get(PrefSettings.annotationEnabled);
  set annotationEnabled(Setting<bool> value) =>
      _set(PrefSettings.annotationEnabled, value);

  Setting<int> get annotationBias => _get(PrefSettings.annotationBias);
  set annotationBias(Setting<int> value) =>
      _set(PrefSettings.annotationBias, value);

  Setting<String> get zhConversionTarget =>
      _get(PrefSettings.zhConversionTarget);
  set zhConversionTarget(Setting<String> value) =>
      _set(PrefSettings.zhConversionTarget, value);

  Setting<List<String>> get zhConversionIgnoredLanguages =>
      _get(PrefSettings.zhConversionIgnoredLanguages);
  set zhConversionIgnoredLanguages(Setting<List<String>> value) =>
      _set(PrefSettings.zhConversionIgnoredLanguages, value);

  Setting<int> get globalOffsetMs => _get(PrefSettings.globalOffsetMs);
  set globalOffsetMs(Setting<int> value) =>
      _set(PrefSettings.globalOffsetMs, value);

  Setting<int> get scrollAutoResumeDelay =>
      _get(PrefSettings.scrollAutoResumeDelay);
  set scrollAutoResumeDelay(Setting<int> value) =>
      _set(PrefSettings.scrollAutoResumeDelay, value);

  Setting<bool> get blurEnabled => _get(PrefSettings.blurEnabled);
  set blurEnabled(Setting<bool> value) => _set(PrefSettings.blurEnabled, value);

  Setting<bool> get richSyncEnabled => _get(PrefSettings.richSyncEnabled);
  set richSyncEnabled(Setting<bool> value) =>
      _set(PrefSettings.richSyncEnabled, value);

  Setting<List<LyricProviderType>> get trimMetadataProviders =>
      _get(PrefSettings.trimMetadataProviders);
  set trimMetadataProviders(Setting<List<LyricProviderType>> value) =>
      _set(PrefSettings.trimMetadataProviders, value);

  Setting<double> get fontSize => _get(PrefSettings.fontSize);
  set fontSize(Setting<double> value) => _set(PrefSettings.fontSize, value);

  Setting<double> get inactiveScale => _get(PrefSettings.inactiveScale);
  set inactiveScale(Setting<double> value) =>
      _set(PrefSettings.inactiveScale, value);

  Setting<bool> get translationHighlightOnly =>
      _get(PrefSettings.translationHighlightOnly);
  set translationHighlightOnly(Setting<bool> value) =>
      _set(PrefSettings.translationHighlightOnly, value);

  Setting<bool> get translationEnabled => _get(PrefSettings.translationEnabled);
  set translationEnabled(Setting<bool> value) =>
      _set(PrefSettings.translationEnabled, value);

  Setting<List<String>> get translationTargetLanguages =>
      _get(PrefSettings.translationTargetLanguages);
  set translationTargetLanguages(Setting<List<String>> value) =>
      _set(PrefSettings.translationTargetLanguages, value);

  Setting<List<String>> get translationIgnoredLanguages =>
      _get(PrefSettings.translationIgnoredLanguages);
  set translationIgnoredLanguages(Setting<List<String>> value) =>
      _set(PrefSettings.translationIgnoredLanguages, value);

  Setting<int> get translationBias => _get(PrefSettings.translationBias);
  set translationBias(Setting<int> value) =>
      _set(PrefSettings.translationBias, value);

  Setting<int> get translationAlignmentThreshold =>
      _get(PrefSettings.translationAlignmentThreshold);
  set translationAlignmentThreshold(Setting<int> value) =>
      _set(PrefSettings.translationAlignmentThreshold, value);

  Setting<int> get translationCoverageThreshold =>
      _get(PrefSettings.translationCoverageThreshold);
  set translationCoverageThreshold(Setting<int> value) =>
      _set(PrefSettings.translationCoverageThreshold, value);

  Setting<String> get llmApiEndpoint => _get(PrefSettings.llmApiEndpoint);
  set llmApiEndpoint(Setting<String> value) =>
      _set(PrefSettings.llmApiEndpoint, value);

  Setting<String> get llmApiKey => _get(PrefSettings.llmApiKey);
  set llmApiKey(Setting<String> value) => _set(PrefSettings.llmApiKey, value);

  Setting<String> get llmModel => _get(PrefSettings.llmModel);
  set llmModel(Setting<String> value) => _set(PrefSettings.llmModel, value);

  Setting<String> get llmReasoningEffort =>
      _get(PrefSettings.llmReasoningEffort);
  set llmReasoningEffort(Setting<String> value) =>
      _set(PrefSettings.llmReasoningEffort, value);

  Setting<int> get llmTimeToFirstTokenSeconds =>
      _get(PrefSettings.llmTimeToFirstTokenSeconds);
  set llmTimeToFirstTokenSeconds(Setting<int> value) =>
      _set(PrefSettings.llmTimeToFirstTokenSeconds, value);

  Setting<double> get llmMinTokensPerSecond =>
      _get(PrefSettings.llmMinTokensPerSecond);
  set llmMinTokensPerSecond(Setting<double> value) =>
      _set(PrefSettings.llmMinTokensPerSecond, value);

  Setting<bool> get keepScreenOn => _get(PrefSettings.keepScreenOn);
  set keepScreenOn(Setting<bool> value) =>
      _set(PrefSettings.keepScreenOn, value);

  Setting<bool> get backgroundMotionEnabled =>
      _get(PrefSettings.backgroundMotionEnabled);
  set backgroundMotionEnabled(Setting<bool> value) =>
      _set(PrefSettings.backgroundMotionEnabled, value);

  Setting<bool> get experimentalRichInlineFontSizeGlitching =>
      _get(PrefSettings.experimentalRichInlineFontSizeGlitching);
  set experimentalRichInlineFontSizeGlitching(Setting<bool> value) =>
      _set(PrefSettings.experimentalRichInlineFontSizeGlitching, value);

  Setting<bool> get experimentalAnnotationFontSizeGlitching =>
      _get(PrefSettings.experimentalAnnotationFontSizeGlitching);
  set experimentalAnnotationFontSizeGlitching(Setting<bool> value) =>
      _set(PrefSettings.experimentalAnnotationFontSizeGlitching, value);

  Setting<bool> get trayEnabled => _get(PrefSettings.trayEnabled);
  set trayEnabled(Setting<bool> value) => _set(PrefSettings.trayEnabled, value);

  Setting<bool> get hideToTrayOnClose => _get(PrefSettings.hideToTrayOnClose);
  set hideToTrayOnClose(Setting<bool> value) =>
      _set(PrefSettings.hideToTrayOnClose, value);

  Setting<String> get lyricsStreamPath => _get(PrefSettings.lyricsStreamPath);
  set lyricsStreamPath(Setting<String> value) =>
      _set(PrefSettings.lyricsStreamPath, value);

  Setting<String> get translationStreamPath =>
      _get(PrefSettings.translationStreamPath);
  set translationStreamPath(Setting<String> value) =>
      _set(PrefSettings.translationStreamPath, value);

  Setting<int> get artworkMinSize => _get(PrefSettings.artworkMinSize);
  set artworkMinSize(Setting<int> value) =>
      _set(PrefSettings.artworkMinSize, value);
}
