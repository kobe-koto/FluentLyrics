import 'dart:async';
import 'package:flutter/material.dart';

class DelayedLoadingImage extends StatefulWidget {
  final ImageProvider image;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final int? cacheWidth;
  final int? cacheHeight;

  const DelayedLoadingImage({
    super.key,
    required this.image,
    required this.fit,
    this.errorBuilder,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<DelayedLoadingImage> createState() => _DelayedLoadingImageState();
}

class _DelayedLoadingImageState extends State<DelayedLoadingImage> {
  bool _showLoading = false;
  Timer? _timer;
  late ImageProvider _resolvedImage;

  @override
  void initState() {
    super.initState();
    _resolvedImage = _buildResolvedImage();
    _startTimer();
  }

  @override
  void didUpdateWidget(DelayedLoadingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image ||
        widget.cacheWidth != oldWidget.cacheWidth ||
        widget.cacheHeight != oldWidget.cacheHeight) {
      _resolvedImage = _buildResolvedImage();
      _startTimer();
    }
  }

  ImageProvider _buildResolvedImage() {
    if (widget.cacheWidth == null && widget.cacheHeight == null) {
      return widget.image;
    }

    return ResizeImage(
      widget.image,
      width: widget.cacheWidth,
      height: widget.cacheHeight,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _showLoading = false;
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _resolvedImage,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: widget.errorBuilder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          _timer?.cancel();
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (_showLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
