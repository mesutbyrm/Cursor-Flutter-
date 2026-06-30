import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/services/voice_room_dj_player.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import '../../../video/presentation/room_video_controller.dart';
import 'voice_room_youtube_embed_host.dart';

/// Koltuk altı video şeridi + ses modunda görünmez embed oynatıcı.
class VoiceRoomSeatVideoStrip extends ConsumerWidget {
  const VoiceRoomSeatVideoStrip({
    super.key,
    required this.roomKey,
  });

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(roomVideoControllerProvider(roomKey));
    final player = ref.watch(voiceRoomDjPlayerProvider);

    return ValueListenableBuilder<VoiceRoomEmbedUiState>(
      valueListenable: player.embedUi,
      builder: (context, ui, _) {
        final hasTrack = ui.videoId?.trim().isNotEmpty == true;
        if (!hasTrack && !video.hasActiveVideo) {
          return const SizedBox.shrink();
        }

        if (video.hasActiveVideo && ui.showVideo) {
          final width = MediaQuery.sizeOf(context).width;
          final height = (width * 9 / 16).clamp(52.0, 96.0);
          return SizedBox(
            width: width,
            height: height,
            child: ClipRect(
              child: VoiceRoomYoutubeEmbedHost(
                roomKey: roomKey,
                compact: true,
              ),
            ),
          );
        }

        return VoiceRoomYoutubeEmbedHost(
          roomKey: roomKey,
          compact: false,
        );
      },
    );
  }
}
