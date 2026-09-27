import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../services/secret_store.dart';
import '../../services/secret_store_message.dart';
import '../../services/providers/musixmatch_service.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/lyric_configuration_section.dart';

class LyricConfigurationScreen extends StatefulWidget {
  const LyricConfigurationScreen({super.key});

  @override
  State<LyricConfigurationScreen> createState() =>
      _LyricConfigurationScreenState();
}

class _LyricConfigurationScreenState extends State<LyricConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.lyricConfiguration.title,
      child: const LyricConfigurationSettingsContent(),
    );
  }
}

class LyricConfigurationSettingsContent extends StatefulWidget {
  const LyricConfigurationSettingsContent({super.key});

  @override
  State<LyricConfigurationSettingsContent> createState() =>
      _LyricConfigurationSettingsContentState();
}

class _LyricConfigurationSettingsContentState
    extends State<LyricConfigurationSettingsContent> {
  final SettingsService _settingsService = SettingsService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final TextEditingController _tokenController = TextEditingController();

  bool _isFetchingToken = false;
  bool _isLoading = true;
  String? _secretError;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final token = (await _settingsService.getMusixmatchToken()).current;
      if (!mounted) return;
      setState(() {
        _tokenController.text = token ?? '';
        _isLoading = false;
        _secretError = null;
      });
    } on SecretStoreException catch (error) {
      if (!mounted) return;
      setState(() {
        _tokenController.text = '';
        _isLoading = false;
        _secretError = secretStoreFailureMessage(error.failure);
      });
    }
  }

  Future<void> _saveToken() async {
    try {
      await _settingsService.setMusixmatchToken(_tokenController.text);
      if (!mounted) return;
      setState(() => _secretError = null);
      _showSnackBar(t.settings.lyricConfig.tokenSaved);
    } on SecretStoreException catch (error) {
      if (!mounted) return;
      setState(() => _secretError = secretStoreFailureMessage(error.failure));
    }
  }

  Future<void> _getNewToken() async {
    setState(() => _isFetchingToken = true);
    try {
      final newToken = await _musixmatchService.fetchNewToken();
      if (newToken != null) {
        setState(() => _tokenController.text = newToken);
        try {
          await _settingsService.setMusixmatchToken(newToken);
          if (mounted) {
            setState(() => _secretError = null);
            _showSnackBar(t.settings.lyricConfig.tokenAcquired);
          }
        } on SecretStoreException catch (error) {
          if (mounted) {
            setState(
              () => _secretError = secretStoreFailureMessage(error.failure),
            );
          }
        }
      } else {
        if (mounted) _showSnackBar(t.settings.lyricConfig.tokenFailed);
      }
    } finally {
      setState(() => _isFetchingToken = false);
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
            child: LyricConfigurationSection(
              tokenController: _tokenController,
              isFetchingToken: _isFetchingToken,
              onGetNewToken: _getNewToken,
              onTokenChanged: _saveToken,
              secretError: _secretError,
            ),
          );
  }
}
