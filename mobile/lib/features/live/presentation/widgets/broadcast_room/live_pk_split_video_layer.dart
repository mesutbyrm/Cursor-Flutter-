import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/pk/live_pk_side_resolver.dart';
import '../../providers/live_pk_ui_providers.dart';
import '../../providers/live_providers.dart';
import '../../providers/live_video_pk_provider.dart';
import '../../../domain/pk/live_pk_broadcast_stage.dart';
import '../../../domain/pk/pk_status_helper.dart';
import 'live_pk_reference_top_bar.dart';
import '../live_playback_bridge.dart';
import '../../../../pk/presentation/widgets/pk_battle_visuals.dart';
import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_vs_emblem.dart';
import 'live_pk_immersive_video_pane.dart';
import 'live_pk_resolved_timer.dart';
import 'live_pk_reference_score_bar.dart';
import 'live_pk_reference_chat_overlay.dart';
import 'live_pk_gift_toast_overlay.dart';

/// PK aktifken tam ekran split: sol yerel/yayıncı, sağ rakip + referans overlay.
class LivePkSplitVideoLayer extends ConsumerWidget {
  const LivePkSplitVideoLayer({
    super.key,
    required this.streamId,
    required this.session,
    required this.trtc,
    required this.rtcReady,
    this.onEndPk,
    this.onMuteOpponent,
    this.chatVisible = true,
    this.onBack,
    this.viewerCount = 0,
  });

  final String streamId;
  final LiveBroadcastSession session;
  final TrtcRoomManager trtc;
  final bool rtcReady;
  final VoidCallback? onEndPk;
  final void Function(String opponentUserId, bool mute)? onMuteOpponent;
  final bool chatVisible;
  final VoidCallback? onBack;
  final int viewerCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle;
    if (battle == null || !isLivePkBroadcastStage(battle, pk.status)) {
      return const ColoredBox(color: Color(0xFF120A1E));
    }
    final ended = isLivePkEndedStatus(pk.status);
    final pkActive = isLivePkActiveStatus(pk.status);

    final myUserId = ref.read(authControllerProvider).valueOrNull?.id;
    final layout = resolveLivePkSplitLayout(
      battle: battle,
      myStreamId: streamId,
      myUserId: myUserId ?? session.hostUserId,
      amBroadcaster: session.isHost,
    );

    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final streams = ref.watch(liveStreamsProvider).valueOrNull ?? const [];
    final battleMap = Map<String, dynamic>.from(battle);
    final leftScore = pkScoreFromBattleMap(battleMap, left: true);
    final rightScore = pkScoreFromBattleMap(battleMap, left: false);
    final secondsLeft = pkBattleSecondsLeftFromMap(battleMap);
    final endsAtRaw = battleMap['endsAt']?.toString();
    final endsAt = endsAtRaw != null && endsAtRaw.isNotEmpty
        ? DateTime.tryParse(endsAtRaw)
        : null;

    String? playbackFor(String? targetStreamId) {
      final id = targetStreamId?.trim() ?? '';
      if (id.isEmpty) return null;
      for (final s in streams) {
        if (s.id == id) return s.playbackUrl;
      }
      return null;
    }

    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: trtc.remoteVideoByUser,
      builder: (context, remoteVideoMap, _) {
        final oppId = layout.right.userId?.trim() ?? '';
        final remoteCam =
            oppId.isEmpty ? true : (remoteVideoMap[oppId] ?? true);
        final remoteMic = oppId.isEmpty
            ? true
            : (trtc.remoteAudioByUser.value[oppId] ?? true);

        return _buildStack(
          context,
          ref,
          layout: layout,
          opponentMuted: opponentMuted,
          leftScore: leftScore,
          rightScore: rightScore,
          secondsLeft: secondsLeft,
          endsAt: endsAt,
          playbackFor: playbackFor,
          remoteCam: remoteCam,
          remoteMic: remoteMic,
          ended: ended,
          pkActive: pkActive,
        );
      },
    );
  }

  Widget _buildStack(
    BuildContext context,
    WidgetRef ref, {
    required LivePkSplitLayout layout,
    required bool opponentMuted,
    required int leftScore,
    required int rightScore,
    required int secondsLeft,
    required DateTime? endsAt,
    required String? Function(String?) playbackFor,
    required bool remoteCam,
    required bool remoteMic,
    required bool ended,
    required bool pkActive,
  }) {
    final statusLabel = livePkOutcomeStatusLabel(
      ended: ended,
      localOnLeft: layout.left.isLocalPane,
      leftScore: leftScore,
      rightScore: rightScore,
      leftLabel: layout.left.label,
      rightLabel: layout.right.label,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final videoH = (h * 0.52).clamp(240.0, h * 0.55);

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: videoH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LivePkImmersiveVideoPane(
                            isLocal: layout.left.isLocalPane,
                            displayName: layout.left.label,
                            avatarUrl: layout.left.avatarUrl,
                            micOn: layout.left.isLocalPane ? trtc.micOn : remoteMic,
                            cameraOn:
                                layout.left.isLocalPane ? trtc.cameraOn : remoteCam,
                            chipAlignment: Alignment.topLeft,
                            video: _PkPane(
                              pane: layout.left,
                              trtc: trtc,
                              rtcReady: rtcReady,
                              playbackUrl: layout.left.isLocalPane
                                  ? null
                                  : playbackFor(layout.left.streamId),
                              accent: Colors.pinkAccent,
                              playbackAudible: true,
                              bare: true,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LivePkImmersiveVideoPane(
                            displayName: layout.right.label,
                            avatarUrl: layout.right.avatarUrl,
                            micOn: remoteMic,
                            cameraOn: remoteCam,
                            chipAlignment: Alignment.topRight,
                            video: _PkPane(
                              pane: layout.right,
                              trtc: trtc,
                              rtcReady: rtcReady,
                              playbackUrl: playbackFor(layout.right.streamId),
                              accent: Colors.cyanAccent,
                              preferRemoteUserId: layout.right.userId,
                              playbackAudible: !opponentMuted,
                              bare: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: PkVsEmblem(size: 48, pulse: true),
                    ),
                    if (session.isHost)
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (layout.right.userId != null &&
                                layout.right.userId!.isNotEmpty)
                              Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  tooltip: opponentMuted
                                      ? 'Sesi aç'
                                      : 'Rakibi sessize al',
                                  icon: Icon(
                                    opponentMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    final oppId = layout.right.userId!.trim();
                                    final next = !opponentMuted;
                                    ref
                                        .read(
                                          livePkOpponentMutedProvider(streamId)
                                              .notifier,
                                        )
                                        .state = next;
                                    onMuteOpponent?.call(oppId, next);
                                    trtc.muteRemoteAudio(oppId, next);
                                  },
                                ),
                              ),
                            const SizedBox(width: 4),
                            Material(
                              color: Colors.red.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                tooltip: 'PK bitir',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: onEndPk,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: videoH - 6,
                child: LivePkReferenceScoreBar(
                  leftScore: leftScore,
                  rightScore: rightScore,
                  leftLabel: layout.left.label,
                  rightLabel: layout.right.label,
                  statusLabel: statusLabel,
                  active: pkActive,
                  showEndedScores: ended,
                ),
              ),
              LivePkReferenceChatOverlay(
                streamId: streamId,
                maxHeight: (h - videoH - 72).clamp(72, 200),
                visible: chatVisible,
              ),
              const LivePkGiftToastOverlay(),
              LivePkReferenceTopBar(
                onBack: onBack,
                viewerCount: viewerCount,
                timer: ended
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: Color(0xFFFFD54F), size: 18),
                          SizedBox(width: 4),
                          Text(
                            'PK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 8),
                          PkBattleTimerBadge(secondsLeft: 0, flashThreshold: 10),
                        ],
                      )
                    : LivePkResolvedTimer(
                        remote: null,
                        fallbackSeconds: secondsLeft,
                        endsAt: endsAt,
                        countdownActive: true,
                        centered: true,
                        onExpired: session.isHost ? onEndPk : null,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PkPane extends StatelessWidget {
  const _PkPane({
    required this.pane,
    required this.trtc,
    required this.rtcReady,
    required this.accent,
    this.playbackUrl,
    this.preferRemoteUserId,
    this.playbackAudible = false,
    this.bare = false,
  });

  final LivePkPaneModel pane;
  final TrtcRoomManager trtc;
  final bool rtcReady;
  final Color accent;
  final String? playbackUrl;
  final String? preferRemoteUserId;
  final bool playbackAudible;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: trtc.remoteUserIdsNotifier,
      builder: (context, remoteIds, _) {
        Widget video;
        final remoteId = preferRemoteUserId?.trim() ?? '';
        if (pane.isLocalPane && rtcReady) {
          video = TrtcLocalVideoView(manager: trtc);
        } else if (remoteId.isNotEmpty &&
            rtcReady &&
            remoteIds.contains(remoteId)) {
          video = TrtcRemoteVideoView(manager: trtc, userId: remoteId);
        } else if (playbackUrl != null && playbackUrl!.trim().isNotEmpty) {
          video = LivePlaybackBridge(
            playbackUrl: playbackUrl,
            thumbnailUrl: pane.avatarUrl,
            audible: playbackAudible,
          );
        } else if (pane.avatarUrl != null && pane.avatarUrl!.trim().isNotEmpty) {
          video = CanlifalNetworkImage(
            url: pane.avatarUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          video = Center(
            child: Icon(Icons.videocam_rounded, size: 44, color: accent),
          );
        }

        if (bare) return video;
        return ColoredBox(
          color: const Color(0xFF120A1E),
          child: video,
        );
      },
    );
  }
}
