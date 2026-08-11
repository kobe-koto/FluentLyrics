import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../constants/app_defaults.dart';
import '../../i18n/strings.g.dart';
import '../../models/lyric_provider_type.dart';
import '../../providers/lyrics_provider_settings.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_scaffold.dart';

class AboutDiagnosticsScreen extends StatefulWidget {
  const AboutDiagnosticsScreen({super.key});

  @override
  State<AboutDiagnosticsScreen> createState() => _AboutDiagnosticsScreenState();
}

class _AboutDiagnosticsScreenState extends State<AboutDiagnosticsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _includeConfiguration = false;
  String? _copyMessage;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    final diagnostics = await _collectDiagnostics(
      includeConfiguration: _includeConfiguration,
    );
    if (!mounted) return;

    _controller.text = diagnostics;
    setState(() => _loading = false);
    await _copyToClipboard(automatic: true);
  }

  Future<void> _setIncludeConfiguration(bool value) async {
    setState(() {
      _includeConfiguration = value;
      _loading = true;
      _copyMessage = null;
    });

    final diagnostics = await _collectDiagnostics(includeConfiguration: value);
    if (!mounted) return;

    _controller.text = diagnostics;
    setState(() => _loading = false);
  }

  Future<String> _collectDiagnostics({
    required bool includeConfiguration,
  }) async {
    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      // The remaining platform details are still useful without package info.
    }

    final version = packageInfo == null
        ? 'unknown'
        : '${packageInfo.version}+${packageInfo.buildNumber}';
    final mode = kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release');

    final lines = [
      'Fluent Lyrics $version',
      'Mode: $mode',
      'Platform: ${Platform.operatingSystem}',
      'OS: ${Platform.operatingSystemVersion}',
      'Dart: ${Platform.version}',
    ];

    if (includeConfiguration) {
      lines.add('');
      try {
        lines.addAll(await _collectConfiguration());
      } catch (_) {
        lines.add('Configuration unavailable: <error>');
      }
    }

    return lines.join('\n');
  }

  Future<List<String>> _collectConfiguration() async {
    final settingsService = SettingsService();
    final settings = await LyricsProviderSettings.load(settingsService);
    final allProviders =
        (await settingsService.getAllProvidersOrdered()).current;
    final enabledCount = (await settingsService.getEnabledCount()).current;
    final locale = await settingsService.getLocale();
    final musixmatchToken = await settingsService.getMusixmatchToken();

    final enabledProviders = allProviders.take(enabledCount).toList();
    final disabledProviders = allProviders.skip(enabledCount).toList();
    final effectivePriority = [
      if (settings.cacheEnabled.current) LyricProviderType.cache,
      ...enabledProviders,
    ];
    final apiKeyConfigured =
        settings.llmApiKey.current.isNotEmpty &&
        settings.llmApiKey.current != AppDefaults.llmApiKey;
    final musixmatchTokenConfigured =
        musixmatchToken.current?.trim().isNotEmpty == true;

    return [
      'Configuration:',
      'Locale: ${locale ?? 'system'}',
      'Provider order: ${_formatProviders(effectivePriority)}',
      'Enabled provider count: ${enabledProviders.length}/${allProviders.length}',
      'Disabled providers: ${_formatProviders(disabledProviders)}',
      'Cache enabled: ${settings.cacheEnabled.current}',
      'Lines before active: ${settings.linesBefore.current}',
      'Global lyrics offset: ${settings.globalOffsetMs.current} ms',
      'Auto-resume delay: ${settings.scrollAutoResumeDelay.current} s',
      'Blur enabled: ${settings.blurEnabled.current}',
      'Rich sync enabled: ${settings.richSyncEnabled.current}',
      'Metadata trim providers: ${_formatProviders(settings.trimMetadataProviders.current)}',
      'Font size: ${settings.fontSize.current}',
      'Inactive line scale: ${settings.inactiveScale.current}',
      'Keep screen on: ${settings.keepScreenOn.current}',
      'Background motion enabled: ${settings.backgroundMotionEnabled.current}',
      'Artwork minimum size: ${settings.artworkMinSize.current} px',
      'Translation enabled: ${settings.translationEnabled.current}',
      'Translation target languages: ${_formatValues(settings.translationTargetLanguages.current)}',
      'Translation ignored languages: ${_formatValues(settings.translationIgnoredLanguages.current)}',
      'Translation highlight only: ${settings.translationHighlightOnly.current}',
      'Translation bias: ${settings.translationBias.current} ms',
      'Translation alignment threshold: ${settings.translationAlignmentThreshold.current}%',
      'Translation coverage threshold: ${settings.translationCoverageThreshold.current}%',
      'LLM endpoint: ${_safeEndpoint(settings.llmApiEndpoint.current)}',
      'LLM model: ${settings.llmModel.current}',
      'LLM reasoning effort: ${settings.llmReasoningEffort.current}',
      'LLM API key configured: $apiKeyConfigured',
      'Musixmatch token configured: $musixmatchTokenConfigured',
      'Experimental rich inline font fix: ${settings.experimentalRichInlineFontSizeGlitching.current}',
      'System tray enabled: ${settings.trayEnabled.current}',
      'Hide to tray on close: ${settings.hideToTrayOnClose.current}',
      'Lyrics stream configured: ${settings.lyricsStreamPath.current.isNotEmpty}',
      'Translation stream configured: ${settings.translationStreamPath.current.isNotEmpty}',
      'Configuration secrets and file paths omitted: true',
    ];
  }

  String _formatProviders(List<LyricProviderType> providers) {
    if (providers.isEmpty) return '<none>';
    return providers.map((provider) => provider.name).join(' > ');
  }

  String _formatValues(List<String> values) {
    if (values.isEmpty) return '<none>';
    return values.join(', ');
  }

  String _safeEndpoint(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || uri.host.isEmpty) {
      return endpoint.isEmpty ? '<not set>' : '<configured>';
    }

    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Future<void> _copyToClipboard({required bool automatic}) async {
    if (_controller.text.isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: _controller.text));
      if (!mounted) return;
      setState(() {
        _copyMessage = automatic
            ? t.about.diagnosticsPage.automaticCopySuccess
            : t.about.diagnosticsPage.copied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _copyMessage = automatic
            ? t.about.diagnosticsPage.automaticCopyFailed
            : t.about.diagnosticsPage.copyFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = t.about.diagnosticsPage;
    return SettingsScaffold(
      title: diagnostics.title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                title: Text(
                  diagnostics.includeConfiguration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  diagnostics.includeConfigurationSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                  ),
                ),
                value: _includeConfiguration,
                onChanged: _loading ? null : _setIncludeConfiguration,
                activeThumbColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _controller,
                readOnly: true,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.045),
                  contentPadding: const EdgeInsets.all(18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loading
                  ? null
                  : () => _copyToClipboard(automatic: false),
              icon: const Icon(Icons.copy_all_rounded),
              label: Text(diagnostics.copy),
            ),
            if (_copyMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _copyMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
