import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../live/domain/entities/live_stream_entity.dart';

/// Ana sayfa canlı kartı — HLS varsa video, yoksa thumbnail + LIVE animasyonu.
class LiveStreamPreviewMedia extends StatefulWidget {
  const LiveStreamPreviewMedia({
    super.key,
    required this.stream,
    this.eager = false,
  });

  final LiveStreamEntity stream;
  final bool eager;

  @override
  State<LiveStreamPreviewMedia> createState() => _LiveStreamPreviewMediaState();
}

class _LiveStreamPreviewMediaState extends State<LiveStreamPreviewMedia>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.stream.playbackUrl?.trim();
    if (url == null || url.isEmpty) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (widget.eager) await c.play();
      if (mounted) setState(() => _controller = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulse.dispose();
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

    final thumb = widget.stream.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: thumb,
            fit: BoxFit.cover,
            memCacheWidth: widget.eager ? 480 : 320,
            fadeInDuration: widget.eager ? Duration.zero : const Duration(milliseconds: 180),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
          _liveShimmer(),
        ],
      );
    }
    return _placeholder();
  }

  Widget _liveShimmer() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.04 + _pulse.value * 0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFF1A1030),
      child: Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}
