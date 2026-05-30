import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_card_frame.dart';
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
              const _LyricsStreamCard(),
            ] else
              const _UnsupportedNotice(
                message:
                    'There is nothing here on this platform yet — system tray '
                    'and lyrics streaming are only available on Linux and '
                    'macOS desktops.',
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

/// Two plain text file paths the app streams the currently-sung lyric line
/// (and matching translation) into. Empty path = disabled. The translation
/// file mirrors the lyric file line-for-line; lines without a translation
/// become empty lines so external tools can index by line number.
class _LyricsStreamCard extends StatefulWidget {
  const _LyricsStreamCard();

  @override
  State<_LyricsStreamCard> createState() => _LyricsStreamCardState();
}

class _LyricsStreamCardState extends State<_LyricsStreamCard> {
  late final TextEditingController _lyricsController;
  late final TextEditingController _translationController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LyricsProvider>();
    _lyricsController = TextEditingController(
      text: provider.lyricsStreamPath.current,
    );
    _translationController = TextEditingController(
      text: provider.translationStreamPath.current,
    );
  }

  @override
  void dispose() {
    _lyricsController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LyricsProvider>();
    // Settings can change from elsewhere (e.g. reset to defaults); keep the
    // text fields in sync without stomping the user's in-progress edit.
    _syncController(_lyricsController, provider.lyricsStreamPath.current);
    _syncController(
      _translationController,
      provider.translationStreamPath.current,
    );

    return SettingsCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lyrics Stream Output',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Append the currently-sung lyric line to a plain text file as '
            'playback advances. The translation file mirrors the lyrics '
            'file line-for-line; lines without a translation become empty '
            'lines so external tools can index by line number. Useful for '
            'OBS, status bars, or `tail -n 1`. Leave a path empty to '
            'disable that output.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lyricsController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Lyrics file path',
              labelStyle: TextStyle(color: Colors.white54),
              hintText: '/tmp/fluent-lyrics.txt',
              hintStyle: TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) => provider.setLyricsStreamPath(value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _translationController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Translation file path',
              labelStyle: TextStyle(color: Colors.white54),
              hintText: '/tmp/fluent-lyrics-translation.txt',
              hintStyle: TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) =>
                provider.setTranslationStreamPath(value),
          ),
        ],
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    final selection = controller.selection;
    controller.value = TextEditingValue(
      text: value,
      // Preserve caret if it's still within bounds; otherwise drop it.
      selection: selection.start <= value.length
          ? selection
          : TextSelection.collapsed(offset: value.length),
    );
  }
}
