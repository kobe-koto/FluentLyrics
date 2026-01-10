import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/lyric_line.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  static const int _linesBefore = 2;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _scrollToCurrentIndex(int index) {
    if (_itemScrollController.isAttached) {
      // Line-based scroll: target the line N lines before the current one
      final targetIndex = (index - _linesBefore).clamp(0, index);
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        // Auto-scroll logic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // trigger only once for same index
          if (provider.currentIndex != this._previousIndex) {
            _scrollToCurrentIndex(provider.currentIndex);
            this._previousIndex = provider.currentIndex;
          }
        });

        return Scaffold(
          body: Stack(
            children: [
              // Background Layer: Blurred Album Art
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/album_art.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

              // Lyrics Layer
              SafeArea(
                child: Column(
                  children: [
                    // Header (Optional: Mock Player Info)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: const DecorationImage(
                                image: AssetImage('assets/album_art.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Never Gonna Give You Up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Rick Astley",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              provider.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 48,
                            ),
                            onPressed: () => provider.togglePlayPause(),
                          ),
                        ],
                      ),
                    ),

                    // Main Lyrics List
                    Expanded(
                      child: ScrollablePositionedList.builder(
                        itemCount: provider.lyrics.length,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        itemBuilder: (context, index) {
                          final lyric = provider.lyrics[index];
                          final isHighlighted = index == provider.currentIndex;
                          final distance = (index - provider.currentIndex)
                              .toDouble();

                          return LyricLine(
                            text: lyric.text,
                            isHighlighted: isHighlighted,
                            distance: distance,
                          );
                        },
                      ),
                    ),

                    // Progress Bar Mock
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: provider.lyrics.isEmpty
                                ? 0
                                : provider.currentPosition.inMilliseconds /
                                      (provider
                                              .lyrics
                                              .last
                                              .startTime
                                              .inMilliseconds +
                                          5000),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(provider.currentPosition),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  provider.lyrics.isEmpty
                                      ? Duration.zero
                                      : provider.lyrics.last.startTime +
                                            const Duration(seconds: 5),
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
