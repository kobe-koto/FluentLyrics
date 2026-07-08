import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.display;
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: i18n.sectionTitle,
          description: i18n.sectionDescription,
          children: [
            SettingsSliderCard(
              title: i18n.fontSize,
              subtitle: i18n.fontSizeSubtitle,
              value: provider.fontSize.current,
              min: 12,
              max: 64,
              divisions: 52,
              label: provider.fontSize.current.toInt().toString(),
              valueText: '${provider.fontSize.current.toInt()}',
              onChanged: (value) => provider.setFontSize(value),
              onReset: provider.fontSize.changed
                  ? () => provider.setFontSize(provider.fontSize.defaultValue)
                  : null,
              resetTooltip: i18n.fontSizeReset,
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: i18n.inactiveScale,
              subtitle: i18n.inactiveScaleSubtitle,
              value: provider.inactiveScale.current,
              min: 0.5,
              max: 1.0,
              divisions: 50,
              label: '${(provider.inactiveScale.current * 100).toInt()}%',
              valueText: '${(provider.inactiveScale.current * 100).toInt()}%',
              onChanged: (value) => provider.setInactiveScale(value),
              onReset: provider.inactiveScale.changed
                  ? () => provider.setInactiveScale(
                      provider.inactiveScale.defaultValue,
                    )
                  : null,
              resetTooltip: i18n.inactiveScaleReset,
            ),
            const SizedBox(height: 24),
            SettingsToggleCard(
              title: i18n.blur,
              subtitle: i18n.blurSubtitle,
              value: provider.blurEnabled.current,
              onChanged: (value) => provider.setBlurEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsToggleCard(
              title: i18n.backgroundMotion,
              subtitle: i18n.backgroundMotionSubtitle,
              value: provider.backgroundMotionEnabled.current,
              onChanged: (value) => provider.setBackgroundMotionEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: i18n.linesBefore,
              subtitle: i18n.linesBeforeSubtitle,
              value: provider.linesBefore.current.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: provider.linesBefore.current.toString(),
              valueText: '${provider.linesBefore.current}',
              onChanged: (value) => provider.setLinesBefore(value.toInt()),
              onReset: provider.linesBefore.changed
                  ? () => provider.setLinesBefore(
                      provider.linesBefore.defaultValue,
                    )
                  : null,
              resetTooltip: i18n.linesBeforeReset,
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: i18n.autoResumeDelay,
              subtitle: i18n.autoResumeDelaySubtitle,
              value: provider.scrollAutoResumeDelay.current.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '${provider.scrollAutoResumeDelay.current}s',
              valueText: '${provider.scrollAutoResumeDelay.current}s',
              onChanged: (value) =>
                  provider.setScrollAutoResumeDelay(value.toInt()),
              onReset: provider.scrollAutoResumeDelay.changed
                  ? () => provider.setScrollAutoResumeDelay(
                      provider.scrollAutoResumeDelay.defaultValue,
                    )
                  : null,
              resetTooltip: i18n.autoResumeDelayReset,
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: i18n.artworkMinSize,
              subtitle: i18n.artworkMinSizeSubtitle,
              value: provider.artworkMinSize.current.toDouble(),
              min: 0,
              max: 1024,
              divisions: 64,
              label: provider.artworkMinSize.current == 0
                  ? 'Off'
                  : '${provider.artworkMinSize.current}px',
              valueText: provider.artworkMinSize.current == 0
                  ? 'Off'
                  : '${provider.artworkMinSize.current}px',
              onChanged: (value) =>
                  provider.setArtworkMinSize(value.toInt()),
              onReset: provider.artworkMinSize.changed
                  ? () => provider.setArtworkMinSize(
                      provider.artworkMinSize.defaultValue,
                    )
                  : null,
              resetTooltip: i18n.artworkMinSizeReset,
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 24),
              SettingsToggleCard(
                title: i18n.keepScreenOn,
                subtitle: i18n.keepScreenOnSubtitle,
                value: provider.keepScreenOn.current,
                onChanged: (value) => provider.setKeepScreenOn(value),
              ),
            ],
          ],
        );
      },
    );
  }
}
