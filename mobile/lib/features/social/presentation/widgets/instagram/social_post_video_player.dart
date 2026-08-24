import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../shorts/presentation/utils/short_video_player_util.dart';

/// Sosyal akış kartında kısa video — dokunulana kadar oynatılmaz (bellek/FPS).
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
  var _loading = false;
  var _error = false;
  var _started = false;

  @override
  void didUpdateWidget(covariant SocialPostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      setState(() {
        _started = false;
        _loading = false;
        _error = false;
      });
    }
  }

  Future<void> _startPlayback() async {
    if (_started || _loading) return;
    setState(() {
      _started = true;
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
      await c.setLooping(true);
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
        child: !_started
            ? GestureDetector(
                onTap: _startPlayback,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CanlifalNetworkImage(
                      url: widget.videoUrl,
                      fit: BoxFit.cover,
                      placeholder: const _VideoPosterPlaceholder(),
                      errorWidget: const _VideoPosterPlaceholder(),
                    ),
                    const Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _loading
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

class _VideoPosterPlaceholder extends StatelessWidget {
  const _VideoPosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF12121E),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white24,
          size: 40,
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
