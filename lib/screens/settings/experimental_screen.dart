import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/experimental_section.dart';

class ExperimentalScreen extends StatelessWidget {
  const ExperimentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.experimental.title,
      child: const ExperimentalSettingsContent(),
    );
  }
}

class ExperimentalSettingsContent extends StatelessWidget {
  const ExperimentalSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: ExperimentalSection(),
    );
  }
}
