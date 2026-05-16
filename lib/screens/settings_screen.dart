import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/settings_scaffold.dart';
import '../widgets/screen/settings/version_section.dart';
import 'settings/priority_screen.dart';
import 'settings/display_screen.dart';
import 'settings/translation_screen.dart';
import 'settings/lyric_configuration_screen.dart';
import 'settings/cache_screen.dart';
import 'settings/experimental_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() => _version = packageInfo.version);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _SettingsEntry(
            icon: Icons.sort,
            color: Colors.blue,
            title: 'Provider Priority',
            subtitle: 'Reorder and enable/disable lyrics providers',
            onTap: () => _push(context, const PriorityScreen()),
          ),
          _SettingsEntry(
            icon: Icons.display_settings,
            color: Colors.purple,
            title: 'Display',
            subtitle: 'Font size, blur, background motion, scroll behavior',
            onTap: () => _push(context, const DisplayScreen()),
          ),
          _SettingsEntry(
            icon: Icons.translate,
            color: Colors.teal,
            title: 'Translation',
            subtitle: 'Translation targets, LLM config, alignment',
            onTap: () => _push(context, const TranslationScreen()),
          ),
          _SettingsEntry(
            icon: Icons.music_note,
            color: Colors.orange,
            title: 'Lyric Configuration',
            subtitle: 'Rich sync, offset, metadata trim, Musixmatch token',
            onTap: () => _push(context, const LyricConfigurationScreen()),
          ),
          _SettingsEntry(
            icon: Icons.storage,
            color: Colors.red,
            title: 'Cache Management',
            subtitle: 'Clear lyrics and artwork cache',
            onTap: () => _push(context, const CacheScreen()),
          ),
          _SettingsEntry(
            icon: Icons.science,
            color: Colors.amber,
            title: 'Experimental',
            subtitle: 'Unstable features and fixes',
            onTap: () => _push(context, const ExperimentalScreen()),
          ),
          const SizedBox(height: 32),
          if (_version.isNotEmpty) VersionSection(version: _version),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
