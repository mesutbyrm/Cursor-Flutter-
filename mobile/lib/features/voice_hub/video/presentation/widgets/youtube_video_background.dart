import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../data/services/voice_room_debug_log.dart';
import '../../domain/room_video_state.dart';
import '../room_video_controller.dart';

/// Tam ekran YouTube arka plan — koltuk/sohbet üst katmanında kalır.
class YoutubeVideoBackground extends ConsumerStatefulWidget {
  const YoutubeVideoBackground({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  ConsumerState<YoutubeVideoBackground> createState() =>
      _YoutubeVideoBackgroundState();
}

class _YoutubeVideoBackgroundState extends ConsumerState<YoutubeVideoBackground> {
  YoutubePlayerController? _controller;
  String? _loadedVideoId;
  bool? _lastPlaying;
  int _lastSeekMs = -1;

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _ensureController(String videoId) async {
    if (_loadedVideoId == videoId && _controller != null) return;
    await _controller?.close();
    _loadedVideoId = videoId;
    _lastSeekMs = -1;
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        enableCaption: false,
        playsInline: true,
        mute: false,
        loop: false,
        pointerEvents: PointerEvents.none,
        strictRelatedVideos: true,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _syncPlayback(RoomVideoState video) async {
    final ctrl = _controller;
    if (ctrl == null || !video.hasActiveVideo) return;
    final videoId = video.videoId!;
    if (_loadedVideoId != videoId) {
      await _ensureController(videoId);
      final fresh = _controller;
      if (fresh == null) return;
      final startSec = (video.resolvedPositionMs() / 1000).floor();
      try {
        await fresh.loadVideoById(
          videoId: videoId,
          startSeconds: startSec.clamp(0, 86400).toDouble(),
        );
        _lastSeekMs = video.resolvedPositionMs();
        VoiceRoomDebugLog.log('roomVideo.player.load', {
          'videoId': videoId,
          'startSec': startSec,
        });
      } catch (e, st) {
        VoiceRoomDebugLog.log('roomVideo.player.load_fail', {
          'error': e.toString(),
          'stack': st.toString().split('\n').take(2).join(' '),
        });
      }
    }

    final targetMs = video.resolvedPositionMs();
    if ((targetMs - _lastSeekMs).abs() > 2500) {
      final sec = (targetMs / 1000).clamp(0, 86400).toDouble();
      try {
        await ctrl.seekTo(seconds: sec, allowSeekAhead: true);
        _lastSeekMs = targetMs;
      } catch (e) {
        VoiceRoomDebugLog.log('roomVideo.player.seek_fail', {
          'error': e.toString(),
        });
      }
    }

    if (_lastPlaying != video.isPlaying) {
      _lastPlaying = video.isPlaying;
      try {
        if (video.isPlaying) {
          await ctrl.playVideo();
        } else {
          await ctrl.pauseVideo();
        }
      } catch (e) {
        VoiceRoomDebugLog.log('roomVideo.player.playback_fail', {
          'error': e.toString(),
          'playing': video.isPlaying,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(roomVideoControllerProvider(widget.roomKey));
    if (!video.hasActiveVideo) {
      return const SizedBox.shrink();
    }

    ref.listen<RoomVideoState>(roomVideoControllerProvider(widget.roomKey),
        (prev, next) {
      if (!next.hasActiveVideo) {
        unawaited(_controller?.close());
        _controller = null;
        _loadedVideoId = null;
        _lastPlaying = null;
        if (mounted) setState(() {});
        return;
      }
      unawaited(_syncPlayback(next));
    });

    final videoId = video.videoId!;
    if (_loadedVideoId != videoId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_ensureController(videoId).then((_) => _syncPlayback(video)));
      });
    } else if (_lastPlaying != video.isPlaying ||
        (video.resolvedPositionMs() - _lastSeekMs).abs() > 2500) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_syncPlayback(video));
      });
    }

    final ctrl = _controller;
    if (ctrl == null) {
      return _loadingPlaceholder(video);
    }

    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: 16 / 9 * MediaQuery.sizeOf(context).height,
                  height: MediaQuery.sizeOf(context).height,
                  child: YoutubePlayer(
                    controller: ctrl,
                    aspectRatio: 16 / 9,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingPlaceholder(RoomVideoState video) {
    final thumb = video.thumbUrl?.trim();
    return ColoredBox(
      color: Colors.black,
      child: thumb != null && thumb.isNotEmpty
          ? Image.network(
              thumb,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
    );
  }
}
