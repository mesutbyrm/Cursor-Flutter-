import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/live_broadcast_session.dart';
import '../../../domain/entities/live_stream_viewer.dart';
import '../../../domain/pk/live_pk_side_resolver.dart';
import '../../providers/live_pk_ui_providers.dart';
import '../../providers/live_providers.dart';
import '../../providers/live_video_pk_provider.dart';
import '../../../domain/pk/live_pk_broadcast_stage.dart';
import '../../../domain/pk/live_pk_chat_stream.dart';
import '../../../domain/pk/live_pk_outcome_latch.dart';
import '../../../domain/pk/pk_status_helper.dart';
import 'live_pk_reference_top_bar.dart';
import '../live_playback_bridge.dart';
import '../../../../pk/presentation/widgets/pk_battle_visuals.dart';
import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_vs_emblem.dart';
import 'live_pk_immersive_video_pane.dart';
import 'live_pk_resolved_timer.dart';
import 'live_pk_reference_score_bar.dart';
import 'live_pk_reference_chat_overlay.dart';
import 'live_pk_pane_gift_toast.dart';
import 'live_pk_layout_metrics.dart';
import 'live_pk_pane_gifter_strip.dart';
import '../../providers/live_stream_viewers_provider.dart';
import '../../providers/live_host_rank_provider.dart';
import '../../providers/live_pk_ended_lock_provider.dart';
import 'live_pk_pane_outcome_overlay.dart';

/// PK aktifken tam ekran split: sol yerel/yayıncı, sağ rakip + referans overlay.
class LivePkSplitVideoLayer extends ConsumerStatefulWidget {
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
  ConsumerState<LivePkSplitVideoLayer> createState() =>
      _LivePkSplitVideoLayerState();
}

class _LivePkSplitVideoLayerState extends ConsumerState<LivePkSplitVideoLayer>
    with SingleTickerProviderStateMixin {
  final _outcomeLatch = LivePkOutcomeLatch();
  late final AnimationController _outcomeFx;
  var _outcomeFxVisible = false;

  @override
  void initState() {
    super.initState();
    _outcomeFx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _outcomeFx.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _outcomeFxVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _outcomeFx.dispose();
    super.dispose();
  }

  void _onPkEndedTransition(String? battleId) {
    final bid = battleId?.trim() ?? '';
    if (bid.isEmpty) return;
    final lock = ref.read(livePkEndedLockProvider.notifier);
    if (!lock.tryAcquireEndedCelebration(bid)) return;
    setState(() => _outcomeFxVisible = true);
    _outcomeFx.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final streamId = widget.streamId;
    final session = widget.session;
    final trtc = widget.trtc;
    final rtcReady = widget.rtcReady;
    final pk = ref.watch(liveVideoPkProvider(streamId));
    final battle = pk.battle;
    ref.listen(liveVideoPkProvider(streamId), (prev, next) {
      final wasEnded =
          prev != null && isLivePkEndedStatus(prev.status);
      final nowEnded = isLivePkEndedStatus(next.status);
      if (!wasEnded && nowEnded) {
        _onPkEndedTransition(next.battle?['id']?.toString());
      }
    });
    if (battle == null || !isLivePkBroadcastStage(battle, pk.status)) {
      return const ColoredBox(color: Color(0xFF120A1E));
    }
    final ended = isLivePkEndedStatus(pk.status);
    final pkActive = isLivePkActiveStatus(pk.status);

    final authUser = ref.read(authControllerProvider).valueOrNull;
    final myUserId = authUser?.id;
    final layout = resolveLivePkSplitLayout(
      battle: battle,
      myStreamId: streamId,
      myUserId: myUserId ?? session.hostUserId,
      amBroadcaster: session.isHost,
    );

    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
    final interaction = ref.watch(liveRoomInteractionProvider(streamId));
    final viewers = ref.watch(liveStreamViewersProvider(streamId)).valueOrNull ??
        const [];
    final streams = ref.watch(liveStreamsProvider).valueOrNull ?? const [];
    final battleMap = Map<String, dynamic>.from(battle);
    final chatStreamId = livePkEffectiveChatStreamId(
      battle: battleMap,
      myStreamId: streamId,
    );
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
        final audioMap = trtc.remoteAudioByUser.value;
        bool remoteCamFor(String? uid) {
          final id = uid?.trim() ?? '';
          if (id.isEmpty) return true;
          return remoteVideoMap[id] ?? true;
        }

        bool remoteMicFor(String? uid) {
          final id = uid?.trim() ?? '';
          if (id.isEmpty) return true;
          return audioMap[id] ?? true;
        }

        return _buildStack(
          context,
          ref,
          streamId: streamId,
          chatStreamId: chatStreamId,
          session: session,
          trtc: trtc,
          rtcReady: rtcReady,
          battleId: battleMap['id']?.toString() ??
              battleMap['battleId']?.toString(),
          layout: layout,
          myUserId: myUserId,
          opponentMuted: opponentMuted,
          leftScore: leftScore,
          rightScore: rightScore,
          secondsLeft: secondsLeft,
          endsAt: endsAt,
          playbackFor: playbackFor,
          leftRemoteCam: remoteCamFor(layout.left.userId),
          leftRemoteMic: remoteMicFor(layout.left.userId),
          rightRemoteCam: remoteCamFor(layout.right.userId),
          rightRemoteMic: remoteMicFor(layout.right.userId),
          ended: ended,
          pkActive: pkActive,
          viewers: viewers,
        );
      },
    );
  }

  Widget _buildStack(
    BuildContext context,
    WidgetRef ref, {
    required String streamId,
    required String chatStreamId,
    required LiveBroadcastSession session,
    required TrtcRoomManager trtc,
    required bool rtcReady,
    required String? battleId,
    required LivePkSplitLayout layout,
    String? myUserId,
    required bool opponentMuted,
    required int leftScore,
    required int rightScore,
    required int secondsLeft,
    required DateTime? endsAt,
    required String? Function(String?) playbackFor,
    required bool leftRemoteCam,
    required bool leftRemoteMic,
    required bool rightRemoteCam,
    required bool rightRemoteMic,
    required bool ended,
    required bool pkActive,
    required List<LiveStreamViewer> viewers,
  }) {
    final leftLeague = _leagueForUser(ref, layout.left.userId);
    final rightLeague = _leagueForUser(ref, layout.right.userId);
    final computedLabel = livePkOutcomeStatusLabel(
      ended: ended,
      localOnLeft: layout.left.isLocalPane,
      leftScore: leftScore,
      rightScore: rightScore,
      leftLabel: layout.left.label,
      rightLabel: layout.right.label,
    );
    _outcomeLatch.resolve(
      currentBattleId: battleId,
      ended: ended,
      computedLabel: computedLabel,
    );
    final pillMode = livePkStatusPillMode(
      ended: ended,
      leftScore: leftScore,
      rightScore: rightScore,
    );
    final winnerName = livePkWinnerName(
      leftScore: leftScore,
      rightScore: rightScore,
      leftLabel: layout.left.label,
      rightLabel: layout.right.label,
    );
    final leftWins = livePkLeftPaneWins(
      leftScore: leftScore,
      rightScore: rightScore,
    );
    return AnimatedBuilder(
      animation: _outcomeFx,
      builder: (context, _) {
        final fxProgress = _outcomeFxVisible ? _outcomeFx.value : 0.0;
        return LayoutBuilder(
      builder: (context, constraints) {
        final chromeBottom = LivePkLayoutMetrics.chromeReserve(context);
        final scoreH = LivePkLayoutMetrics.scoreBandHeight;
        final videoBottom = LivePkLayoutMetrics.videoBottomInset(context);
        final headerH = LivePkLayoutMetrics.headerHeight(context);
        final chipTop = LivePkLayoutMetrics.streamerChipTop(context);

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: videoBottom,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              LivePkImmersiveVideoPane(
                            isLocal: layout.left.isLocalPane,
                            displayName: layout.left.label,
                            avatarUrl: layout.left.avatarUrl,
                            streamerUserId: layout.left.userId,
                            showFollowOnChip: _showPkFollow(
                              layout.left,
                              myUserId: myUserId,
                            ),
                            leagueLabel: leftLeague,
                            followAccent: const Color(0xFFFF2D7A),
                            chipTopInset: chipTop,
                            footerOverlay: LivePkPaneGifterStrip(
                              sessionKey: streamId,
                              hostLabel: layout.left.label,
                              hostUserId: layout.left.userId,
                              alignLeft: true,
                            ),
                            micOn: layout.left.isLocalPane
                                ? trtc.micOn
                                : leftRemoteMic,
                            cameraOn: layout.left.isLocalPane
                                ? trtc.cameraOn
                                : leftRemoteCam,
                            chipAlignment: Alignment.topLeft,
                            video: _PkPane(
                              pane: layout.left,
                              trtc: trtc,
                              rtcReady: rtcReady,
                              playbackUrl: layout.left.isLocalPane
                                  ? null
                                  : playbackFor(layout.left.streamId),
                              preferRemoteUserId: layout.left.userId,
                              accent: Colors.pinkAccent,
                              playbackAudible: true,
                              bare: true,
                            ),
                          ),
                              LivePkPaneGiftToast(
                                hostUserId: layout.left.userId,
                                hostLabel: layout.left.label,
                              ),
                              LivePkPaneOutcomeOverlay(
                                visible: _outcomeFxVisible && ended,
                                winnerPane: leftWins,
                                progress: fxProgress,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: LivePkLayoutMetrics.splitDividerWidth,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              LivePkImmersiveVideoPane(
                            isLocal: layout.right.isLocalPane,
                            displayName: layout.right.label,
                            avatarUrl: layout.right.avatarUrl,
                            streamerUserId: layout.right.userId,
                            showFollowOnChip: _showPkFollow(
                              layout.right,
                              myUserId: myUserId,
                            ),
                            leagueLabel: rightLeague,
                            followAccent: const Color(0xFF448AFF),
                            chipTopInset: chipTop,
                            localMediaCorner: layout.right.isLocalPane
                                ? _PkLocalMediaStatus(
                                    micOn: trtc.micOn,
                                    cameraOn: trtc.cameraOn,
                                  )
                                : null,
                            footerOverlay: LivePkPaneGifterStrip(
                              sessionKey: streamId,
                              hostLabel: layout.right.label,
                              hostUserId: layout.right.userId,
                              alignLeft: false,
                            ),
                            micOn: layout.right.isLocalPane
                                ? trtc.micOn
                                : rightRemoteMic,
                            cameraOn: layout.right.isLocalPane
                                ? trtc.cameraOn
                                : rightRemoteCam,
                            chipAlignment: Alignment.topLeft,
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
                              LivePkPaneGiftToast(
                                hostUserId: layout.right.userId,
                                hostLabel: layout.right.label,
                              ),
                              LivePkPaneOutcomeOverlay(
                                visible: _outcomeFxVisible && ended,
                                winnerPane: !leftWins && leftScore != rightScore,
                                progress: fxProgress,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: PkVsEmblem(
                        size: LivePkLayoutMetrics.vsEmblemSize,
                        pulse: true,
                      ),
                    ),
                    Positioned(
                      top: headerH + 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            child: ended
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded,
                                          color: Color(0xFFFFD54F), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'PK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      PkBattleTimerBadge(
                                        secondsLeft: 0,
                                        flashThreshold: 10,
                                      ),
                                    ],
                                  )
                                : LivePkResolvedTimer(
                                    remote: null,
                                    fallbackSeconds: secondsLeft,
                                    endsAt: endsAt,
                                    countdownActive: true,
                                    centered: true,
                                    onExpired:
                                        session.isHost ? widget.onEndPk : null,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: chromeBottom,
                height: scoreH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.92),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Center(
                    child: LivePkReferenceScoreBar(
                      leftScore: leftScore,
                      rightScore: rightScore,
                      pillMode: pillMode,
                      winnerName: winnerName,
                      active: pkActive,
                      showEndedScores: ended,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: LivePkLayoutMetrics.chatOverlayLeftPadding,
                bottom: chromeBottom + scoreH + 6,
                width: MediaQuery.sizeOf(context).width *
                    LivePkLayoutMetrics.chatOverlayWidthFactor,
                height: LivePkLayoutMetrics.chatOverlayHeight,
                child: LivePkReferenceChatOverlay(
                  streamId: chatStreamId,
                  visible: widget.chatVisible,
                ),
              ),
              LivePkReferenceTopBar(
                onBack: widget.onBack,
                onClose: widget.onBack,
                viewerCount: widget.viewerCount,
                viewers: viewers,
              ),
            ],
          ),
        );
      },
        );
      },
    );
  }

  static String? _leagueForUser(WidgetRef ref, String? userId) {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return null;
    return ref.watch(liveHostRankProvider(id)).valueOrNull?.leagueLabel;
  }

  static bool _showPkFollow(
    LivePkPaneModel pane, {
    String? myUserId,
  }) {
    if (pane.isLocalPane) return false;
    final uid = pane.userId?.trim() ?? '';
    if (uid.isEmpty) return false;
    final me = myUserId?.trim() ?? '';
    if (me.isNotEmpty && me == uid) return false;
    return true;
  }
}

class _PkLocalMediaStatus extends StatelessWidget {
  const _PkLocalMediaStatus({
    required this.micOn,
    required this.cameraOn,
  });

  final bool micOn;
  final bool cameraOn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Icon(
              cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
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
        final remoteId = preferRemoteUserId?.trim() ??
            pane.userId?.trim() ??
            '';
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
