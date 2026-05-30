import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_toggle_card.dart';

class MiscSection extends StatelessWidget {
  const MiscSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        final isDesktop = Platform.isLinux || Platform.isMacOS;
        return SettingsSection(
          title: 'Misc',
          description: 'Miscellaneous options.',
          children: [
            if (isDesktop) ...[
              SettingsToggleCard(
                title: 'System Tray Icon',
                subtitle:
                    'Show a Fluent Lyrics icon in the system tray with quick '
                    'show/hide and quit actions. Requires AppIndicator on '
                    'Linux (libayatana-appindicator).',
                value: provider.trayEnabled.current,
                onChanged: (value) => provider.setTrayEnabled(value),
              ),
              if (provider.trayEnabled.current)
                SettingsToggleCard(
                  title: 'Hide to Tray on Close',
                  subtitle:
                      'When you close the main window, hide it to the tray '
                      'instead of quitting. Lyrics and translations keep '
                      'fetching in the background; UI rendering pauses while '
                      'hidden. Use the tray menu to quit.',
                  value: provider.hideToTrayOnClose.current,
                  onChanged: (value) => provider.setHideToTrayOnClose(value),
                ),
            ] else
              const _UnsupportedNotice(
                message:
                    'There is nothing here on this platform yet — system tray '
                    'is only available on Linux and macOS desktops.',
              ),
          ],
        );
      },
    );
  }
}

class _UnsupportedNotice extends StatelessWidget {
  const _UnsupportedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
