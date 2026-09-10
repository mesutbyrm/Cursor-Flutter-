import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/navigate_to_voice_room.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
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
    final liveKey = room.liveKey;
    final ui = ref.watch(voiceRoomUiProvider);
    final player = ref.read(voiceRoomDjPlayerProvider);
    final sessionNotifier = ref.read(voiceRoomMusicSessionProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => navigateToVoiceRoom(
            context,
            ref,
            room: room,
            source: 'music_bar',
          ),
          child: VoiceRoomWebMusicBar(
            dj: session.dj,
            roomLiveKey: liveKey,
            detachedMiniPlayer: true,
            isVideoMode: false,
            musicMuted: !ui.backgroundMusicEnabled,
            canControlMusic: session.canSyncServer,
            onPlayPause: () async {
              final wasPlaying = player.playback.value.playing;
              if (wasPlaying) {
                await player.pauseLocal();
              } else {
                await player.resumeLocal();
              }
              if (session.canSyncServer && liveKey.isNotEmpty) {
                final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
                if (wasPlaying) {
                  await ctrl.pauseMusic();
                } else {
                  await ctrl.resumeMusic();
                }
              }
            },
            onStop: () async {
              await sessionNotifier.closePlayer();
            },
            onMuteToggle: () {
              ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic();
            },
            onClose: () async {
              await sessionNotifier.closePlayer();
            },
          ),
        ),
      ),
    );
  }
}
