import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/theme/app_theme.dart';
import 'package:fluent_lyrics/theme/settings_colors.dart';
import 'package:fluent_lyrics/widgets/settings_dropdown_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dropdown text keeps the app font family', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSettingsTheme(SettingsColors.light),
        home: Scaffold(
          body: SettingsDropdownCard<String>(
            title: 'Title',
            subtitle: 'Subtitle',
            value: 'a',
            options: const [
              SettingsDropdownOption(value: 'a', label: 'Option A'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.style?.fontFamily, 'Outfit');
    expect(dropdown.style?.color, SettingsColors.light.onSurface);
  });
}
