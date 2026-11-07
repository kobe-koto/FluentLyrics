import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../widgets/settings_card_frame.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_scaffold.dart';
import 'about_screen.dart';
import 'settings/priority_screen.dart';
import 'settings/display_screen.dart';
import 'settings/translation_screen.dart';
import 'settings/lyric_configuration_screen.dart';
import 'settings/cache_screen.dart';
import 'settings/misc_screen.dart';
import 'settings/language_screen.dart';
import 'settings/appearance_screen.dart';
import '../theme/settings_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsDestination _selectedDestination = _SettingsDestination.priority;

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final (index, group) in _SettingsGroup.values.indexed) ...[
          if (index > 0) const SizedBox(height: 20),
          SettingsGroup(
            children: [
              for (final destination in group.destinations)
                _SettingsEntry(
                  destination: destination,
                  i18n: i18n,
                  selected: false,
                  showAccentBar: false,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: context.settingsColors.fg(0.3),
                  ),
                  onTap: () => _push(context, destination.screen),
                ),
            ],
          ),
        ],
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
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView(
                      children: [
                        for (final (index, group)
                            in _SettingsGroup.values.indexed) ...[
                          if (index > 0) const SizedBox(height: 16),
                          SettingsGroup(
                            children: [
                              for (final destination in group.destinations)
                                _SettingsEntry(
                                  destination: destination,
                                  i18n: i18n,
                                  selected: destination == _selectedDestination,
                                  showAccentBar: true,
                                  trailing: null,
                                  onTap: () {
                                    setState(() {
                                      _selectedDestination = destination;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.settingsColors.fg(0.04),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.settingsColors.fg(0.06)),
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
                                style: TextStyle(
                                  color: context.settingsColors.onSurface,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                destination.localizedSubtitle(i18n),
                                style: TextStyle(
                                  color: context.settingsColors.fg(0.45),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: context.settingsColors.fg(0.06),
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
    return SettingsCardFrame(
      padding: EdgeInsets.zero,
      color: selected ? context.settingsColors.fg(0.1) : null,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: SettingsGroupMetrics.groupedPadding,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.settingsColors.fg(selected ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      destination.icon,
                      color: context.settingsColors.fg(selected ? 1.0 : 0.8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.localizedTitle(i18n),
                          style: TextStyle(
                            color: context.settingsColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 600),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          destination.localizedSubtitle(i18n),
                          style: TextStyle(
                            color: context.settingsColors.fg(
                              selected ? 0.7 : 0.5,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontVariations: const <FontVariation>[
                              FontVariation('wght', 400),
                            ],
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
          if (showAccentBar)
            Positioned(
              left: 0,
              top: 16,
              bottom: 16,
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
                          width: 3,
                          decoration: BoxDecoration(
                            color: context.settingsColors.onSurface,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(2),
                            ),
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

enum _SettingsGroup {
  lyrics([
    _SettingsDestination.priority,
    _SettingsDestination.display,
    _SettingsDestination.translation,
    _SettingsDestination.lyricConfiguration,
  ]),
  app([
    _SettingsDestination.cache,
    _SettingsDestination.misc,
    _SettingsDestination.language,
    _SettingsDestination.appearance,
  ]),
  about([_SettingsDestination.about]);

  final List<_SettingsDestination> destinations;

  const _SettingsGroup(this.destinations);
}

enum _SettingsDestination {
  priority(
    icon: Icons.sort,
    screen: PriorityScreen(),
    content: PrioritySettingsContent(),
  ),
  display(
    icon: Icons.display_settings,
    screen: DisplayScreen(),
    content: DisplaySettingsContent(),
  ),
  translation(
    icon: Icons.translate,
    screen: TranslationScreen(),
    content: TranslationSettingsContent(),
  ),
  lyricConfiguration(
    icon: Icons.music_note,
    screen: LyricConfigurationScreen(),
    content: LyricConfigurationSettingsContent(),
  ),
  cache(
    icon: Icons.storage,
    screen: CacheScreen(),
    content: CacheSettingsContent(),
  ),
  misc(icon: Icons.tune, screen: MiscScreen(), content: MiscSettingsContent()),
  language(
    icon: Icons.language,
    screen: LanguageScreen(),
    content: LanguageSettingsContent(),
  ),
  appearance(
    icon: Icons.palette_outlined,
    screen: AppearanceScreen(),
    content: AppearanceSettingsContent(),
  ),
  about(
    icon: Icons.info_outline,
    screen: AboutScreen(),
    content: AboutContent(),
  );

  final IconData icon;
  final Widget screen;
  final Widget content;

  const _SettingsDestination({
    required this.icon,
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
      misc => t.settings.destinations.misc.title,
      language => t.settings.language.title,
      appearance => t.settings.appearance.title,
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
      misc => t.settings.destinations.misc.subtitle,
      language => t.settings.language.subtitle,
      appearance => t.settings.appearance.subtitle,
      about => t.about.subtitle,
    };
  }
}
