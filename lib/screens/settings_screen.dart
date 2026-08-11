import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../i18n/strings.g.dart';
import '../widgets/settings_scaffold.dart';
import 'about_screen.dart';
import '../widgets/screen/settings/version_section.dart';
import 'settings/priority_screen.dart';
import 'settings/display_screen.dart';
import 'settings/translation_screen.dart';
import 'settings/lyric_configuration_screen.dart';
import 'settings/cache_screen.dart';
import 'settings/experimental_screen.dart';
import 'settings/misc_screen.dart';
import 'settings/language_screen.dart';

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
    final i18n = t;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= 960 &&
            constraints.maxWidth > constraints.maxHeight;
        return SettingsScaffold(
          title: i18n.settings.title,
          child: isWide
              ? _buildWideLayout(context, i18n)
              : _buildCompactLayout(context, i18n),
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context, Translations i18n) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        for (final destination in _SettingsDestination.values)
          _SettingsEntry(
            destination: destination,
            i18n: i18n,
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

  Widget _buildWideLayout(BuildContext context, Translations i18n) {
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
                            i18n.settings.preferences,
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
                                i18n: i18n,
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
                                destination.localizedTitle(i18n),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                destination.localizedSubtitle(i18n),
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
  final Translations i18n;
  final bool selected;
  final bool showAccentBar;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsEntry({
    required this.destination,
    required this.i18n,
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
                              destination.localizedTitle(i18n),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destination.localizedSubtitle(i18n),
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
    screen: PriorityScreen(),
    content: PrioritySettingsContent(),
  ),
  display(
    icon: Icons.display_settings,
    color: Colors.purple,
    screen: DisplayScreen(),
    content: DisplaySettingsContent(),
  ),
  translation(
    icon: Icons.translate,
    color: Colors.teal,
    screen: TranslationScreen(),
    content: TranslationSettingsContent(),
  ),
  lyricConfiguration(
    icon: Icons.music_note,
    color: Colors.orange,
    screen: LyricConfigurationScreen(),
    content: LyricConfigurationSettingsContent(),
  ),
  cache(
    icon: Icons.storage,
    color: Colors.red,
    screen: CacheScreen(),
    content: CacheSettingsContent(),
  ),
  experimental(
    icon: Icons.science,
    color: Colors.amber,
    screen: ExperimentalScreen(),
    content: ExperimentalSettingsContent(),
  ),
  misc(
    icon: Icons.tune,
    color: Colors.green,
    screen: MiscScreen(),
    content: MiscSettingsContent(),
  ),
  language(
    icon: Icons.language,
    color: Colors.cyan,
    screen: LanguageScreen(),
    content: LanguageSettingsContent(),
  ),
  about(
    icon: Icons.info_outline,
    color: Colors.blueGrey,
    screen: AboutScreen(),
    content: AboutContent(),
  );

  final IconData icon;
  final Color color;
  final Widget screen;
  final Widget content;

  const _SettingsDestination({
    required this.icon,
    required this.color,
    required this.screen,
    required this.content,
  });

  String localizedTitle(Translations t) {
    return switch (this) {
      priority => t.settings.destinations.priority.title,
      display => t.settings.destinations.display.title,
      translation => t.settings.destinations.translation.title,
      lyricConfiguration => t.settings.destinations.lyricConfiguration.title,
      cache => t.settings.destinations.cache.title,
      experimental => t.settings.destinations.experimental.title,
      misc => t.settings.destinations.misc.title,
      language => t.settings.language.title,
      about => t.about.title,
    };
  }

  String localizedSubtitle(Translations t) {
    return switch (this) {
      priority => t.settings.destinations.priority.subtitle,
      display => t.settings.destinations.display.subtitle,
      translation => t.settings.destinations.translation.subtitle,
      lyricConfiguration => t.settings.destinations.lyricConfiguration.subtitle,
      cache => t.settings.destinations.cache.subtitle,
      experimental => t.settings.destinations.experimental.subtitle,
      misc => t.settings.destinations.misc.subtitle,
      language => t.settings.language.subtitle,
      about => t.about.subtitle,
    };
  }
}
