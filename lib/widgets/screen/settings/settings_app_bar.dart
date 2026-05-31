import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';

class SettingsAppBar extends StatelessWidget {
  final VoidCallback onBackPressed;

  const SettingsAppBar({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onBackPressed,
          ),
          const SizedBox(width: 8),
          Text(
            t.settings.appBar.lyricsConfiguration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
