import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/lyric_line.dart';
import '../services/media_service.dart';
import 'settings_screen.dart';

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
  String? _lastArtUrl;
  ImageProvider? _cachedArtProvider;

  ImageProvider _updateArtProvider(MediaMetadata? metadata) {
    final artUrl = metadata?.artUrl.trim();
    final title = metadata?.title;
    final artist = metadata?.artist;

    if (artUrl != null && artUrl.isNotEmpty) {
      if (artUrl == _lastArtUrl && _cachedArtProvider != null) {
        return _cachedArtProvider!;
      }
      _lastArtUrl = artUrl;
      _cachedArtProvider = _getArtProvider(artUrl);
      _lastTitle = title;
      _lastArtist = artist;
    } else {
      // If artUrl is empty, check if we still have the same song.
      // If it's the same song, keep the last cached art (prevent flicker).
      if (title != null &&
          title == _lastTitle &&
          artist == _lastArtist &&
          _cachedArtProvider != null) {
        return _cachedArtProvider!;
      }

      // If it's a new song (or no song) and has no art, reset to default.
      _lastArtUrl = artUrl;
      _cachedArtProvider = const AssetImage('assets/album_art.png');
      _lastTitle = title;
      _lastArtist = artist;
    }

    return _cachedArtProvider!;
  }

  String? _lastTitle;
  String? _lastArtist;

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
        final artProvider = _updateArtProvider(metadata);

        return Scaffold(
          body: Stack(
            children: [
              // Background Layer
              _buildBackground(artProvider),

              // Content Layer
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(provider, artProvider),
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

  Widget _buildBackground(ImageProvider artProvider) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: artProvider, fit: BoxFit.cover),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.black.withAlpha(136)),
      ),
    );
  }

  ImageProvider _getArtProvider(String? artUrl) {
    if (artUrl == null || artUrl.isEmpty) {
      return const AssetImage('assets/album_art.png');
    }

    // Handle data URIs
    if (artUrl.startsWith('data:')) {
      final commaIndex = artUrl.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = artUrl
              .substring(commaIndex + 1)
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          return const AssetImage('assets/album_art.png');
        }
      }
    }

    // Handle file URIs
    if (artUrl.startsWith('file://')) {
      try {
        return FileImage(File(Uri.parse(artUrl).toFilePath()));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    // Handle local paths without file://
    if (artUrl.startsWith('/')) {
      try {
        return FileImage(File(artUrl));
      } catch (e) {
        return const AssetImage('assets/album_art.png');
      }
    }

    // Fallback to NetworkImage for everything else (http, etc.)
    return NetworkImage(artUrl);
  }

  Widget _buildHeader(LyricsProvider provider, ImageProvider artProvider) {
    final metadata = provider.currentMetadata;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildArtThumb(artProvider),
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
                    color: Colors.white.withAlpha(136),
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
            color: Colors.white.withAlpha(200),
            size: 24,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtThumb(ImageProvider artImage) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              provider.loadingStatus.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
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
              color: Colors.white.withValues(alpha: 0.4),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 3),
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
              backgroundColor: Colors.white.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDuration(metadata?.duration ?? Duration.zero),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
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
