import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';
import '../../../providers/appearance_controller.dart';
import '../../../theme/settings_colors.dart';
import '../../settings_card_frame.dart';
import '../../settings_group.dart';
import '../../settings_section.dart';
import '../../settings_toggle_card.dart';

class AppearanceSection extends StatefulWidget {
  const AppearanceSection({super.key});

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  /// Used only when no [AppearanceScope] is mounted (tests, previews).
  AppearanceController? _fallback;

  @override
  void dispose() {
    _fallback?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        AppearanceScope.maybeOf(context) ??
        (_fallback ??= AppearanceController());
    final i18n = t.settings.appearance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SettingsSection(
          title: i18n.title,
          description: i18n.description,
          children: [
            SettingsGroup(
              children: [
                for (final mode in SettingsThemeMode.values)
                  _ThemeModeTile(
                    icon: switch (mode) {
                      SettingsThemeMode.system =>
                        Icons.brightness_auto_outlined,
                      SettingsThemeMode.light => Icons.light_mode_outlined,
                      SettingsThemeMode.dark => Icons.dark_mode_outlined,
                    },
                    label: switch (mode) {
                      SettingsThemeMode.system => i18n.system,
                      SettingsThemeMode.light => i18n.light,
                      SettingsThemeMode.dark => i18n.dark,
                    },
                    selected: controller.themeMode == mode,
                    onTap: () => controller.setThemeMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsToggleCard(
              title: i18n.pureBlack,
              subtitle: i18n.pureBlackDescription,
              value: controller.pureBlack,
              onChanged: controller.setPureBlack,
            ),
          ],
        );
      },
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.settingsColors;
    return SettingsCardFrame(
      padding: EdgeInsets.zero,
      color: selected ? colors.fg(0.1) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: colors.fg(selected ? 0.9 : 0.6), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: colors.onSurface, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
