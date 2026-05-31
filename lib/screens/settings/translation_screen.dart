import 'package:flutter/material.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/translation_section.dart';
import '../../i18n/strings.g.dart';

class TranslationScreen extends StatelessWidget {
  const TranslationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.translation.title,
      child: const TranslationSettingsContent(),
    );
  }
}

class TranslationSettingsContent extends StatelessWidget {
  const TranslationSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: TranslationSection(),
    );
  }
}
