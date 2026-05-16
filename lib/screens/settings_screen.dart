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
  _SettingsDestination _selectedDestination = _SettingsDestination.priority;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= 960 &&
            constraints.maxWidth > constraints.maxHeight;
        return SettingsScaffold(
          title: 'Settings',
          child: isWide
              ? _buildWideLayout(context)
              : _buildCompactLayout(context),
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        for (final destination in _SettingsDestination.values)
          _SettingsEntry(
            destination: destination,
            selected: false,
            showAccentBar: false,
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            onTap: () => _push(context, destination.screen),
          ),
        const SizedBox(height: 32),
        if (_version.isNotEmpty) VersionSection(version: _version),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final destination = _selectedDestination;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                          child: Text(
                            'Preferences',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _SettingsDestination.values.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final item = _SettingsDestination.values[index];
                              return _SettingsEntry(
                                destination: item,
                                selected: item == destination,
                                showAccentBar: true,
                                trailing: null,
                                onTap: () {
                                  setState(() {
                                    _selectedDestination = item;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  VersionSection(version: _version),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0.0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: [...previousChildren, ?currentChild],
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(destination),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                destination.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        Expanded(child: destination.content),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

class _SettingsEntry extends StatelessWidget {
  final _SettingsDestination destination;
  final bool selected;
  final bool showAccentBar;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsEntry({
    required this.destination,
    required this.selected,
    required this.showAccentBar,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = destination.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
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
                        child: Icon(destination.icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destination.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: selected ? 0.72 : 0.4,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showAccentBar)
            Positioned(
              left: -4,
              top: 12,
              bottom: 12,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.4,
                          end: 1.0,
                        ).animate(animation),
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    );
                  },
                  child: selected
                      ? Container(
                          key: const ValueKey('bar'),
                          width: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _SettingsDestination {
  priority(
    icon: Icons.sort,
    color: Colors.blue,
    title: 'Provider Priority',
    subtitle: 'Reorder and enable/disable lyrics providers',
    screen: PriorityScreen(),
    content: PrioritySettingsContent(),
  ),
  display(
    icon: Icons.display_settings,
    color: Colors.purple,
    title: 'Display',
    subtitle: 'Font size, blur, background motion, scroll behavior',
    screen: DisplayScreen(),
    content: DisplaySettingsContent(),
  ),
  translation(
    icon: Icons.translate,
    color: Colors.teal,
    title: 'Translation',
    subtitle: 'Translation targets, LLM config, alignment',
    screen: TranslationScreen(),
    content: TranslationSettingsContent(),
  ),
  lyricConfiguration(
    icon: Icons.music_note,
    color: Colors.orange,
    title: 'Lyric Configuration',
    subtitle: 'Rich sync, offset, metadata trim, Musixmatch token',
    screen: LyricConfigurationScreen(),
    content: LyricConfigurationSettingsContent(),
  ),
  cache(
    icon: Icons.storage,
    color: Colors.red,
    title: 'Cache Management',
    subtitle: 'Clear lyrics and artwork cache',
    screen: CacheScreen(),
    content: CacheSettingsContent(),
  ),
  experimental(
    icon: Icons.science,
    color: Colors.amber,
    title: 'Experimental',
    subtitle: 'Unstable features and fixes',
    screen: ExperimentalScreen(),
    content: ExperimentalSettingsContent(),
  );

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget screen;
  final Widget content;

  const _SettingsDestination({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.screen,
    required this.content,
  });
}
