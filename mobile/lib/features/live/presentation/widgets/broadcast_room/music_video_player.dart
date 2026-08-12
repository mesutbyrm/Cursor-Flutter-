import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../providers/live_room_music_provider.dart';

/// Canlı yayın — koltukların altında tek video player (sesli odada ASLA kullanılmaz).
class MusicVideoPlayer extends ConsumerStatefulWidget {
  const MusicVideoPlayer({
    super.key,
    required this.streamId,
  });

  final String streamId;

  @override
  ConsumerState<MusicVideoPlayer> createState() => _MusicVideoPlayerState();
}

class _MusicVideoPlayerState extends ConsumerState<MusicVideoPlayer> {
  VideoPlayerController? _controller;
  String? _loadedUrl;
  var _initializing = false;

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    _loadedUrl = null;
    unawaited(c?.dispose());
  }

  Future<void> _ensureController(String url, {required bool playing}) async {
    if (_loadedUrl == url && _controller != null) {
      if (playing && !_controller!.value.isPlaying) {
        await _controller!.play();
      } else if (!playing && _controller!.value.isPlaying) {
        await _controller!.pause();
      }
      return;
    }
    if (_initializing) return;
    _initializing = true;
    _disposeController();
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.setLooping(false);
      await controller.setVolume(1);
      if (playing) {
        await controller.play();
      }
      setState(() {
        _controller = controller;
        _loadedUrl = url;
      });
    } catch (_) {
      if (mounted) {
        ref.read(liveRoomMusicProvider(widget.streamId).notifier).markPlaybackError();
      }
    } finally {
      _initializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(
      liveRoomMusicProvider(widget.streamId).select(
        (s) => (url: s.videoUrl, playing: s.playing, active: s.hasActiveVideo),
      ),
    );

    if (!music.active || music.url == null) {
      if (_controller != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _disposeController();
          setState(() {});
        });
      }
      return const SizedBox.shrink();
    }

    final url = music.url!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureController(url, playing: music.playing));
    });

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        child: VideoPlayer(controller),
      ),
    );
  }
}
