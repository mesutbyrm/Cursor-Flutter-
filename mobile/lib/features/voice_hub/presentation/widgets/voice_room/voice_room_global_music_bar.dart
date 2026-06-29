import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../../video/presentation/room_video_controller.dart';
import 'voice_room_web_music_bar.dart';

/// Odadan çıkınca arka planda devam eden müzik şeridi.
class VoiceRoomGlobalMusicBar extends ConsumerWidget {
  const VoiceRoomGlobalMusicBar({super.key, required this.routePath});

  final String routePath;

  static bool shouldShowForRoute(String location) {
    var path = Uri.tryParse(location)?.path ?? location;
    if (!path.startsWith('/')) path = '/$path';
    if (path == '/voice-room' || path.startsWith('/voice-room/')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(voiceRoomRtcForegroundProvider)) {
      return const SizedBox.shrink();
    }
    if (!shouldShowForRoute(routePath)) {
      return const SizedBox.shrink();
    }
    final session = ref.watch(voiceRoomMusicSessionProvider);
    if (session.room == null || !session.hasActiveMusic) {
      return const SizedBox.shrink();
    }
    final room = session.room!;
    final videoActive =
        ref.watch(roomVideoControllerProvider(room.liveKey)).hasActiveVideo;
    if (videoActive) {
      return const SizedBox.shrink();
    }

    final liveKey = room.liveKey;
    final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
    final ui = ref.watch(voiceRoomUiProvider);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () {
            final slug = room.slug.trim();
            if (slug.isNotEmpty) {
              context.push('/voice-room/$slug');
            } else if (room.apiRoomKey.isNotEmpty) {
              context.push('/voice-room/${room.apiRoomKey}');
            }
          },
          child: VoiceRoomWebMusicBar(
            dj: session.dj,
            musicMuted: !ui.backgroundMusicEnabled,
            canControlMusic: session.canSyncServer,
            onPlayPause: () async {
              final dj = session.dj;
              if (dj.playing) {
                await ctrl.pauseMusic();
              } else {
                await ctrl.resumeMusic();
              }
            },
            onStop: session.canStopMusic
                ? () async {
                    await ctrl.closeMusicPlayer();
                  }
                : null,
            onMuteToggle: () {
              ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic();
            },
            onClose: () async {
              await ctrl.closeMusicPlayer();
            },
          ),
        ),
      ),
    );
  }
}
