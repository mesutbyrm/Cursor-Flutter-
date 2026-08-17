import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Yerel video dosyası için küçük önizleme — composer ve create sayfası.
class SocialLocalVideoPreview extends StatefulWidget {
  const SocialLocalVideoPreview({
    super.key,
    required this.videoPath,
    this.fit = BoxFit.cover,
  });

  final String videoPath;
  final BoxFit fit;

  @override
  State<SocialLocalVideoPreview> createState() => _SocialLocalVideoPreviewState();
}

class _SocialLocalVideoPreviewState extends State<SocialLocalVideoPreview> {
  File? _thumbnail;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant SocialLocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _loading = true;
      _thumbnail = null;
    });
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: 500,
        maxWidth: 720,
        quality: 85,
      );
      if (!mounted) return;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _thumbnail = file;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fallback icon below.
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbnail;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (thumb != null)
          Image.file(thumb, fit: widget.fit)
        else
          const ColoredBox(
            color: Color(0xFF1A0F3D),
            child: Center(
              child: Icon(
                Icons.videocam_rounded,
                size: 48,
                color: Colors.white54,
              ),
            ),
          ),
        if (_loading)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (!_loading)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 52,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }
}
