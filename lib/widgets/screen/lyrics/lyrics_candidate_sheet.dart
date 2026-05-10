import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/lyric_model.dart';
import '../../../models/lyric_provider_type.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../utils/translation_helper.dart';

/// Shows a modal bottom sheet that lists all lyric candidates and translation
/// candidates collected during the current auto-search.
Future<void> showLyricsCandidateSheet(
  BuildContext context,
  LyricsProvider provider,
) {
  // If the fetch is paused waiting for this sheet, resume it now so remaining
  // providers are queried while the user browses the list.
  provider.resumeCandidateFetch();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LyricsCandidateSheet(provider: provider),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _LyricsCandidateSheet extends StatefulWidget {
  final LyricsProvider provider;
  const _LyricsCandidateSheet({required this.provider});

  @override
  State<_LyricsCandidateSheet> createState() => _LyricsCandidateSheetState();
}

class _LyricsCandidateSheetState extends State<_LyricsCandidateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _showTranslationTab;

  @override
  void initState() {
    super.initState();
    _showTranslationTab = widget.provider.translationEnabled.current;
    _tabController = TabController(
      length: _showTranslationTab ? 2 : 1,
      vsync: this,
    );
    widget.provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final newShow = widget.provider.translationEnabled.current;
    if (newShow != _showTranslationTab) {
      // Rebuild the TabController with the new length.
      final old = _tabController;
      _tabController = TabController(length: newShow ? 2 : 1, vsync: this);
      old.dispose();
      _showTranslationTab = newShow;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Listener(
      // Close on mouse back button.
      onPointerDown: (event) {
        if (event.buttons == kBackMouseButton) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          // Tapping the transparent area above the sheet dismisses it.
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.60, 0.92],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // ── Drag handle ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Header row ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.library_music_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Lyrics Picker',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (provider.isFetching)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Tab bar — hidden when translation is off ──────────
                    if (_showTranslationTab) ...[
                      _TabBar(
                        controller: _tabController,
                        lyricsCount: provider.candidates.length,
                        translationCount: provider.translationCandidates.length,
                      ),
                      const Divider(color: Colors.white12, height: 1),
                    ],

                    // ── Status bar ───────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child:
                          provider.isFetching &&
                              provider.loadingStatus.isNotEmpty
                          ? Container(
                              key: const ValueKey('status'),
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                provider.loadingStatus,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    // ── Tab views ────────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ── Lyrics tab (always present) ───────────────
                          _LyricsTab(
                            provider: provider,
                            scrollController: scrollController,
                          ),
                          // ── Translation tab (only when enabled) ───────
                          if (_showTranslationTab)
                            _TranslationTab(
                              provider: provider,
                              scrollController: scrollController,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom segmented tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  final int lyricsCount;
  final int translationCount;

  const _TabBar({
    required this.controller,
    required this.lyricsCount,
    required this.translationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.12),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        splashBorderRadius: BorderRadius.circular(10),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note_rounded, size: 14),
                const SizedBox(width: 6),
                const Text('Lyrics'),
                if (lyricsCount > 0) ...[
                  const SizedBox(width: 5),
                  _CountBadge(lyricsCount),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.translate_rounded, size: 14),
                const SizedBox(width: 6),
                const Text('Translation'),
                if (translationCount > 0) ...[
                  const SizedBox(width: 5),
                  _CountBadge(translationCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lyrics tab
// ─────────────────────────────────────────────────────────────────────────────

class _LyricsTab extends StatelessWidget {
  final LyricsProvider provider;
  final ScrollController scrollController;

  const _LyricsTab({required this.provider, required this.scrollController});

  bool _isActive(LyricsResult candidate, LyricsResult current) {
    final candidateSrc = candidate.source.replaceAll(' (cached)', '');
    final currentSrc = current.source.replaceAll(' (cached)', '');
    return candidateSrc == currentSrc &&
        candidate.isSynced == current.isSynced &&
        candidate.isRichSync == current.isRichSync;
  }

  @override
  Widget build(BuildContext context) {
    final candidates = provider.candidates;
    final current = provider.lyricsResult;

    // All rich-sync candidates that could be used as Richify sources.
    final richSources = candidates
        .where((c) => c.isRichSync)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              provider.isLoading
                  ? 'Searching providers…'
                  : 'No candidates found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
            if (!provider.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: () => provider.refetchLyrics(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Lyrics'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.lightBlue.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: candidates.length + 1,
      itemBuilder: (context, index) {
        if (index == candidates.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: provider.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.lightBlue.withValues(alpha: 0.5),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => provider.refetchLyrics(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Lyrics'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.lightBlue.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
            ),
          );
        }

        final candidate = candidates[index];
        final isActive = _isActive(candidate, current);

        // Only synced (non-rich) tiles can be Richified.
        final canRichify =
            candidate.isSynced &&
            !candidate.isRichSync &&
            richSources.isNotEmpty;

        return _CandidateTile(
          candidate: candidate,
          isActive: isActive,
          richSources: canRichify ? richSources : const [],
          onSelect: () {
            provider.selectCandidate(candidate);
            Navigator.of(context).pop();
          },
          onRichify: canRichify
              ? (richSource) async {
                  await provider.richifyCandidate(
                    syncedTarget: candidate,
                    richSource: richSource,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                }
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Translation tab
// ─────────────────────────────────────────────────────────────────────────────

class _TranslationTab extends StatelessWidget {
  final LyricsProvider provider;
  final ScrollController scrollController;

  const _TranslationTab({
    required this.provider,
    required this.scrollController,
  });

  bool _isActive(LyricsResult candidate, LyricsResult? current) {
    if (current == null) return false;
    final cProv = (candidate.translationProvider ?? '').replaceAll(
      ' (cached)',
      '',
    );
    final aProv = (current.translationProvider ?? '').replaceAll(
      ' (cached)',
      '',
    );
    return cProv == aProv && candidate.language == current.language;
  }

  /// Count how many non-empty original lines have a matching translation.
  /// Returns (matched, total).
  (int, int) _coverage(LyricsResult trans, List<Lyric> displayLyrics) {
    if (trans.rawTranslation == null) {
      final totalLines = displayLyrics
          .where((l) => l.text.trim().isNotEmpty)
          .length;
      return (0, totalLines);
    }
    return TranslationHelper.coverage(
      currentLyrics: displayLyrics,
      rawTranslation: trans.rawTranslation!,
      similarityThreshold: provider.translationAlignmentThreshold.current,
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = provider.translationCandidates;
    final current = provider.translationResult;
    // Use provider.lyrics — the actual displayed list (rich sync stripped
    // when disabled) — so coverage reflects exactly what the user sees.
    final displayLyrics = provider.lyrics;

    if (candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              provider.isFetching
                  ? 'Searching translations...'
                  : 'No alternatives found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (!provider.isFetching)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: () => provider.refetchTranslations(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Translations'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: candidates.length + 1,
      itemBuilder: (context, index) {
        if (index == candidates.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: provider.isFetching
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.teal.withValues(alpha: 0.5),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => provider.refetchTranslations(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Translations'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.teal.withValues(alpha: 0.8),
                      ),
                    ),
            ),
          );
        }

        final candidate = candidates[index];
        final isActive = _isActive(candidate, current);
        final (matched, total) = _coverage(candidate, displayLyrics);
        return _TranslationTile(
          candidate: candidate,
          isActive: isActive,
          matchedLines: matched,
          totalLines: total,
          onSelect: () {
            provider.selectTranslationCandidate(candidate);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lyrics candidate tile
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateTile extends StatelessWidget {
  final LyricsResult candidate;
  final bool isActive;
  final VoidCallback onSelect;

  /// Rich-sync candidates available as Richify sources. Empty = Richify hidden.
  final List<LyricsResult> richSources;

  /// Called with the chosen rich source when the user taps Richify.
  final void Function(LyricsResult richSource)? onRichify;

  const _CandidateTile({
    required this.candidate,
    required this.isActive,
    required this.onSelect,
    this.richSources = const [],
    this.onRichify,
  });

  LyricProviderType? _providerType() {
    final src = candidate.source.toLowerCase();
    if (src.contains('lrclib')) return LyricProviderType.lrclib;
    if (src.contains('musixmatch')) return LyricProviderType.musixmatch;
    if (src.contains('netease')) return LyricProviderType.netease;
    if (src.contains('qq')) return LyricProviderType.qqmusic;
    if (src.contains('cache')) return LyricProviderType.cache;
    return null;
  }

  String _syncLabel() {
    if (candidate.isPureMusic) return 'Instrumental';
    if (candidate.isRichSync) return 'Rich Sync';
    if (candidate.isSynced) return 'Synced';
    return 'Plain';
  }

  IconData _syncIcon() {
    if (candidate.isPureMusic) return Icons.music_note_rounded;
    if (candidate.isRichSync) return Icons.auto_awesome_rounded;
    if (candidate.isSynced) return Icons.timer_rounded;
    return Icons.notes_rounded;
  }

  Color _syncColor() {
    if (candidate.isPureMusic) return Colors.purple;
    if (candidate.isRichSync) return Colors.amber;
    if (candidate.isSynced) return Colors.lightBlue;
    return Colors.grey;
  }

  String _preview() {
    final lines = candidate.lyrics
        .where((l) => l.text.trim().isNotEmpty)
        .take(2)
        .map((l) => l.text.trim())
        .join('  /  ');
    return lines.isEmpty ? '(no lyrics)' : lines;
  }

  /// Shows a source-picker dialog when multiple rich-sync candidates exist,
  /// otherwise applies the only available source directly.
  Future<void> _handleRichify(BuildContext context) async {
    if (richSources.isEmpty || onRichify == null) return;
    if (richSources.length == 1) {
      onRichify!(richSources.first);
      return;
    }
    // Multiple rich sources — let the user choose.
    final chosen = await showDialog<LyricsResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 18),
            SizedBox(width: 8),
            Text(
              'Choose Rich Sync Source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: richSources.map((src) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                src.source.replaceAll(' (cached)', ''),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                '${src.lyrics.where((l) => l.inlineParts != null && l.inlineParts!.isNotEmpty).length} rich lines',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
              onTap: () => Navigator.of(ctx).pop(src),
            );
          }).toList(),
        ),
      ),
    );
    if (chosen != null) onRichify!(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final providerType = _providerType();
    final providerColor = providerType != null
        ? (providerType.metadata['color'] as Color)
        : Colors.grey;
    final providerName = candidate.source;

    return GestureDetector(
      onTap: isActive ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(label: providerName, color: providerColor),
                  const SizedBox(width: 6),
                  _Badge(
                    label: _syncLabel(),
                    icon: _syncIcon(),
                    color: _syncColor(),
                  ),
                  const Spacer(),
                  // Richify button — only on synced, non-rich tiles
                  if (richSources.isNotEmpty && onRichify != null) ...[
                    _RichifyButton(onTap: () => _handleRichify(context)),
                    const SizedBox(width: 8),
                  ],
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _preview(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                candidate.isPureMusic
                    ? 'Instrumental track'
                    : '${candidate.lyrics.length} lines',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Translation candidate tile
// ─────────────────────────────────────────────────────────────────────────────

class _TranslationTile extends StatelessWidget {
  final LyricsResult candidate;
  final bool isActive;
  final int matchedLines;
  final int totalLines;
  final VoidCallback onSelect;

  const _TranslationTile({
    required this.candidate,
    required this.isActive,
    required this.matchedLines,
    required this.totalLines,
    required this.onSelect,
  });

  LyricProviderType? _providerType() {
    final src = (candidate.translationProvider ?? '').toLowerCase();
    if (src.contains('netease')) return LyricProviderType.netease;
    if (src.contains('qqmusic') || src.contains('qq')) {
      return LyricProviderType.qqmusic;
    }
    if (src.contains('musixmatch')) return LyricProviderType.musixmatch;
    if (src.contains('llm')) return LyricProviderType.llm;
    if (src.contains('cache')) return LyricProviderType.cache;
    return null;
  }

  /// Return the first non-empty translated line as a preview.
  String _preview() {
    if (candidate.rawTranslation == null) return '(no preview)';
    final first = candidate.rawTranslation!
        .where((m) => (m['translated'] ?? '').trim().isNotEmpty)
        .take(2)
        .map((m) => m['translated']!.trim())
        .join('  /  ');
    return first.isEmpty ? '(no preview)' : first;
  }

  @override
  Widget build(BuildContext context) {
    final providerType = _providerType();
    final providerColor = providerType != null
        ? (providerType.metadata['color'] as Color)
        : Colors.teal;

    final providerLabel = (candidate.translationProvider ?? 'Unknown')
        .replaceAll(' (cached)', '');
    final langLabel = candidate.language?.toUpperCase() ?? '?';

    final coverage = totalLines == 0 ? 0.0 : matchedLines / totalLines;

    return GestureDetector(
      onTap: isActive ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: provider + language badge + checkmark ──────
              Row(
                children: [
                  _Badge(label: providerLabel, color: providerColor),
                  const SizedBox(width: 6),
                  _Badge(
                    label: langLabel,
                    icon: Icons.translate_rounded,
                    color: Colors.teal,
                  ),
                  if (candidate.translationContributor != null) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      label: candidate.translationContributor!,
                      color: Colors.blueGrey,
                    ),
                  ],
                  const Spacer(),
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Coverage bar ────────────────────────────────────────
              _CoverageBar(
                matched: matchedLines,
                total: totalLines,
                fraction: coverage,
              ),

              const SizedBox(height: 10),

              // ── Translation preview ─────────────────────────────────
              Text(
                _preview(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isActive ? 0.85 : 0.50),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coverage bar widget
// ─────────────────────────────────────────────────────────────────────────────

class _CoverageBar extends StatelessWidget {
  final int matched;
  final int total;
  final double fraction; // 0.0 – 1.0

  const _CoverageBar({
    required this.matched,
    required this.total,
    required this.fraction,
  });

  Color _barColor() {
    if (fraction >= 0.9) return Colors.greenAccent;
    if (fraction >= 0.6) return Colors.lightGreenAccent;
    if (fraction >= 0.35) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    final pct = (fraction * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.align_vertical_bottom_rounded,
              size: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 5),
            Text(
              '$matched / $total lines matched',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              color.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Richify button
// ─────────────────────────────────────────────────────────────────────────────

class _RichifyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RichifyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.25),
              Colors.orange.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 11,
              color: Colors.amber.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Text(
              'Richify',
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
