import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../live/domain/entities/live_stream_entity.dart';

/// Ana sayfa canlı kartı — varsayılan thumbnail; HLS yalnızca [eager] ise.
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
  VideoPlayerController? _initController;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    if (widget.eager) {
      unawaited(_initVideo());
    }
  }

  @override
  void didUpdateWidget(covariant LiveStreamPreviewMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eager && !oldWidget.eager) {
      unawaited(_initVideo());
    } else if (!widget.eager && oldWidget.eager) {
      _disposeController();
    } else if (widget.stream.id != oldWidget.stream.id) {
      _disposeController();
      if (widget.eager) unawaited(_initVideo());
    }
  }

  Future<void> _initVideo() async {
    final url = widget.stream.playbackUrl?.trim();
    if (url == null || url.isEmpty || !widget.eager) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _initController = c;
    try {
      await c.initialize();
      if (!mounted || _initController != c) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted || _initController != c) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (_) {
      if (_initController == c) _initController = null;
      await c.dispose();
    }
  }

  void _disposeController() {
    final pending = _initController;
    _initController = null;
    if (pending != null) unawaited(pending.dispose());
    final active = _controller;
    _controller = null;
    if (active != null) unawaited(active.dispose());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _disposeController();
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
          CanlifalNetworkImage(
            url: thumb,
            fit: BoxFit.cover,
            thumbnailWidth: 320,
            fadeIn: true,
            errorWidget: _placeholder(),
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
