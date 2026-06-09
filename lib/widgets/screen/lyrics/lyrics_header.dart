import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/app_logger.dart';
import '../../../providers/lyrics_provider.dart';
import '../../../screens/settings_screen.dart';
import 'delayed_loading_image.dart';
import 'lyrics_candidate_sheet.dart';

class LyricsHeader extends StatelessWidget {
  final LyricsProvider provider;
  final ImageProvider artProvider;
  final VoidCallback onRefresh;
  final bool isLandscape;

  const LyricsHeader({
    super.key,
    required this.provider,
    required this.artProvider,
    required this.onRefresh,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return isLandscape
        ? _buildLandscapeHeader(context)
        : _buildPortraitHeader(context);
  }

  Widget _buildPortraitHeader(BuildContext context) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildArtThumb(artProvider),
          const SizedBox(width: 16),
          Expanded(
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata?.title ?? t.lyrics.noMedia,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    metadata?.artist.join(', ') ?? t.lyrics.waitForMusic,
                    style: TextStyle(
                      color: Colors.white.withAlpha(136),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white.withAlpha(200)),
              onPressed: onRefresh,
              tooltip: t.lyrics.clearCacheTooltip,
            ),
          ),
          RepaintBoundary(child: _CandidatesButton(provider: provider)),
          RepaintBoundary(
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: t.lyrics.settingsTooltip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeHeader(BuildContext context) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Center(child: _buildArtThumb(artProvider, true)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Metadata
              Expanded(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata?.title ?? t.lyrics.noMedia,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata?.artist.join(', ') ?? t.lyrics.waitForMusic,
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Refresh lyrics
              RepaintBoundary(
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white.withAlpha(200)),
                  iconSize: 28,
                  onPressed: onRefresh,
                  tooltip: t.lyrics.clearCacheTooltip,
                ),
              ),
              // Candidates
              RepaintBoundary(
                child: _CandidatesButton(provider: provider, iconSize: 28),
              ),
              // Settings
              RepaintBoundary(
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  iconSize: 28,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: t.lyrics.settingsTooltip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtThumb(ImageProvider artImage, [bool large = false]) {
    return RepaintBoundary(
      child: Container(
        width: large ? double.infinity : 64,
        height: large ? double.infinity : 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(large ? 24 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: large ? 24 : 12,
              offset: Offset(0, large ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(large ? 24 : 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double dpr = MediaQuery.of(context).devicePixelRatio;
              final int? cacheWidth = constraints.maxWidth.isFinite
                  ? (constraints.maxWidth * dpr).round()
                  : null;
              final int? cacheHeight = constraints.maxHeight.isFinite
                  ? (constraints.maxHeight * dpr).round()
                  : null;

              return DelayedLoadingImage(
                image: artImage,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.debug('Error loading album art: $error');
                  return Image.asset('assets/album_art.png', fit: BoxFit.cover);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Icon button that opens the lyrics candidate picker sheet.
/// Shows an animated pulsing dot when the stream is paused awaiting user input.
class _CandidatesButton extends StatelessWidget {
  final LyricsProvider provider;
  final double? iconSize;

  const _CandidatesButton({required this.provider, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final hasCandidates = provider.candidates.isNotEmpty;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Icon(
            Icons.library_music_rounded,
            // this is intended, implied theres no candidates, but user can still open it
            color: hasCandidates
                ? Colors.white
                : Colors.white.withValues(alpha: 0.75),
          ),
          iconSize: iconSize ?? 24,
          tooltip: t.lyrics.chooseLyricsTooltip,
          onPressed: () => showLyricsCandidateSheet(context, provider),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 900),
          )
          ..addStatusListener((status) {
            if (status != AnimationStatus.dismissed) return;
            _completedCycles++;
            if (_completedCycles >= 3 && _ctrl.isAnimating) {
              _ctrl.stop();
              _ctrl.value = 1.0;
            }
          })
          ..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
