import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/images/canlifal_network_image.dart';

/// Admin hediye editörü — görsel / video / ses önizlemesi.
class AdminGiftMediaPreview extends StatefulWidget {
  const AdminGiftMediaPreview({
    super.key,
    required this.url,
    this.size = 56,
    this.isAudio = false,
    this.animationType,
  });

  final String? url;
  final double size;
  final bool isAudio;
  final String? animationType;

  @override
  State<AdminGiftMediaPreview> createState() => _AdminGiftMediaPreviewState();
}

class _AdminGiftMediaPreviewState extends State<AdminGiftMediaPreview> {
  VideoPlayerController? _controller;
  var _videoFailed = false;

  bool get _isVideo {
    final type = widget.animationType?.toLowerCase().trim() ?? '';
    if (type == 'mp4' || type == 'webm' || type == 'video') return true;
    final url = widget.url?.toLowerCase().split('?').first ?? '';
    return url.endsWith('.mp4') || url.endsWith('.webm');
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant AdminGiftMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.animationType != widget.animationType) {
      _disposeVideo();
      _videoFailed = false;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.url?.trim() ?? '';
    if (!_isVideo || url.isEmpty || !url.startsWith('http')) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.setLooping(true);
      c.setVolume(0);
      await c.play();
      setState(() => _controller = c);
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _disposeVideo() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      return Icon(
        widget.isAudio ? Icons.audiotrack_rounded : Icons.perm_media_rounded,
        color: const Color(0xFFB388FF),
      );
    }

    if (widget.isAudio) {
      return const Icon(Icons.audiotrack_rounded, color: Color(0xFF66E36F));
    }

    if (_isVideo) {
      final c = _controller;
      if (c != null && c.value.isInitialized && !_videoFailed) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.videocam_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        );
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.movie_rounded, color: Color(0xFFB388FF), size: 28),
          if (_videoFailed)
            const Positioned(
              bottom: 2,
              right: 2,
              child: Icon(Icons.videocam_rounded, size: 12, color: Colors.white70),
            ),
        ],
      );
    }

    if (url.startsWith('http')) {
      return CanlifalNetworkImage(url: url, fit: BoxFit.cover);
    }

    return const Icon(Icons.perm_media_rounded, color: Color(0xFF66E36F));
  }
}
