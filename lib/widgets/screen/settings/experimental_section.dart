import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_toggle_card.dart';

class ExperimentalSection extends StatelessWidget {
  const ExperimentalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.experimental;
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: i18n.sectionTitle,
          description: i18n.sectionDescription,
          children: [
            SettingsToggleCard(
              title: i18n.richInlineFix,
              subtitle: i18n.richInlineFixSubtitle,
              value: provider.experimentalRichInlineFontSizeGlitching.current,
              onChanged: (value) =>
                  provider.setExperimentalRichInlineFontSizeGlitching(value),
            ),
          ],
        );
      },
    );
  }
}
