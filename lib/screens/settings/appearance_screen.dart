import 'package:flutter/material.dart';

import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/appearance_section.dart';
import '../../i18n/strings.g.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.appearance.title,
      child: const AppearanceSettingsContent(),
    );
  }
}

class AppearanceSettingsContent extends StatelessWidget {
  const AppearanceSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: AppearanceSection(),
    );
  }
}
