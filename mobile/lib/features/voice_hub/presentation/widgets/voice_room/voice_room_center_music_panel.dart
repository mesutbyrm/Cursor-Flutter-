import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../utils/voice_room_responsive_metrics.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../voice_room/voice_room_music_mini_player.dart';
import '../voice_room/voice_room_music_request_flash.dart';

/// Koltukların hemen altında ortada — !istek / DJ müziği.
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
    final m = VoiceRoomResponsiveMetrics.of(context);
    final dj = live.dj;
    final ui = ref.watch(voiceRoomUiProvider);
    final musicMuted = !ui.backgroundMusicEnabled;
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

    return Padding(
      padding: EdgeInsets.fromLTRB(m.horizontalPad, 4, m.horizontalPad, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flash != null && flash.trim().isNotEmpty)
            VoiceRoomMusicRequestFlash(message: flash),
          if (showPlayer)
            VoiceRoomMusicMiniPlayer(
              dj: dj,
              canControl: canControlMusic,
              canModerate: canControlMusic,
              musicMuted: musicMuted,
              showClose: canCloseMusic,
              onPlayPause: () async {
                final notifier =
                    ref.read(voiceRoomLiveProvider(sessionKey).notifier);
                if (dj.playing) {
                  await notifier.pauseMusic();
                } else {
                  await notifier.resumeMusic();
                }
              },
              onPrevious: () {
                ref.read(voiceRoomDjPlayerProvider).seekToStart();
              },
              onSkip: canControlMusic
                  ? () {
                      ref
                          .read(voiceRoomLiveProvider(sessionKey).notifier)
                          .skipMusic();
                    }
                  : null,
              onStop: canControlMusic
                  ? () {
                      ref
                          .read(voiceRoomLiveProvider(sessionKey).notifier)
                          .stopMusic();
                    }
                  : null,
              onMuteToggle: () => ref
                  .read(voiceRoomUiProvider.notifier)
                  .toggleBackgroundMusic(),
              onClose: canCloseMusic
                  ? () => ref
                      .read(voiceRoomLiveProvider(sessionKey).notifier)
                      .closeMusicPlayer()
                  : null,
              onTap: () => showRoomMusicQueueSheet(
                context,
                ref,
                liveKey: sessionKey,
                dj: dj,
                canControlMusic: canControlMusic,
              ),
            ),
        ],
      ),
    );
  }
}
