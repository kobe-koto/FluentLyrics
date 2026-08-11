import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';

class AboutDiagnosticsScreen extends StatefulWidget {
  const AboutDiagnosticsScreen({super.key});

  @override
  State<AboutDiagnosticsScreen> createState() => _AboutDiagnosticsScreenState();
}

class _AboutDiagnosticsScreenState extends State<AboutDiagnosticsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
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
    final diagnostics = await _collectDiagnostics();
    if (!mounted) return;

    _controller.text = diagnostics;
    setState(() => _loading = false);
    await _copyToClipboard(automatic: true);
  }

  Future<String> _collectDiagnostics() async {
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

    return [
      'Fluent Lyrics $version',
      'Platform: ${Platform.operatingSystem}',
      'OS: ${Platform.operatingSystemVersion}',
      'Dart: ${Platform.version}',
      'Mode: $mode',
    ].join('\n');
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
