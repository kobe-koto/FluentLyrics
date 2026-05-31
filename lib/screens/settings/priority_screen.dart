import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../models/lyric_provider_type.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/priority_section.dart';

class PriorityScreen extends StatefulWidget {
  const PriorityScreen({super.key});

  @override
  State<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends State<PriorityScreen> {
  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.priority.title,
      child: const PrioritySettingsContent(),
    );
  }
}

class PrioritySettingsContent extends StatefulWidget {
  const PrioritySettingsContent({super.key});

  @override
  State<PrioritySettingsContent> createState() =>
      _PrioritySettingsContentState();
}

class _PrioritySettingsContentState extends State<PrioritySettingsContent> {
  final SettingsService _settingsService = SettingsService();

  List<LyricProviderType> _allProviders = [];
  int _enabledCount = 0;
  bool _cacheEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final allProviders =
        (await _settingsService.getAllProvidersOrdered()).current;
    final enabledCount = (await _settingsService.getEnabledCount()).current;
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;
    setState(() {
      _allProviders = allProviders;
      _enabledCount = enabledCount;
      _cacheEnabled = cacheEnabled;
      _isLoading = false;
    });
  }

  Future<void> _savePriority() async {
    await _settingsService.setPriority(_allProviders);
    await _settingsService.setEnabledCount(_enabledCount);
    if (mounted) _showSnackBar(t.settings.priority.updated);
  }

  Future<void> _toggleCache(bool enabled) async {
    setState(() => _cacheEnabled = enabled);
    await _settingsService.setCacheEnabled(enabled);
    if (mounted) {
      _showSnackBar(
        enabled
            ? t.settings.priority.cacheEnabled
            : t.settings.priority.cacheDisabled,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: PrioritySection(
              allProviders: _allProviders,
              enabledCount: _enabledCount,
              cacheEnabled: _cacheEnabled,
              onReorder: (newProviders, newEnabledCount) {
                setState(() {
                  _allProviders = newProviders;
                  _enabledCount = newEnabledCount;
                });
                _savePriority();
              },
              onCacheToggle: _toggleCache,
            ),
          );
  }
}
