import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_section.dart';
import '../../settings_card_frame.dart';
import '../../settings_group.dart';
import '../../../utils/cache_helper.dart';

class CacheSection extends StatefulWidget {
  final VoidCallback onRefresh;
  final Function(String message) showSnackBar;

  const CacheSection({
    super.key,
    required this.onRefresh,
    required this.showSnackBar,
  });

  @override
  State<CacheSection> createState() => _CacheSectionState();
}

class _CacheSectionState extends State<CacheSection> {
  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.cache;
    return SettingsSection(
      title: i18n.sectionTitle,
      description: i18n.sectionDescription,
      children: [
        SettingsGroup(
          children: [
            SettingsCardFrame(
              child: Consumer<LyricsProvider>(
                builder: (context, provider, child) {
                  return _CacheActionCard(
                    title: i18n.lyricsCacheTitle,
                    description: i18n.lyricsCacheDescription,
                    stats: FutureBuilder<Map<String, dynamic>>(
                      future: provider.getCacheStats(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final count = snapshot.data!['count'];
                          final size = snapshot.data!['size'];
                          return Text(
                            i18n.lyricsCacheStats(
                              count: count.toString(),
                              size: CacheHelper.formatSize(size),
                            ),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    actionButton: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            title: Text(
                              i18n.clearDialogTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              i18n.clearDialogContent,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(t.common.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  t.common.clearAll,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await provider.clearAllCache();
                          if (mounted) {
                            setState(() {});
                            widget.onRefresh();
                            widget.showSnackBar(i18n.cleared);
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: Text(
                        i18n.clearLyricsCacheButton,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SettingsCardFrame(
              child: _CacheActionCard(
                title: i18n.artworkCacheTitle,
                description: i18n.artworkCacheDescription,
                stats: FutureBuilder<Map<String, int>>(
                  future: CacheHelper.getArtworkCacheStats(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final count = snapshot.data!['count']!;
                      final size = snapshot.data!['size']!;
                      return Text(
                        i18n.artworkCacheStats(
                          count: count.toString(),
                          size: CacheHelper.formatSize(size),
                        ),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                actionButton: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: Text(
                          i18n.artworkClearDialogTitle,
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          i18n.artworkClearDialogContent,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(t.common.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              t.common.clearAll,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await CacheHelper.clearArtworkCache();
                      if (mounted) {
                        setState(() {});
                        widget.onRefresh();
                        widget.showSnackBar(i18n.artworkCleared);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: Text(
                    i18n.clearArtworkCacheButton,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            SettingsCardFrame(
              child: _KanjiDictCard(
                onRefresh: () {
                  if (mounted) setState(() {});
                  widget.onRefresh();
                },
                showSnackBar: widget.showSnackBar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CacheActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget stats;
  final Widget actionButton;

  const _CacheActionCard({
    required this.title,
    required this.description,
    required this.stats,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            stats,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: actionButton)]),
      ],
    );
  }
}

/// The extracted kanji reading dictionary: shows its version and size, with
/// reload (re-extract from bundle) and clear (remove extracted copy) actions.
class _KanjiDictCard extends StatefulWidget {
  final VoidCallback onRefresh;
  final void Function(String message) showSnackBar;

  const _KanjiDictCard({required this.onRefresh, required this.showSnackBar});

  @override
  State<_KanjiDictCard> createState() => _KanjiDictCardState();
}

class _KanjiDictCardState extends State<_KanjiDictCard> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(LyricsProvider p) action,
    String doneMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final provider = context.read<LyricsProvider>();
    await action(provider);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onRefresh();
    widget.showSnackBar(doneMessage);
  }

  Future<void> _download() async {
    if (_busy) return;
    final i18n = t.settings.cache;
    setState(() => _busy = true);
    widget.showSnackBar(i18n.kanjiDictDownloading);
    final provider = context.read<LyricsProvider>();
    final version = await provider.downloadKanjiReadingDictionary();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onRefresh();
    widget.showSnackBar(
      version == null
          ? i18n.kanjiDictDownloadFailed
          : i18n.kanjiDictDownloaded(version: version),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.cache;
    final provider = context.read<LyricsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              i18n.kanjiDictTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: provider.getKanjiReadingStats(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                final version = data?['version'] as String?;
                final text = version == null
                    ? i18n.kanjiDictMissing
                    : i18n.kanjiDictStats(
                        version: version,
                        size: CacheHelper.formatSize(data!['size'] as int),
                      );
                return Text(
                  text,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          i18n.kanjiDictDescription,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _download,
                icon: const Icon(Icons.cloud_download, size: 18),
                label: Text(
                  i18n.kanjiDictDownloadButton,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  foregroundColor: Colors.greenAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                        (p) => p.reloadKanjiReadingDictionary(),
                        i18n.kanjiDictReloaded,
                      ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  i18n.kanjiDictReloadButton,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  foregroundColor: Colors.blueAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                        (p) => p.clearKanjiReadingDictionary(),
                        i18n.kanjiDictCleared,
                      ),
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: Text(
                  i18n.kanjiDictClearButton,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  foregroundColor: Colors.redAccent,
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
    );
  }
}
