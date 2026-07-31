import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/video/video_cache_service.dart';
import '../../data/gift_cache_service.dart';
import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import '../sync/gift_sync_log.dart';

/// PNG / SVG / WEBP / MP4 — backend `mediaType` ile uyumlu tek oynatıcı.
class GiftMediaWidget extends StatefulWidget {
  const GiftMediaWidget({
    super.key,
    required this.spec,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.autoplay = true,
    this.muted = true,
    this.looping = true,
    this.fallbackEmoji = '🎁',
    this.onVideoControllerChanged,
  });

  final GiftMediaSpec spec;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoplay;
  final bool muted;
  final bool looping;
  final String fallbackEmoji;
  final ValueChanged<VideoPlayerController?>? onVideoControllerChanged;

  @override
  State<GiftMediaWidget> createState() => _GiftMediaWidgetState();
}

class _GiftMediaWidgetState extends State<GiftMediaWidget> {
  VideoPlayerController? _video;
  var _videoFailed = false;
  var _videoReady = false;
  var _firstFrameReady = false;
  Uint8List? _svgBytes;

  @override
  void initState() {
    super.initState();
    if (widget.spec.mediaType.isVideo) {
      _initVideo();
    } else if (widget.spec.mediaType == GiftMediaType.svg) {
      _loadSvg();
    }
  }

  @override
  void didUpdateWidget(covariant GiftMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.mediaUrl != widget.spec.mediaUrl ||
        oldWidget.spec.mediaType != widget.spec.mediaType) {
      _disposeVideo();
      _videoFailed = false;
      _videoReady = false;
      _firstFrameReady = false;
      _svgBytes = null;
      if (widget.spec.mediaType.isVideo) {
        _initVideo();
      } else if (widget.spec.mediaType == GiftMediaType.svg) {
        _loadSvg();
      }
    }
  }

  Future<void> _loadSvg() async {
    final url = widget.spec.mediaUrl?.trim() ?? '';
    if (url.isEmpty) return;
    final bytes = await GiftCacheService.instance.getBytes(url);
    if (!mounted) return;
    if (bytes != null) {
      GiftSyncLog.cacheHit(url, fromMemory: true);
      setState(() => _svgBytes = bytes);
    } else {
      GiftSyncLog.cacheMiss(url);
    }
  }

  void _onVideoTick() {
    final c = _video;
    if (c == null || _firstFrameReady) return;
    if (c.value.isInitialized &&
        (c.value.isPlaying || c.value.position > Duration.zero)) {
      setState(() => _firstFrameReady = true);
    }
  }

  Future<void> _initVideo() async {
    final url = widget.spec.mediaUrl?.trim() ?? '';
    if (url.isEmpty) {
      if (mounted) setState(() => _videoFailed = true);
      return;
    }
    try {
      final cached = await VideoCacheService.instance.peekCachedFile(url);
      if (cached != null) {
        GiftSyncLog.cacheHit(url, fromMemory: false);
      } else {
        GiftSyncLog.cacheMiss(url);
      }

      final warm = VideoCacheService.instance.takeWarmController(url);
      final c = warm ?? await VideoCacheService.instance.createController(url);
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(widget.looping);
      if (widget.muted) await c.setVolume(0);
      await c.seekTo(Duration.zero);
      c.addListener(_onVideoTick);
      if (widget.autoplay) await c.play();
      _video = c;
      widget.onVideoControllerChanged?.call(c);
      setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) {
        widget.onVideoControllerChanged?.call(null);
        setState(() => _videoFailed = true);
      }
    }
  }

  void _disposeVideo() {
    final c = _video;
    _video = null;
    _videoReady = false;
    _firstFrameReady = false;
    if (c != null) {
      c.removeListener(_onVideoTick);
      widget.onVideoControllerChanged?.call(null);
      final url = widget.spec.mediaUrl?.trim();
      if (url != null && url.isNotEmpty) {
        VideoCacheService.instance.releaseWarmController(url, c);
      } else {
        c.dispose();
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    if (!spec.hasPlayableUrl && spec.thumbnailUrl == null) {
      return _emojiFallback();
    }

    if (spec.mediaType.isVideo) {
      return _buildVideo(spec);
    }

    return _buildStatic(spec);
  }

  Widget _buildVideo(GiftMediaSpec spec) {
    if (_videoFailed) {
      return _thumbnailOrEmoji(spec);
    }
    final c = _video;
    if (!_videoReady || c == null || !c.value.isInitialized) {
      return _thumbnailOrEmoji(spec);
    }

    final videoChild = FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );

    return _wrapSized(
      Stack(
        fit: StackFit.passthrough,
        children: [
          if (!_firstFrameReady) _thumbnailOrEmoji(spec, shrink: true),
          Opacity(
            opacity: _firstFrameReady ? 1 : 0,
            child: _aspectWrap(spec, videoChild, c),
          ),
        ],
      ),
    );
  }

  Widget _buildStatic(GiftMediaSpec spec) {
    final url = spec.mediaUrl?.trim() ?? '';
    if (url.isEmpty) return _thumbnailOrEmoji(spec);

    final child = switch (spec.mediaType) {
      GiftMediaType.svg => _svgBytes != null
          ? SvgPicture.memory(
              _svgBytes!,
              fit: widget.fit,
              placeholderBuilder: (_) => _thumbnailOrEmoji(spec, shrink: true),
            )
          : SvgPicture.network(
              url,
              fit: widget.fit,
              placeholderBuilder: (_) => _thumbnailOrEmoji(spec, shrink: true),
            ),
      GiftMediaType.gif ||
      GiftMediaType.png ||
      GiftMediaType.webp ||
      GiftMediaType.unknown =>
        CanlifalNetworkImage(
          url: url,
          fit: widget.fit,
          errorWidget: _thumbnailOrEmoji(spec, shrink: true),
          placeholder: _thumbnailPlaceholder(spec),
        ),
      GiftMediaType.video => const SizedBox.shrink(),
      GiftMediaType.lottie => _thumbnailOrEmoji(spec),
    };

    return _wrapSized(_aspectWrap(spec, child, null));
  }

  Widget _aspectWrap(
    GiftMediaSpec spec,
    Widget child,
    VideoPlayerController? controller,
  ) {
    final ratio = spec.aspectRatio ??
        (controller != null &&
                controller.value.isInitialized &&
                controller.value.size.height > 0
            ? controller.value.size.width / controller.value.size.height
            : null);
    if (ratio != null && ratio > 0) {
      return AspectRatio(aspectRatio: ratio, child: child);
    }
    return child;
  }

  Widget _wrapSized(Widget child) {
    final w = widget.width;
    final h = widget.height;
    if (w != null || h != null) {
      return SizedBox(width: w, height: h, child: child);
    }
    return child;
  }

  Widget _thumbnailOrEmoji(GiftMediaSpec spec, {bool shrink = false}) {
    final thumb = spec.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return _wrapSized(
        CanlifalNetworkImage(
          url: thumb,
          fit: widget.fit,
          width: shrink ? widget.width : null,
          height: shrink ? widget.height : null,
          errorWidget: _emojiFallback(),
        ),
      );
    }
    return _emojiFallback();
  }

  Widget? _thumbnailPlaceholder(GiftMediaSpec spec) {
    final thumb = spec.thumbnailUrl?.trim();
    if (thumb == null || thumb.isEmpty) return null;
    return CanlifalNetworkImage(url: thumb, fit: widget.fit);
  }

  Widget _emojiFallback() {
    final size = widget.width ?? widget.height ?? 48;
    return Center(
      child: Text(
        widget.fallbackEmoji,
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }
}
