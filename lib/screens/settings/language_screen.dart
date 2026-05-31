import 'package:flutter/material.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/language_section.dart';
import '../../i18n/strings.g.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.language.title,
      child: const LanguageSettingsContent(),
    );
  }
}

class LanguageSettingsContent extends StatelessWidget {
  const LanguageSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: LanguageSection(),
    );
  }
}
