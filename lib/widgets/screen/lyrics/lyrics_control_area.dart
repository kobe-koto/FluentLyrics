import 'package:flutter/material.dart';
import '../../../providers/lyrics_provider.dart';

class LyricsControlArea extends StatelessWidget {
  final LyricsProvider provider;
  final bool isScrubbing;
  final double scrubValue;
  final Function(double) onScrubChanged;
  final Function(double) onScrubEnd;

  const LyricsControlArea({
    super.key,
    required this.provider,
    required this.isScrubbing,
    required this.scrubValue,
    required this.onScrubChanged,
    required this.onScrubEnd,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final metadata = provider.currentMetadata;
    final totalMs = metadata?.duration.inMilliseconds ?? 1;

    final offsetSeconds = provider.trackOffset.inMilliseconds / 1000.0;
    final offsetText =
        "${offsetSeconds >= 0 ? '+' : ''}${offsetSeconds.toStringAsFixed(2)}s";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OffsetButton(
                icon: Icons.remove_circle_outline,
                onPressed: () => provider.adjustTrackOffset(
                  const Duration(milliseconds: -250),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPress: () => provider.setTrackOffset(Duration.zero),
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 10,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: Colors.white.withAlpha(150),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        offsetText,
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OffsetButton(
                icon: Icons.add_circle_outline,
                onPressed: () => provider.adjustTrackOffset(
                  const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<Duration>(
            valueListenable: provider.currentPositionNotifier,
            builder: (context, currentPosition, child) {
              final currentMs = currentPosition.inMilliseconds;
              final progress = (currentMs / totalMs).clamp(0.0, 1.0);

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      disabledActiveTrackColor: Colors.white,
                      disabledInactiveTrackColor: Colors.white.withValues(
                        alpha: 0.1,
                      ),
                      thumbColor: Colors.white,
                      trackHeight: 4,
                      thumbShape: provider.controlAbility.canSeek
                          ? const RoundSliderThumbShape(enabledThumbRadius: 6)
                          : SliderComponentShape.noThumb,
                      overlayColor: Colors.white.withValues(alpha: 0.1),
                      trackShape: _CustomSliderTrackShape(),
                    ),
                    child: RepaintBoundary(
                      child: Slider(
                        value: isScrubbing ? scrubValue : progress,
                        onChanged: provider.controlAbility.canSeek
                            ? (value) => onScrubChanged(value)
                            : null,
                        onChangeEnd: (value) => onScrubEnd(value),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RepaintBoundary(
                        child: Text(
                          _formatDuration(
                            isScrubbing
                                ? Duration(
                                    milliseconds: (scrubValue * totalMs)
                                        .round(),
                                  )
                                : currentPosition,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: Text(
                          _formatDuration(metadata?.duration ?? Duration.zero),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: Colors.white,
                iconSize: 32,
                onPressed: provider.controlAbility.canGoPrevious
                    ? provider.previousTrack
                    : null,
                disabledColor: Colors.white.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                iconSize: 48,
                onPressed: provider.controlAbility.canPlayPause
                    ? provider.playPause
                    : null,
                disabledColor: Colors.white.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: Colors.white,
                iconSize: 32,
                onPressed: provider.controlAbility.canGoNext
                    ? provider.nextTrack
                    : null,
                disabledColor: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OffsetButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OffsetButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withAlpha(100), size: 20),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
