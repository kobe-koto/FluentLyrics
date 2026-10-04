import 'package:flutter/material.dart';

import '../../../i18n/strings.g.dart';
import '../../../services/musixmatch_token.dart';
import '../../../services/providers/musixmatch_service.dart';
import '../../../services/secret_store.dart';
import '../../../services/secret_store_message.dart';
import '../../../services/settings_service.dart';
import '../../../theme/monospace_text_style.dart';
import '../../settings_card_frame.dart';

class MusixmatchTokenCard extends StatefulWidget {
  const MusixmatchTokenCard({super.key});

  @override
  State<MusixmatchTokenCard> createState() => _MusixmatchTokenCardState();
}

class _MusixmatchTokenCardState extends State<MusixmatchTokenCard> {
  final SettingsService _settingsService = SettingsService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final TextEditingController _tokenController = TextEditingController();

  bool _isFetchingToken = false;
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
        _secretError = null;
      });
    } on SecretStoreException catch (error) {
      if (!mounted) return;
      setState(() {
        _tokenController.text = '';
        _secretError = secretStoreFailureMessage(error.failure);
      });
    }
  }

  Future<void> _saveToken() async {
    try {
      await _settingsService.setMusixmatchToken(_tokenController.text);
      if (!mounted) return;
      setState(() => _secretError = null);
      _showSnackBar(t.settings.priority.tokenSaved);
    } on SecretStoreException catch (error) {
      if (!mounted) return;
      setState(() => _secretError = secretStoreFailureMessage(error.failure));
    }
  }

  Future<void> _getNewToken() async {
    setState(() => _isFetchingToken = true);
    try {
      final newToken = await _musixmatchService.fetchNewToken();
      if (isUsableMusixmatchToken(newToken)) {
        final acquired = newToken!;
        setState(() => _tokenController.text = acquired);
        try {
          await _settingsService.setMusixmatchToken(acquired);
          if (mounted) {
            setState(() => _secretError = null);
            _showSnackBar(t.settings.priority.tokenAcquired);
          }
        } on SecretStoreException catch (error) {
          if (mounted) {
            setState(
              () => _secretError = secretStoreFailureMessage(error.failure),
            );
          }
        }
      } else {
        if (!isUsableMusixmatchToken(_tokenController.text)) {
          _tokenController.text = '';
          try {
            await _settingsService.setMusixmatchToken('');
          } on SecretStoreException catch (error) {
            if (mounted) {
              setState(
                () => _secretError = secretStoreFailureMessage(error.failure),
              );
            }
          }
        }
        if (mounted) _showSnackBar(t.settings.priority.tokenFailed);
      }
    } finally {
      if (mounted) setState(() => _isFetchingToken = false);
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
    final i18n = t.settings.priority;
    return SettingsCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.musixmatchTitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            i18n.musixmatchSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            style: monospaceTextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: i18n.musixmatchHint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => _saveToken(),
          ),
          if (_secretError != null) ...[
            const SizedBox(height: 8),
            Text(
              _secretError!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isFetchingToken ? null : _getNewToken,
                  icon: _isFetchingToken
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    i18n.getNewToken,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    foregroundColor: Colors.orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
