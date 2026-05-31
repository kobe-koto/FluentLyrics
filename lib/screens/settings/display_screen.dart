import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/display_section.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.display.title,
      child: const DisplaySettingsContent(),
    );
  }
}

class DisplaySettingsContent extends StatelessWidget {
  const DisplaySettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: DisplaySection(),
    );
  }
}
