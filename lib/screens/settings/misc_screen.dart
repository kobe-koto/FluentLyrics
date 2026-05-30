import 'package:flutter/material.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/misc_section.dart';

class MiscScreen extends StatelessWidget {
  const MiscScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: 'Misc',
      child: MiscSettingsContent(),
    );
  }
}

class MiscSettingsContent extends StatelessWidget {
  const MiscSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: MiscSection(),
    );
  }
}
