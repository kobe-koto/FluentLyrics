import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/settings_service.dart';
import '../../settings_section.dart';

class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  final SettingsService _settingsService = SettingsService();

  /// null means "follow system".
  String? _savedLocaleTag;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tag = await _settingsService.getLocale();
    if (mounted) {
      setState(() {
        _savedLocaleTag = tag;
        _loaded = true;
      });
    }
  }

  Future<void> _setLocale(AppLocale? locale) async {
    if (locale == null) {
      // Follow system
      await _settingsService.setLocale(null);
      LocaleSettings.useDeviceLocale();
    } else {
      await _settingsService.setLocale(locale.languageTag);
      LocaleSettings.setLocale(locale);
    }
    if (mounted) {
      setState(() {
        _savedLocaleTag = locale?.languageTag;
      });
    }
  }

  String _displayName(AppLocale locale) {
    return switch (locale) {
      AppLocale.en => 'English',
      AppLocale.zhCn => '简体中文',
      AppLocale.zhTw => '繁體中文',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final i18n = t;
    return SettingsSection(
      title: i18n.settings.language.title,
      description: i18n.settings.language.subtitle,
      children: [
        _LanguageTile(
          label: i18n.settings.language.system,
          subtitle: null,
          selected: _savedLocaleTag == null,
          onTap: () => _setLocale(null),
        ),
        const SizedBox(height: 8),
        for (final locale in AppLocale.values) ...[
          _LanguageTile(
            label: _displayName(locale),
            subtitle: locale.languageTag,
            selected: _savedLocaleTag == locale.languageTag,
            onTap: () => _setLocale(locale),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.cyan.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.cyan, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
