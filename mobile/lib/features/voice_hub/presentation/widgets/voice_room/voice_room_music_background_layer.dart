import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/room_video_controller.dart';
import '../../../video/presentation/widgets/youtube_video_background.dart';
import 'voice_room_youtube_embed_host.dart';

/// Videolu mod — koltukların altından mesaj alanına kadar çerçevesiz YouTube arka plan.
class VoiceRoomMusicBackgroundLayer extends ConsumerWidget {
  const VoiceRoomMusicBackgroundLayer({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(
      roomVideoControllerProvider(roomKey).select((s) => s.showsVideo),
    );
    if (!video) return const SizedBox.shrink();

    // Tam ekran video + %50 karartma: koltuklar ve sohbet okunur kalır.
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            VoiceRoomYoutubeEmbedHost(roomKey: roomKey, fillBackground: true),
            const ColoredBox(color: Color(0x80000000)),
          ],
        ),
      ),
    );
  }
}

/// Ses modu — gizli 1×1 YouTube oynatıcı (yalnızca ses).
class VoiceRoomHiddenAudioPlayer extends ConsumerWidget {
  const VoiceRoomHiddenAudioPlayer({super.key, required this.roomKey});

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioOnly = ref.watch(
      roomVideoControllerProvider(roomKey).select(
        (s) => s.hasActiveVideo && s.audioOnly,
      ),
    );
    if (!audioOnly) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Opacity(
        opacity: 0.01,
        child: SizedBox(
          width: 1,
          height: 1,
          child: YoutubeVideoBackground(roomKey: roomKey),
        ),
      ),
    );
  }
}
