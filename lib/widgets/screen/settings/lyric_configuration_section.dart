import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/lyric_provider_type.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../services/opencc/zh_conversion.dart';
import '../../../utils/lyric_configuration_helper.dart';
import '../../settings_card_frame.dart';
import '../../settings_section.dart';
import '../../settings_group.dart';
import '../../settings_dropdown_card.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class LyricConfigurationSection extends StatelessWidget {
  const LyricConfigurationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.lyricConfig;
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: i18n.sectionTitle,
          description: i18n.sectionDescription,
          children: [
            SettingsGroup(
              children: [
                SettingsToggleCard(
                  title: i18n.richSync,
                  subtitle: i18n.richSyncSubtitle,
                  value: provider.richSyncEnabled.current,
                  onChanged: (value) => provider.setRichSyncEnabled(value),
                ),
                SettingsSliderCard(
                  title: i18n.richSyncThreshold,
                  subtitle: i18n.richSyncThresholdSubtitle,
                  value: provider.richSyncThresholdMs.current.toDouble(),
                  min: 0,
                  max: 2000,
                  divisions: 20,
                  label: '${provider.richSyncThresholdMs.current}ms',
                  valueText: '${provider.richSyncThresholdMs.current}ms',
                  onChanged: (value) =>
                      provider.setRichSyncThresholdMs(value.toInt()),
                  onReset: provider.richSyncThresholdMs.changed
                      ? () => provider.setRichSyncThresholdMs(
                          provider.richSyncThresholdMs.defaultValue,
                        )
                      : null,
                  resetTooltip: i18n.richSyncThresholdReset,
                ),
                SettingsToggleCard(
                  title: i18n.annotation,
                  subtitle: i18n.annotationSubtitle,
                  value: provider.annotationEnabled.current,
                  onChanged: (value) => provider.setAnnotationEnabled(value),
                ),
                SettingsSliderCard(
                  title: i18n.annotationBias,
                  subtitle: i18n.annotationBiasSubtitle,
                  value: provider.annotationBias.current.toDouble(),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  label: '${provider.annotationBias.current}ms',
                  valueText: '${provider.annotationBias.current}ms',
                  onChanged: (value) =>
                      provider.setAnnotationBias(value.toInt()),
                  onReset: provider.annotationBias.changed
                      ? () => provider.setAnnotationBias(
                          provider.annotationBias.defaultValue,
                        )
                      : null,
                  resetTooltip: i18n.annotationBiasReset,
                ),
                SettingsDropdownCard<String>(
                  title: i18n.zhConversion,
                  subtitle: i18n.zhConversionSubtitle,
                  value: provider.zhConversionTarget.current,
                  options: [
                    SettingsDropdownOption(
                      value: ZhConversionTarget.off.settingValue,
                      label: i18n.zhConversionOff,
                    ),
                    SettingsDropdownOption(
                      value: ZhConversionTarget.simplified.settingValue,
                      label: i18n.zhConversionSimplified,
                    ),
                    SettingsDropdownOption(
                      value: ZhConversionTarget.traditionalTaiwan.settingValue,
                      label: i18n.zhConversionTraditionalTaiwan,
                    ),
                    SettingsDropdownOption(
                      value:
                          ZhConversionTarget.traditionalHongKong.settingValue,
                      label: i18n.zhConversionTraditionalHongKong,
                    ),
                  ],
                  onChanged: (value) => provider.setZhConversionTarget(value),
                  onReset: provider.zhConversionTarget.changed
                      ? () => provider.setZhConversionTarget(
                          provider.zhConversionTarget.defaultValue,
                        )
                      : null,
                ),
                SettingsSliderCard(
                  title: i18n.globalOffset,
                  subtitle: i18n.globalOffsetSubtitle,
                  value: (provider.globalOffset.inMilliseconds / 100)
                      .toDouble(),
                  min: -50,
                  max: 50,
                  divisions: 100,
                  label: (provider.globalOffset.inMilliseconds / 1000.0)
                      .toStringAsFixed(1),
                  valueText:
                      '${(provider.globalOffset.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
                  onChanged: (value) {
                    provider.setGlobalOffset(
                      Duration(milliseconds: (value * 100).toInt()),
                    );
                  },
                  onReset: provider.globalOffsetSetting.changed
                      ? () => provider.setGlobalOffset(Duration.zero)
                      : null,
                  resetTooltip: i18n.globalOffsetReset,
                ),
                SettingsCardFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.trimTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.trimSubtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: LyricProviderType.values
                            .where((v) => v != LyricProviderType.cache)
                            .map((providerType) {
                              final isSelected = provider
                                  .trimMetadataProviders
                                  .current
                                  .contains(providerType);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    final updated =
                                        LyricConfigurationHelper.toggleTrimMetadataProvider(
                                          provider
                                              .trimMetadataProviders
                                              .current,
                                          providerType,
                                        );
                                    provider.setTrimMetadataProviders(updated);
                                  },
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          final updated =
                                              LyricConfigurationHelper.toggleTrimMetadataProvider(
                                                provider
                                                    .trimMetadataProviders
                                                    .current,
                                                providerType,
                                                select: value == true,
                                              );
                                          provider.setTrimMetadataProviders(
                                            updated,
                                          );
                                        },
                                        activeColor: Colors.blue,
                                        checkColor: Colors.black,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        providerType.localizedName(t),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
