import 'dart:async';

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
import '../../../domain/pk/live_pk_authoritative_outcome.dart';
import '../../../domain/pk/live_pk_outcome_latch.dart';
import '../../pages/live_session_phase.dart';
import 'live_pk_reconnect_banner.dart';
import '../../../domain/pk/pk_status_helper.dart';
import 'live_pk_reference_top_bar.dart';
import 'live_pk_reference_battle_bar.dart';
import '../live_playback_bridge.dart';
import '../../../../pk/presentation/providers/pk_providers.dart';
import '../../../../pk/presentation/widgets/pk_battle_visuals.dart';
import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_vs_emblem.dart';
import 'live_pk_immersive_video_pane.dart';
import 'live_pk_resolved_timer.dart';
import 'live_pk_reference_chat_overlay.dart';
import 'live_pk_pane_gift_toast.dart';
import 'live_pk_layout_metrics.dart';
import 'live_pk_pane_profile_footer.dart';
import '../../providers/live_stream_viewers_provider.dart';
import '../../providers/live_pk_ended_lock_provider.dart';
import 'live_pk_pane_outcome_overlay.dart';
import 'live_pk_preparing_overlay.dart';
import 'live_pk_final_countdown_overlay.dart';
import 'live_pk_result_flash_overlay.dart';
import 'live_pk_score_pop_overlay.dart';
import 'live_pk_top_supporters_panel.dart';
import '../../providers/live_pk_score_burst_provider.dart';

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
    this.sessionPhase = LiveSessionPhase.live,
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
  final LiveSessionPhase sessionPhase;

  @override
  ConsumerState<LivePkSplitVideoLayer> createState() =>
      _LivePkSplitVideoLayerState();
}

class _LivePkSplitVideoLayerState extends ConsumerState<LivePkSplitVideoLayer>
    with SingleTickerProviderStateMixin {
  final _outcomeLatch = LivePkOutcomeLatch();
  late final AnimationController _outcomeFx;
  var _outcomeFxVisible = false;
  var _resultFlashVisible = false;
  Timer? _uiClock;

  @override
  void initState() {
    super.initState();
    _uiClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
    _uiClock?.cancel();
    _outcomeFx.dispose();
    super.dispose();
  }

  void _onPkEndedTransition(String? battleId) {
    final bid = battleId?.trim() ?? '';
    if (bid.isEmpty) return;
    final lock = ref.read(livePkEndedLockProvider.notifier);
    if (!lock.tryAcquireEndedCelebration(bid)) return;
    setState(() {
      _outcomeFxVisible = true;
      _resultFlashVisible = true;
    });
    _outcomeFx.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _resultFlashVisible = false);
    });
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      ref
          .read(liveVideoPkProvider(widget.streamId).notifier)
          .dismissEndedOverlay(expectedBattleId: bid);
    });
  }

  int _resolveDisplaySeconds(DateTime? endsAt, int fallback) {
    if (endsAt != null) {
      return endsAt.difference(DateTime.now()).inSeconds.clamp(0, 86400);
    }
    return fallback;
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
    final pkStarting = isLivePkStartingStatus(pk.status);

    final authUser = ref.read(authControllerProvider).valueOrNull;
    final myUserId = authUser?.id;
    final layout = resolveLivePkSplitLayout(
      battle: battle,
      myStreamId: streamId,
      myUserId: myUserId ?? session.hostUserId,
      amBroadcaster: session.isHost,
    );

    final opponentMuted = ref.watch(livePkOpponentMutedProvider(streamId));
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
    ref.read(livePkScoreBurstProvider(streamId).notifier).observeScores(
          left: leftScore,
          right: rightScore,
        );
    final burst = ref.watch(livePkScoreBurstProvider(streamId));
    final secondsLeft = pkBattleSecondsLeftFromMap(battleMap);
    final endsAtRaw = battleMap['endsAt']?.toString();
    final skew = ref.read(pkServiceProvider).clockSkew;
    DateTime? endsAt;
    if (endsAtRaw != null && endsAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(endsAtRaw);
      if (parsed != null) {
        endsAt = parsed.add(skew);
      }
    }
    final opponentUserId = layout.left.isLocalPane
        ? layout.right.userId
        : layout.left.userId;

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
          battleMap: battleMap,
          layout: layout,
          myUserId: myUserId,
          opponentMuted: opponentMuted,
          opponentUserId: opponentUserId,
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
          pkStarting: pkStarting,
          burst: burst,
          viewers: viewers,
          sessionPhase: widget.sessionPhase,
        );
      },
    );
  }

  bool _remotePlaybackAudible({
    required LivePkPaneModel pane,
    required String? opponentUserId,
    required bool opponentMuted,
  }) {
    if (pane.isLocalPane) return true;
    final opp = opponentUserId?.trim() ?? '';
    final uid = pane.userId?.trim() ?? '';
    if (opp.isNotEmpty && uid.isNotEmpty && uid == opp) {
      return !opponentMuted;
    }
    return true;
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
    required Map<String, dynamic> battleMap,
    required LivePkSplitLayout layout,
    String? myUserId,
    required bool opponentMuted,
    required String? opponentUserId,
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
    required bool pkStarting,
    required LivePkScoreBurstState burst,
    required List<LiveStreamViewer> viewers,
    required LiveSessionPhase sessionPhase,
  }) {
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
    final leftWins = livePkLeftPaneWins(
      leftScore: leftScore,
      rightScore: rightScore,
    );
    final displaySec = _resolveDisplaySeconds(endsAt, secondsLeft);
    final localOnLeft = layout.left.isLocalPane;
    final myScore = localOnLeft ? leftScore : rightScore;
    final oppScore = localOnLeft ? rightScore : leftScore;
    final outcome = resolveLivePkAuthoritativeOutcome(
      battle: battleMap,
      ended: ended,
      myUserId: myUserId,
      localOnLeft: localOnLeft,
      leftScore: leftScore,
      rightScore: rightScore,
    );
    final isDraw = outcome.isDraw;
    final iWon = outcome.localWon;
    return AnimatedBuilder(
      animation: _outcomeFx,
      builder: (context, _) {
        final fxProgress = _outcomeFxVisible ? _outcomeFx.value : 0.0;
        return LayoutBuilder(
      builder: (context, constraints) {
        final headerH = LivePkLayoutMetrics.headerHeight(context);
        final chipTop = LivePkLayoutMetrics.streamerChipTop(context);
        final divider = LivePkLayoutMetrics.splitDividerWidth;
        final paneWidth =
            (constraints.maxWidth - divider).clamp(0.0, constraints.maxWidth) / 2;
        // Referans düzen: başlığın hemen altında yayıncı bandı
        // [sol kart | PK sayacı | sağ kart]. Video bunun altından başlar.
        const bandHeight = 62.0;
        final videoTop = headerH + bandHeight;
        // Video, band ile alt şerit (skor barı + kontroller + giriş) arasındaki
        // tüm dikey alanı doldurur — referans tasarımdaki uzun dikey paneller.
        // Önceki davranış panelleri kare (paneWidth) yapıyordu; bu, ekranın alt
        // yarısını boş siyah bırakıyordu.
        final availableVideoHeight =
            (constraints.maxHeight -
                    videoTop -
                    LivePkLayoutMetrics.videoBottomInset(context))
                .clamp(0.0, constraints.maxHeight)
                .toDouble();
        final videoHeight =
            availableVideoHeight < paneWidth ? paneWidth : availableVideoHeight;
        final scoreBarTop = videoTop + videoHeight;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: videoTop,
                left: 0,
                right: 0,
                height: videoHeight,
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
                            chipTopInset: chipTop,
                            profileFooter: LivePkPaneProfileFooter(
                              displayName: layout.left.label,
                              avatarUrl: layout.left.avatarUrl,
                              userId: layout.left.userId,
                              pkScore: leftScore,
                              isLocal: layout.left.isLocalPane,
                              showFollow: _showPkFollow(
                                layout.left,
                                myUserId: myUserId,
                              ),
                              followAccent: const Color(0xFFFF2D7A),
                            ),
                            micOn: layout.left.isLocalPane
                                ? trtc.micOn
                                : leftRemoteMic,
                            cameraOn: layout.left.isLocalPane
                                ? trtc.cameraOn
                                : leftRemoteCam,
                            video: _PkPane(
                              pane: layout.left,
                              trtc: trtc,
                              rtcReady: rtcReady,
                              playbackUrl: layout.left.isLocalPane
                                  ? null
                                  : playbackFor(layout.left.streamId),
                              preferRemoteUserId: layout.left.userId,
                              accent: Colors.pinkAccent,
                              playbackAudible: _remotePlaybackAudible(
                                pane: layout.left,
                                opponentUserId: opponentUserId,
                                opponentMuted: opponentMuted,
                              ),
                              bare: true,
                            ),
                          ),
                              LivePkPaneGiftToast(
                                sessionKey: streamId,
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
                            chipTopInset: chipTop,
                            localMediaCorner: layout.right.isLocalPane
                                ? _PkLocalMediaStatus(
                                    micOn: trtc.micOn,
                                    cameraOn: trtc.cameraOn,
                                  )
                                : null,
                            profileFooter: LivePkPaneProfileFooter(
                              displayName: layout.right.label,
                              avatarUrl: layout.right.avatarUrl,
                              userId: layout.right.userId,
                              pkScore: rightScore,
                              isLocal: layout.right.isLocalPane,
                              showFollow: _showPkFollow(
                                layout.right,
                                myUserId: myUserId,
                              ),
                              followAccent: const Color(0xFF448AFF),
                            ),
                            micOn: layout.right.isLocalPane
                                ? trtc.micOn
                                : rightRemoteMic,
                            cameraOn: layout.right.isLocalPane
                                ? trtc.cameraOn
                                : rightRemoteCam,
                            video: _PkPane(
                              pane: layout.right,
                              trtc: trtc,
                              rtcReady: rtcReady,
                              playbackUrl: playbackFor(layout.right.streamId),
                              accent: Colors.cyanAccent,
                              preferRemoteUserId: layout.right.userId,
                              playbackAudible: _remotePlaybackAudible(
                                pane: layout.right,
                                opponentUserId: opponentUserId,
                                opponentMuted: opponentMuted,
                              ),
                              bare: true,
                            ),
                          ),
                              LivePkPaneGiftToast(
                                sessionKey: streamId,
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
                  ],
                ),
              ),
              // Referans yayıncı bandı: [sol kart | PK sayacı | sağ kart].
              Positioned(
                top: headerH,
                left: 0,
                right: 0,
                height: bandHeight,
                child: Center(
                  child: LivePkReferenceStreamerBand(
                    leftCard: LivePkReferenceStreamerCard(
                      displayName: layout.left.label,
                      avatarUrl: layout.left.avatarUrl,
                      userId: layout.left.userId,
                      isLocal: layout.left.isLocalPane,
                      showFollow: _showPkFollow(layout.left, myUserId: myUserId),
                      accent: const Color(0xFFFF2D6B),
                    ),
                    centerTimer: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD24A).withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ended
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      color: Color(0xFFFFD54F), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'PK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
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
                    rightCard: LivePkReferenceStreamerCard(
                      displayName: layout.right.label,
                      avatarUrl: layout.right.avatarUrl,
                      userId: layout.right.userId,
                      isLocal: layout.right.isLocalPane,
                      showFollow:
                          _showPkFollow(layout.right, myUserId: myUserId),
                      accent: const Color(0xFF2E9BFF),
                    ),
                  ),
                ),
              ),
              // Referans skor barı — video ile alt kontroller arasında.
              Positioned(
                top: scoreBarTop,
                left: 0,
                right: 0,
                child: LivePkReferenceScoreBar(
                  leftScore: leftScore,
                  rightScore: rightScore,
                  showStatus: !ended,
                  statusText: 'PK devam ediyor!',
                ),
              ),
              Positioned(
                left: LivePkLayoutMetrics.chatOverlayLeftPadding,
                bottom: LivePkLayoutMetrics.videoBottomInset(context) + 6,
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
              Positioned(
                top: headerH + 8,
                right: 8,
                width: MediaQuery.sizeOf(context).width * 0.42,
                child: LivePkTopSupportersPanel(
                  sessionKey: streamId,
                  leftHostLabel: layout.left.label,
                  rightHostLabel: layout.right.label,
                  leftHostUserId: layout.left.userId,
                  rightHostUserId: layout.right.userId,
                ),
              ),
              LivePkScorePopOverlay(
                burstToken: burst.token,
                delta: burst.delta,
                toLeft: burst.toLeft,
              ),
              LivePkFinalCountdownOverlay(
                secondsLeft: displaySec,
                active: pkActive && !ended,
              ),
              LivePkPreparingOverlay(
                visible: pkStarting && !ended,
                leftName: layout.left.label,
                rightName: layout.right.label,
              ),
              LivePkResultFlashOverlay(
                visible: _resultFlashVisible && ended,
                isDraw: isDraw,
                iWon: iWon,
                myScore: myScore,
                opponentScore: oppScore,
              ),
              LivePkReconnectBanner(
                visible: sessionPhase == LiveSessionPhase.reconnecting,
              ),
            ],
          ),
        );
      },
        );
      },
    );
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
          video = ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'Kamera bekleniyor',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
