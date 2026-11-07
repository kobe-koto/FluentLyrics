import 'package:flutter/material.dart';

import '../theme/settings_colors.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: context.settingsColors.fg(0.54),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: context.settingsColors.fg(0.38),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}
