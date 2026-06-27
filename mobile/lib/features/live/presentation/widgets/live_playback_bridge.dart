import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Oda içi HLS köprüsü — Agora hazır olana kadar ilk kare (sessiz döngü).
class LivePlaybackBridge extends StatefulWidget {
  const LivePlaybackBridge({
    super.key,
    this.playbackUrl,
    this.thumbnailUrl,
  });

  final String? playbackUrl;
  final String? thumbnailUrl;

  @override
  State<LivePlaybackBridge> createState() => _LivePlaybackBridgeState();
}

class _LivePlaybackBridgeState extends State<LivePlaybackBridge> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(LivePlaybackBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackUrl != widget.playbackUrl) {
      _controller?.dispose();
      _controller = null;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.playbackUrl?.trim();
    if (url == null || url.isEmpty) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _controller = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    }

    final thumb = widget.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return CanlifalNetworkImage(
        url: thumb,
        fit: BoxFit.cover,
        thumbnailWidth: 720,
        errorWidget: const ColoredBox(color: Color(0xFF1A1030)),
      );
    }

    return const ColoredBox(color: Color(0xFF1A1030));
  }
}
