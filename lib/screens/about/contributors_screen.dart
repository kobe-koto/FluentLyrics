import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';

class AboutContributorsScreen extends StatefulWidget {
  const AboutContributorsScreen({super.key});

  @override
  State<AboutContributorsScreen> createState() =>
      _AboutContributorsScreenState();
}

class _AboutContributorsScreenState extends State<AboutContributorsScreen> {
  static final Uri _contributorsApiUri = Uri.parse(
    'https://api.github.com/repos/kobe-koto/FluentLyrics/contributors',
  );

  late Future<List<_GithubContributor>> _contributorsFuture;

  @override
  void initState() {
    super.initState();
    _contributorsFuture = _fetchContributors();
  }

  Future<List<_GithubContributor>> _fetchContributors() async {
    final response = await http
        .get(
          _contributorsApiUri,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'FluentLyrics',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'GitHub API returned ${response.statusCode}',
        _contributorsApiUri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Unexpected GitHub contributors response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_GithubContributor.fromJson)
        .where((contributor) => contributor.login.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _reload() async {
    setState(() {
      _contributorsFuture = _fetchContributors();
    });
    await _contributorsFuture;
  }

  Future<void> _openProfile(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.about.linkUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.about.contributors,
      child: FutureBuilder<List<_GithubContributor>>(
        future: _contributorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ContributorsMessage(
              icon: Icons.cloud_off_outlined,
              message: t.about.contributorsPage.loadFailed,
              action: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.about.contributorsPage.retry),
              ),
            );
          }

          final contributors = snapshot.data ?? const <_GithubContributor>[];
          if (contributors.isEmpty) {
            return _ContributorsMessage(
              icon: Icons.people_outline,
              message: t.about.contributorsPage.empty,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              itemCount: contributors.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final contributor = contributors[index];
                return _ContributorRow(
                  contributor: contributor,
                  contributionsLabel: t.about.contributorsPage.contributions(
                    count: contributor.contributions,
                  ),
                  onTap: () => _openProfile(contributor.profileUri),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ContributorsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _ContributorsMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.white.withValues(alpha: 0.45)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _ContributorRow extends StatelessWidget {
  final _GithubContributor contributor;
  final String contributionsLabel;
  final VoidCallback onTap;

  const _ContributorRow({
    required this.contributor,
    required this.contributionsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _ContributorAvatar(contributor: contributor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.login,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contributionsLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.32),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
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

class _ContributorAvatar extends StatelessWidget {
  final _GithubContributor contributor;

  const _ContributorAvatar({required this.contributor});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      child: ClipOval(
        child: Image.network(
          contributor.avatarUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            contributor.login.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GithubContributor {
  final String login;
  final String avatarUrl;
  final int contributions;
  final Uri profileUri;

  const _GithubContributor({
    required this.login,
    required this.avatarUrl,
    required this.contributions,
    required this.profileUri,
  });

  factory _GithubContributor.fromJson(Map<String, dynamic> json) {
    final login = json['login'] as String? ?? '';
    final avatarUrl = json['avatar_url'] as String? ?? '';
    final profileUrl = json['html_url'] as String? ?? '';
    final rawContributions = json['contributions'];
    final contributions = rawContributions is num
        ? rawContributions.toInt()
        : int.tryParse('$rawContributions') ?? 0;

    return _GithubContributor(
      login: login,
      avatarUrl: avatarUrl,
      contributions: contributions,
      profileUri: Uri.tryParse(profileUrl) ?? Uri.parse('https://github.com'),
    );
  }
}
