import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/config/env.dart';
import '../../audio/voice_room_dj_stream_loader.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';

/// Ses akışı başarısız olunca küçük kare video oynatıcı (YouTube proxy).
class VoiceRoomDjVideoFallback extends ConsumerStatefulWidget {
  const VoiceRoomDjVideoFallback({super.key});

  @override
  ConsumerState<VoiceRoomDjVideoFallback> createState() =>
      _VoiceRoomDjVideoFallbackState();
}

class _VoiceRoomDjVideoFallbackState
    extends ConsumerState<VoiceRoomDjVideoFallback> {
  VideoPlayerController? _controller;
  String? _loadedVideoId;

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _load(String videoId) async {
    if (_loadedVideoId == videoId && _controller != null) return;
    await _controller?.dispose();
    _controller = null;
    _loadedVideoId = videoId;

    final watch = 'https://www.youtube.com/watch?v=$videoId';
    final proxy =
        '${Env.siteOrigin}/api/chat/youtube-audio?url=${Uri.encodeComponent(watch)}';
    final url = VoiceRoomDjStreamLoader.clientPlaybackUrl(proxy);

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(ref.read(voiceRoomUiProvider).backgroundMusicEnabled ? 1 : 0);
      await controller.play();
      if (!mounted || _loadedVideoId != videoId) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _controller = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = ref.watch(voiceRoomDjVideoFallbackProvider);
    if (videoId == null || videoId.isEmpty) {
      if (_controller != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _controller?.dispose();
          if (mounted) {
            setState(() {
              _controller = null;
              _loadedVideoId = null;
            });
          }
        });
      }
      return const SizedBox.shrink();
    }

    ref.listen(voiceRoomDjVideoFallbackProvider, (prev, next) {
      if (next != null && next.isNotEmpty && next != _loadedVideoId) {
        unawaited(_load(next));
      }
      if (next == null || next.isEmpty) {
        unawaited(_controller?.dispose());
        if (mounted) {
          setState(() {
            _controller = null;
            _loadedVideoId = null;
          });
        }
      }
    });

    if (_loadedVideoId != videoId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load(videoId)));
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Positioned(
        right: 12,
        bottom: 120,
        child: _VideoShell(
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Positioned(
      right: 12,
      bottom: 120,
      child: _VideoShell(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () {
                    ref.read(voiceRoomDjVideoFallbackProvider.notifier).state =
                        null;
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoShell extends StatelessWidget {
  const _VideoShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 96, height: 96, child: child),
    );
  }
}
