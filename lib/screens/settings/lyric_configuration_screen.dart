import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/screen/settings/lyric_configuration_section.dart';
import '../../widgets/settings_scaffold.dart';

class LyricConfigurationScreen extends StatelessWidget {
  const LyricConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.lyricConfiguration.title,
      child: const LyricConfigurationSettingsContent(),
    );
  }
}

class LyricConfigurationSettingsContent extends StatelessWidget {
  const LyricConfigurationSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: LyricConfigurationSection(),
    );
  }
}
