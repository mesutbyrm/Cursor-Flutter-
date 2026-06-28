import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../providers/chat_room_providers.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../voice_room/voice_room_music_request_flash.dart';
import '../voice_room/voice_room_premium_music_card.dart';

/// Koltukların hemen altında tam genişlik — !istek / SSE müzik kartı.
class VoiceRoomCenterMusicPanel extends ConsumerWidget {
  const VoiceRoomCenterMusicPanel({
    super.key,
    required this.room,
    required this.live,
    required this.canControlMusic,
    required this.canCloseMusic,
    this.musicRequestFlash,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final bool canControlMusic;
  final bool canCloseMusic;
  final String? musicRequestFlash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = live.dj;
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final sessionKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;

    final hasTrack =
        dj.playing || dj.nowPlaying != null || dj.musicQueue.isNotEmpty;
    final showPlayer = hasTrack &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;
    final flash = musicRequestFlash ?? live.musicRequestFlash;

    if (!showPlayer && (flash == null || flash.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (flash != null && flash.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: VoiceRoomMusicRequestFlash(message: flash),
          ),
        if (showPlayer)
          VoiceRoomPremiumMusicCard(
            room: room,
            liveKey: sessionKey,
            dj: dj,
            canClose: canCloseMusic,
            listenerCount: live.onlineCountFor(room),
            likeCount: live.musicLikeCount,
            onQueueTap: () => showRoomMusicQueueSheet(
              context,
              ref,
              liveKey: sessionKey,
              dj: dj,
              canControlMusic: canControlMusic,
            ),
          ),
      ],
    );
  }
}
