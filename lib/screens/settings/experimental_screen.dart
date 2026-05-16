import 'package:flutter/material.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/experimental_section.dart';

class ExperimentalScreen extends StatelessWidget {
  const ExperimentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: 'Experimental',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: ExperimentalSection(),
      ),
    );
  }
}
