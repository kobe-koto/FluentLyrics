import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../widgets/settings_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(title: t.about.title, child: const AboutContent());
  }
}

class AboutContent extends StatefulWidget {
  const AboutContent({super.key});

  @override
  State<AboutContent> createState() => _AboutContentState();
}

class _AboutContentState extends State<AboutContent> {
  static final Uri _projectUri = Uri.parse(
    'https://github.com/kobe-koto/FluentLyrics',
  );
  static final Uri _releaseUri = Uri.parse(
    'https://github.com/kobe-koto/FluentLyrics/releases',
  );
  static final Uri _issueUri = Uri.parse(
    'https://github.com/kobe-koto/FluentLyrics/issues',
  );
  static final Uri _contributorsUri = Uri.parse(
    'https://github.com/kobe-koto/FluentLyrics/graphs/contributors',
  );

  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = packageInfo);
    } catch (_) {
      // Keep the page usable when package metadata is unavailable.
    }
  }

  Future<void> _openExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage(t.about.linkUnavailable);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _copyDiagnostics() async {
    final packageInfo = _packageInfo;
    final version = packageInfo == null
        ? 'unknown'
        : '${packageInfo.version}+${packageInfo.buildNumber}';
    final mode = kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release');
    final diagnostics = [
      'Fluent Lyrics $version',
      'Platform: ${Platform.operatingSystem}',
      'OS: ${Platform.operatingSystemVersion}',
      'Mode: $mode',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: diagnostics));
    if (mounted) _showMessage(t.about.diagnosticsCopied);
  }

  void _showLicenses() {
    final packageInfo = _packageInfo;
    showLicensePage(
      context: context,
      applicationName: 'Fluent Lyrics',
      applicationVersion: packageInfo == null
          ? null
          : '${packageInfo.version}+${packageInfo.buildNumber}',
      applicationIcon: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Image.asset(
          'assets/icons/logo-rounded.png',
          width: 48,
          height: 48,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final about = t.about;
    final packageInfo = _packageInfo;
    final version = packageInfo == null
        ? '...'
        : about.version(
            version: packageInfo.version,
            build: packageInfo.buildNumber,
          );

    final providers = [
      _AboutProvider(
        icon: Icons.library_music_outlined,
        name: about.providers.musixmatch.name,
        description: about.providers.musixmatch.description,
        uri: Uri.parse('https://www.musixmatch.com/'),
      ),
      _AboutProvider(
        icon: Icons.library_music_outlined,
        name: about.providers.netease.name,
        description: about.providers.netease.description,
        uri: Uri.parse('https://music.163.com/'),
      ),
      _AboutProvider(
        icon: Icons.library_music_outlined,
        name: about.providers.qqmusic.name,
        description: about.providers.qqmusic.description,
        uri: Uri.parse('https://y.qq.com/'),
      ),
      _AboutProvider(
        icon: Icons.lyrics_outlined,
        name: about.providers.lrclib.name,
        description: about.providers.lrclib.description,
        uri: Uri.parse('https://lrclib.net/'),
      ),
      _AboutProvider(
        icon: Icons.auto_awesome_outlined,
        name: about.providers.llm.name,
        description: about.providers.llm.description,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              _buildIdentity(version),
              const SizedBox(height: 32),
              _AboutSection(
                title: about.project,
                children: [
                  _AboutActionRow(
                    icon: Icons.code_rounded,
                    title: about.sourceCode,
                    subtitle: about.sourceCodeSubtitle,
                    onTap: () => _openExternal(_projectUri),
                  ),
                  _AboutActionRow(
                    icon: Icons.new_releases_outlined,
                    title: about.releaseNotes,
                    subtitle: about.releaseNotesSubtitle,
                    onTap: () => _openExternal(_releaseUri),
                  ),
                  _AboutActionRow(
                    icon: Icons.bug_report_outlined,
                    title: about.reportIssue,
                    subtitle: about.reportIssueSubtitle,
                    onTap: () => _openExternal(_issueUri),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _AboutSection(
                title: about.credits,
                children: [
                  _AboutActionRow(
                    icon: Icons.people_outline,
                    title: about.contributors,
                    subtitle: about.contributorsSubtitle,
                    onTap: () => _openExternal(_contributorsUri),
                  ),
                  _AboutActionRow(
                    icon: Icons.library_music_outlined,
                    title: about.lyricsProviders,
                    subtitle: about.lyricsProvidersSubtitle,
                    onTap: null,
                  ),
                  for (final provider in providers)
                    _AboutProviderRow(
                      provider: provider,
                      onTap: provider.uri == null
                          ? null
                          : () => _openExternal(provider.uri!),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              _AboutSection(
                title: about.legal,
                children: [
                  _AboutActionRow(
                    icon: Icons.description_outlined,
                    title: about.openSourceLicenses,
                    subtitle: about.openSourceLicensesSubtitle,
                    onTap: _showLicenses,
                  ),
                  _AboutActionRow(
                    icon: Icons.content_copy_outlined,
                    title: about.diagnostics,
                    subtitle: about.diagnosticsSubtitle,
                    onTap: _copyDiagnostics,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                about.builtWith,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity(String version) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/icons/logo-rounded.png',
            width: 96,
            height: 96,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Fluent Lyrics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.about.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.48),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            version,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AboutSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ..._withSpacing(children),
      ],
    );
  }

  List<Widget> _withSpacing(List<Widget> items) {
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 8));
      spaced.add(items[i]);
    }
    return spaced;
  }
}

class _AboutActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _AboutActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _AboutRowSurface(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.72)),
      title: title,
      subtitle: subtitle,
      trailing: onTap == null
          ? null
          : Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.32),
            ),
    );
  }
}

class _AboutProviderRow extends StatelessWidget {
  final _AboutProvider provider;
  final VoidCallback? onTap;

  const _AboutProviderRow({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _AboutRowSurface(
      onTap: onTap,
      leading: Icon(
        provider.icon,
        color: Colors.white.withValues(alpha: 0.58),
        size: 20,
      ),
      title: provider.name,
      subtitle: provider.description,
      trailing: onTap == null
          ? null
          : Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.32),
            ),
      dense: true,
    );
  }
}

class _AboutRowSurface extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool dense;

  const _AboutRowSurface({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 16 : 18,
        vertical: dense ? 12 : 15,
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: dense ? 14 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class _AboutProvider {
  final IconData icon;
  final String name;
  final String description;
  final Uri? uri;

  const _AboutProvider({
    required this.icon,
    required this.name,
    required this.description,
    this.uri,
  });
}
