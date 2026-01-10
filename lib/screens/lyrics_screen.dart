import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/lyric_line.dart';
import '../services/media_service.dart';

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

  void _scrollToCurrentIndex(int index) {
    if (_itemScrollController.isAttached) {
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
          if (provider.currentIndex != _previousIndex) {
            _scrollToCurrentIndex(provider.currentIndex);
            _previousIndex = provider.currentIndex;
          }
        });

        final metadata = provider.currentMetadata;

        return Scaffold(
          body: Stack(
            children: [
              // Background Layer
              _buildBackground(metadata),

              // Content Layer
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(provider),
                    Expanded(child: _buildLyricsList(provider)),
                    _buildProgressBar(provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(MediaMetadata? metadata) {
    ImageProvider backgroundImage;
    if (metadata != null && metadata.artUrl.isNotEmpty) {
      if (metadata.artUrl.startsWith('file://')) {
        backgroundImage = FileImage(
          File(Uri.parse(metadata.artUrl).toFilePath()),
        );
      } else {
        backgroundImage = NetworkImage(metadata.artUrl);
      }
    } else {
      backgroundImage = const AssetImage('assets/album_art.png');
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: backgroundImage, fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.black.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildHeader(LyricsProvider provider) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildArtThumb(metadata),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata?.title ?? "No Media Playing",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  metadata?.artist ?? "Wait for music...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            provider.isPlaying ? Icons.graphic_eq : Icons.pause,
            color: Colors.white.withOpacity(0.8),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildArtThumb(MediaMetadata? metadata) {
    ImageProvider artImage;
    if (metadata != null && metadata.artUrl.isNotEmpty) {
      if (metadata.artUrl.startsWith('file://')) {
        artImage = FileImage(File(Uri.parse(metadata.artUrl).toFilePath()));
      } else {
        artImage = NetworkImage(metadata.artUrl);
      }
    } else {
      artImage = const AssetImage('assets/album_art.png');
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(image: artImage, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLyricsList(LyricsProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (provider.lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            provider.currentMetadata == null
                ? "Start playing music on your Linux system"
                : "No lyrics found for this track",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemCount: provider.lyrics.length,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemBuilder: (context, index) {
        final lyric = provider.lyrics[index];
        final isHighlighted = index == provider.currentIndex;
        final distance = (index - provider.currentIndex).toDouble();

        return LyricLine(
          text: lyric.text,
          isHighlighted: isHighlighted,
          distance: distance,
        );
      },
    );
  }

  Widget _buildProgressBar(LyricsProvider provider) {
    final metadata = provider.currentMetadata;
    final totalMs = metadata?.duration.inMilliseconds ?? 1;
    final currentMs = provider.currentPosition.inMilliseconds;
    final progress = (currentMs / totalMs).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(provider.currentPosition),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDuration(metadata?.duration ?? Duration.zero),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
