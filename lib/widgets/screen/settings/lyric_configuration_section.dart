import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/lyric_provider_type.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../services/opencc/zh_conversion.dart';
import '../../../utils/lyric_configuration_helper.dart';
import '../../settings_card_frame.dart';
import '../../settings_section.dart';
import '../../settings_dropdown_card.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class LyricConfigurationSection extends StatelessWidget {
  final TextEditingController tokenController;
  final bool isFetchingToken;
  final VoidCallback onGetNewToken;
  final VoidCallback onTokenChanged;

  const LyricConfigurationSection({
    super.key,
    required this.tokenController,
    required this.isFetchingToken,
    required this.onGetNewToken,
    required this.onTokenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.lyricConfig;
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: i18n.sectionTitle,
          description: i18n.sectionDescription,
          children: [
            SettingsToggleCard(
              title: i18n.richSync,
              subtitle: i18n.richSyncSubtitle,
              value: provider.richSyncEnabled.current,
              onChanged: (value) => provider.setRichSyncEnabled(value),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
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
                  value: ZhConversionTarget.traditionalHongKong.settingValue,
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
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: i18n.globalOffset,
              subtitle: i18n.globalOffsetSubtitle,
              value: (provider.globalOffset.inMilliseconds / 100).toDouble(),
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
            const SizedBox(height: 24),
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
                                      provider.trimMetadataProviders.current,
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
            const SizedBox(height: 24),
            SettingsCardFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.musixmatchTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.musixmatchSubtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tokenController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: i18n.musixmatchHint,
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => onTokenChanged(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isFetchingToken ? null : onGetNewToken,
                          icon: isFetchingToken
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(
                            i18n.getNewToken,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
