import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../pages/voice_music_hub_page.dart';
import '../../providers/chat_room_providers.dart';
import '../../sheets/voice_room_dj_sheet.dart';
import '../../utils/voice_room_permissions.dart';
import '../../utils/voice_room_responsive_metrics.dart';
import 'voice_room_action_row.dart';
import 'voice_room_music_queue_section.dart';
import 'voice_room_web_music_bar.dart';
import 'voice_staff_entrance_marquee.dart';

/// Müzik / DJ / kuyruk — mesaj kutusunun hemen üstünde sabit blok.
class VoiceRoomBottomDock extends ConsumerWidget {
  const VoiceRoomBottomDock({
    super.key,
    required this.room,
    required this.session,
    required this.live,
    required this.perms,
    required this.isOwner,
    required this.showDjControls,
    required this.showMusicCard,
    required this.canControlMusic,
    required this.musicMuted,
    required this.pkActive,
    required this.staffBanner,
    required this.onPkTap,
    required this.onMuteToggle,
  });

  final VoiceRoomEntity room;
  final VoiceRoomEntity session;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final bool showDjControls;
  final bool showMusicCard;
  final bool canControlMusic;
  final bool musicMuted;
  final bool pkActive;
  final String? staffBanner;
  final VoidCallback onPkTap;
  final VoidCallback onMuteToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = VoiceRoomResponsiveMetrics.of(context);
    final musicDismissed = ref.watch(voiceRoomMusicSessionProvider).dismissed;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDjControls)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: m.horizontalPad),
                child: VoiceRoomActionRow(
                  dj: live.dj,
                  showMusicCard: showMusicCard,
                  showDjCard: showDjControls,
                  showPkCard: isOwner,
                  pkActive: pkActive,
                  onMusicTap: () => showVoiceMusicHubPage(
                    context,
                    ref,
                    room: room,
                    perms: perms,
                    isOwner: isOwner,
                  ),
                  onDjTap: () => showVoiceRoomDjSheet(
                    context,
                    ref,
                    room: room,
                    live: live,
                    perms: perms,
                    isOwner: isOwner,
                  ),
                  onPkTap: onPkTap,
                ),
              ),
            if (!musicDismissed)
              VoiceRoomWebMusicBar(
              dj: live.dj,
              showDebug: kDebugMode,
              onPlayPause: () {
                final ctrl =
                    ref.read(voiceRoomLiveProvider(session).notifier);
                final player = ref.read(voiceRoomDjPlayerProvider);
                final playing = live.dj.playing ||
                    player.playback.value.playing;
                if (canControlMusic) {
                  if (playing) {
                    unawaited(ctrl.pauseMusic());
                  } else {
                    unawaited(ctrl.resumeMusic());
                  }
                } else if (playing) {
                  unawaited(player.pauseLocal());
                } else {
                  unawaited(player.resumeLocal());
                }
              },
              onClose: () => unawaited(
                ref
                    .read(voiceRoomLiveProvider(session).notifier)
                    .closeMusicPlayer(),
              ),
              musicMuted: musicMuted,
              onMuteToggle: onMuteToggle,
            ),
            VoiceStaffEntranceMarquee(
              message: staffBanner,
              roomName: room.nameTr,
            ),
            if (!live.dj.playing && live.dj.nowPlaying == null)
              VoiceRoomMusicQueueSection(
                dj: live.dj,
                coinCost: live.dj.musicRequestCost,
                maxItems: 3,
              ),
          ],
        ),
      ),
    );
  }
}
