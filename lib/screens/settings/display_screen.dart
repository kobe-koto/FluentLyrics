import 'package:flutter/material.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/display_section.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: 'Display',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: DisplaySection(),
      ),
    );
  }
}
