import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';

class AboutProvidersScreen extends StatelessWidget {
  const AboutProvidersScreen({super.key});

  static final _providers = [
    _Provider(
      icon: Icons.library_music_outlined,
      name: 'musixmatch',
      uri: 'https://www.musixmatch.com/',
    ),
    _Provider(
      icon: Icons.library_music_outlined,
      name: 'netease',
      uri: 'https://music.163.com/',
    ),
    _Provider(
      icon: Icons.library_music_outlined,
      name: 'qqmusic',
      uri: 'https://y.qq.com/',
    ),
    _Provider(
      icon: Icons.lyrics_outlined,
      name: 'lrclib',
      uri: 'https://lrclib.net/',
    ),
    _Provider(icon: Icons.auto_awesome_outlined, name: 'llm'),
  ];

  Future<void> _openExternal(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.about.linkUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final about = t.about;
    final providers = [
      _ProviderDetails(
        item: _providers[0],
        name: about.providers.musixmatch.name,
        description: about.providers.musixmatch.description,
      ),
      _ProviderDetails(
        item: _providers[1],
        name: about.providers.netease.name,
        description: about.providers.netease.description,
      ),
      _ProviderDetails(
        item: _providers[2],
        name: about.providers.qqmusic.name,
        description: about.providers.qqmusic.description,
      ),
      _ProviderDetails(
        item: _providers[3],
        name: about.providers.lrclib.name,
        description: about.providers.lrclib.description,
      ),
      _ProviderDetails(
        item: _providers[4],
        name: about.providers.llm.name,
        description: about.providers.llm.description,
      ),
    ];

    return SettingsScaffold(
      title: about.lyricsProviders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        itemCount: providers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final provider = providers[index];
          return _ProviderRow(
            provider: provider,
            onTap: provider.item.uri == null
                ? null
                : () => _openExternal(context, provider.item.uri!),
          );
        },
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final _ProviderDetails provider;
  final VoidCallback? onTap;

  const _ProviderRow({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(
              provider.item.icon,
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ],
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

class _ProviderDetails {
  final _Provider item;
  final String name;
  final String description;

  const _ProviderDetails({
    required this.item,
    required this.name,
    required this.description,
  });
}

class _Provider {
  final IconData icon;
  final String name;
  final String? uri;

  const _Provider({required this.icon, required this.name, this.uri});
}
