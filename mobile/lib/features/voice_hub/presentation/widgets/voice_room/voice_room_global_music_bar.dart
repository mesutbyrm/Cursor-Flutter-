import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import 'voice_room_web_music_bar.dart';
class VoiceRoomGlobalMusicBar extends ConsumerWidget {
  const VoiceRoomGlobalMusicBar({super.key, required this.routePath});

  /// MaterialApp.builder Stack'inde GoRouter.of(context) yok — dışarıdan verilir.
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
    final playback = ref.watch(voiceRoomDjPlayerProvider).playback;
    final muted = !ref.watch(voiceRoomUiProvider).backgroundMusicEnabled;

    if (!session.visible || session.room == null) {
      return const SizedBox.shrink();
    }
    final playing =
        session.dj.playing || playback.value.playing || session.dj.nowPlaying != null;
    if (!playing && session.dj.musicQueue.isEmpty) {
      return const SizedBox.shrink();
    }

    final room = session.room!;
    final canSync = session.canSyncServer;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: VoiceRoomWebMusicBar(
          dj: session.dj,
          musicMuted: muted,
          onPlayPause: () {
            final player = ref.read(voiceRoomDjPlayerProvider);
            final isPlaying =
                session.dj.playing || player.playback.value.playing;
            if (canSync) {
              final ctrl =
                  ref.read(voiceRoomLiveProvider(room.stableSessionKey).notifier);
              if (isPlaying) {
                unawaited(ctrl.pauseMusic());
              } else {
                unawaited(ctrl.resumeMusic());
              }
            } else if (isPlaying) {
              unawaited(player.pauseLocal());
            } else {
              unawaited(player.resumeLocal());
            }
          },
          onClose: () => unawaited(
            ref.read(voiceRoomMusicSessionProvider.notifier).closePlayer(),
          ),
          onMuteToggle: () {
            final notifier = ref.read(voiceRoomUiProvider.notifier);
            notifier.toggleBackgroundMusic();
            final enabled = ref.read(voiceRoomUiProvider).backgroundMusicEnabled;
            unawaited(
              ref
                  .read(voiceRoomLiveProvider(room.stableSessionKey).notifier)
                  .toggleBackgroundMusic(enabled),
            );
          },
        ),
      ),
    );
  }
}
