import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../../shorts/presentation/utils/short_video_player_util.dart';

/// Sosyal akış kartında kısa video oynatıcı (sessiz, döngülü).
class SocialPostVideoPlayer extends ConsumerStatefulWidget {
  const SocialPostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.aspectRatio = 4 / 5,
  });

  final String videoUrl;
  final String? videoId;
  final double aspectRatio;

  @override
  ConsumerState<SocialPostVideoPlayer> createState() =>
      _SocialPostVideoPlayerState();
}

class _SocialPostVideoPlayerState extends ConsumerState<SocialPostVideoPlayer> {
  VideoPlayerController? _controller;
  var _loading = true;
  var _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant SocialPostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final dio = ref.read(dioProvider);
      final c = await createShortVideoController(
        url: widget.videoUrl,
        videoId: widget.videoId,
        dio: dio,
      );
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setVolume(0);
      await c.play();
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ColoredBox(
        color: Colors.black,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            : _error || c == null || !c.value.isInitialized
                ? const Center(
                    child: Icon(
                      Icons.videocam_off_outlined,
                      color: Colors.white38,
                      size: 40,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  ),
      ),
    );
  }
}

bool socialPostLooksLikeVideo({
  String? postType,
  String? mediaUrl,
}) {
  if (postType == 'video') return true;
  final url = mediaUrl?.toLowerCase().trim() ?? '';
  if (url.isEmpty) return false;
  return url.contains('.mp4') ||
      url.contains('.mov') ||
      url.contains('.webm') ||
      url.contains('/shorts/videos/');
}
