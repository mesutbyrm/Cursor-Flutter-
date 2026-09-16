import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../../voice_hub/domain/pk/pk_battle_mode.dart';
import '../../../voice_hub/domain/pk/pk_battle_state.dart';
import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/providers/pk_battle_provider.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_floating_reactions.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_gift_explosion_flash.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_winner_celebration.dart';
import '../providers/live_pk_ui_providers.dart';
import '../widgets/broadcast_room/live_pk_immersive_controls.dart';
import '../widgets/broadcast_room/live_pk_immersive_score_overlay.dart';
import '../widgets/broadcast_room/live_pk_immersive_video_pane.dart';
import '../widgets/broadcast_room/live_pk_intro_overlay.dart';
import '../widgets/broadcast_room/live_pk_resolved_timer.dart';
import '../widgets/broadcast_room/live_pk_score_pop_overlay.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../../../gifts/presentation/sync/gift_event_listener.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../gifts/presentation/sync/gift_session_state.dart';
import '../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../gifts/presentation/engine/gift_engine_seat_effects_overlay.dart';
import '../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../providers/live_room_providers.dart';
import '../providers/pk_room_providers.dart';
import '../gifts/live_gift_controller.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../widgets/broadcast_room/live_pk_score_bar.dart';
import '../widgets/live_playback_bridge.dart';

/// Canlı yayın split-screen PK — sol kendi yayın, sağ rakip, jeton skorları.
class LivePkBattlePage extends ConsumerStatefulWidget {
  const LivePkBattlePage({
    super.key,
    required this.session,
    this.opponentStream,
  });

  final LiveBroadcastSession session;
  final LiveStreamEntity? opponentStream;

  @override
  ConsumerState<LivePkBattlePage> createState() => _LivePkBattlePageState();
}

class _LivePkBattlePageState extends ConsumerState<LivePkBattlePage> {
  final _trtc = TrtcRoomManager();
  final _chatController = TextEditingController();
  var _lastGiftSideLeft = true;
  var _lastGiftDelta = 0;
  var _trtcReady = false;
  var _chatOpen = true;
  Timer? _pkPollTimer;
  String? _unifiedMatchId;

  String? get _streamId => widget.session.streamId?.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty) return;

    await _initTrtcPreview();

    final remote = ref.read(pkBattleRemoteProvider.notifier);
    final unified = await ref.read(pkRoomRemoteProvider).activeForStream(streamId);
    if (unified != null) {
      _unifiedMatchId = unified.id;
      ref.read(pkRoomProvider(unified.id).notifier).adopt(unified);
      remote.ingestSseBattle(pkRoomMatchToBattleRemote(unified, myStreamId: streamId));
    } else {
      await remote.loadStreamBattle(streamId);
    }

    ref.read(liveGiftControllerProvider).attach(
      streamId: streamId,
      receiverName: widget.session.streamerName ?? 'Yayıncı',
    );

    _pollPk();
  }

  Future<void> _initTrtcPreview() async {
    if (!widget.session.isHost) return;
    try {
      await _trtc.startPreviewOnly();
      if (mounted) setState(() => _trtcReady = true);
    } catch (_) {}
  }

  void _pollPk() {
    _pkPollTimer?.cancel();
    _pkPollTimer = Timer.periodic(const Duration(seconds: 8), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      final streamId = _streamId;
      if (streamId == null) return;
      final battle = await ref.read(pkBattleRemoteProvider.notifier).loadStreamBattle(streamId);
      if (battle != null && battle.isEnded) t.cancel();
    });
  }

  void _onGift(LiveGiftEvent event) {
    if (!mounted) return;
    final challengerId = ref.read(pkBattleRemoteProvider)?.challengerId;
    final toLeft = challengerId == null || event.senderId == challengerId;
    _lastGiftSideLeft = toLeft;
    _lastGiftDelta = (event.coinCost * event.quantity).clamp(1, 999999);
    ref.read(pkBattleProvider.notifier).applyGift(event, toLeft: toLeft);
  }

  @override
  void dispose() {
    _pkPollTimer?.cancel();
    _chatController.dispose();
    ref.read(liveGiftControllerProvider).detach();
    _trtc.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final unifiedId = _unifiedMatchId;
    if (unifiedId != null && unifiedId.isNotEmpty) {
      final m = await ref.read(pkUnifiedInviteProvider).respond(
            matchId: unifiedId,
            accept: true,
          );
      if (m != null) {
        ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(
              pkRoomMatchToBattleRemote(m, myStreamId: _streamId),
            );
      }
      return;
    }
    final id = ref.read(pkBattleRemoteProvider)?.id;
    final streamId = _streamId;
    if (id == null || streamId == null || streamId.isEmpty) return;
    await ref.read(pkBattleRemoteProvider.notifier).accept(
          id,
          streamId: streamId,
        );
  }

  Future<void> _reject() async {
    final unifiedId = _unifiedMatchId;
    if (unifiedId != null && unifiedId.isNotEmpty) {
      await ref.read(pkUnifiedInviteProvider).respond(matchId: unifiedId, accept: false);
      if (mounted) context.pop();
      return;
    }
    final id = ref.read(pkBattleRemoteProvider)?.id;
    final streamId = _streamId;
    if (id == null || streamId == null || streamId.isEmpty) return;
    await ref.read(pkBattleRemoteProvider.notifier).reject(
          id,
          streamId: streamId,
        );
    if (mounted) context.pop();
  }

  Future<void> _end() async {
    final unifiedId = _unifiedMatchId;
    if (unifiedId != null && unifiedId.isNotEmpty) {
      await ref.read(pkUnifiedInviteProvider).end(unifiedId);
      return;
    }
    final id = ref.read(pkBattleRemoteProvider)?.id;
    final streamId = _streamId;
    if (id == null || streamId == null || streamId.isEmpty) return;
    await ref.read(pkBattleRemoteProvider.notifier).end(
          id,
          streamId: streamId,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      final list = next.notifications;
      if (list.isEmpty) return;
      if (prev != null && prev.notifications.length == list.length) return;
      _onGift(list.last);
    });

    final remote = ref.watch(pkBattleRemoteProvider);
    final unifiedId = _unifiedMatchId;
    final unifiedMatch = unifiedId != null && unifiedId.isNotEmpty
        ? ref.watch(pkRoomProvider(unifiedId))
        : null;
    final pk = ref.watch(pkBattleProvider);
    final streamId = _streamId ?? '';
    final giftSession = streamId.isNotEmpty
        ? ref.watch(giftSessionProvider(streamId))
        : const GiftSessionState();
    final activeGift = giftSession.activeAnimation;
    final opponentMuted = streamId.isNotEmpty
        ? ref.watch(livePkOpponentMutedProvider(streamId))
        : false;

    final leftScore = unifiedMatch?.leftScore ??
        remote?.challengerScore ??
        pk.left.total;
    final rightScore = unifiedMatch?.rightScore ??
        remote?.opponentScore ??
        pk.right.total;
    final status = unifiedMatch?.status ?? remote?.status ?? (pk.isActive ? 'active' : 'pending');
    final isHost = widget.session.isHost;
    final leftName = widget.session.streamerName ?? 'Sen';
    final rightName = widget.opponentStream?.streamerName ??
        remote?.opponent?.displayName ??
        'Rakip';
    final opponentUserId = remote?.opponentId ??
        widget.opponentStream?.hostUserId ??
        '';

    final pkState = PkBattleState(
      phase: remote?.isEnded == true || pk.isFinished
          ? PkBattlePhase.finished
          : remote?.isActive == true || pk.isActive
              ? PkBattlePhase.active
              : PkBattlePhase.ready,
      secondsLeft: remote?.resolvedSecondsLeft() ?? pk.secondsLeft,
      left: pk.left.copyWith(score: leftScore, giftPower: 0),
      right: pk.right.copyWith(score: rightScore, giftPower: 0),
      winner: pk.winner,
      reactionBurst: pk.reactionBurst,
      serverAuthoritative: remote != null,
    );

    final pkActive = remote?.isActive == true || pk.isActive;
    final pending = remote?.isPending == true && !pkActive;
    final topInset = MediaQuery.paddingOf(context).top;
    final chatHeight = _chatOpen ? 52.0 : 0.0;
    final controlsHeight = 88.0 + MediaQuery.paddingOf(context).bottom;

    return GiftEventListener(
      sessionKey: streamId,
      isHost: widget.session.isHost,
      useVoiceRealtime: false,
      useLiveRealtime: streamId.isNotEmpty,
      liveStreamId: streamId.isEmpty ? null : streamId,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: LivePkImmersiveVideoPane(
                      isLocal: true,
                      displayName: leftName,
                      avatarUrl: widget.session.avatarUrl ?? widget.session.coverImageUrl,
                      micOn: _trtc.micOn,
                      cameraOn: _trtc.cameraOn,
                      chipAlignment: Alignment.topLeft,
                      video: _trtcReady
                          ? TrtcLocalVideoView(manager: _trtc)
                          : _fallbackThumb(widget.session.coverImageUrl),
                    ),
                  ),
                  Expanded(
                    child: LivePkImmersiveVideoPane(
                      displayName: rightName,
                      avatarUrl: widget.opponentStream?.thumbnailUrl,
                      micOn: true,
                      cameraOn: true,
                      chipAlignment: Alignment.topRight,
                      video: _opponentVideo(
                        opponentUserId: opponentUserId,
                        opponentMuted: opponentMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (pending)
              Positioned(
                left: 12,
                right: 12,
                top: topInset + 56,
                child: LivePkScoreBar(
                  leftScore: leftScore,
                  rightScore: rightScore,
                  status: status,
                  isHost: isHost,
                  onAccept: _accept,
                  onReject: _reject,
                  onEnd: _end,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsHeight + chatHeight,
              child: LivePkImmersiveScoreOverlay(
                leftScore: leftScore,
                rightScore: rightScore,
                leftLabel: leftName,
                rightLabel: rightName,
                showTieHint: pkState.isFinished,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: topInset + 4,
              child: _TopBar(
                onBack: () => context.pop(),
                timer: LivePkResolvedTimer(
                  remote: remote,
                  fallbackSeconds: pk.secondsLeft,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsHeight,
              child: LivePkChatInputBar(
                controller: _chatController,
                visible: _chatOpen && pkActive,
                onSend: () {
                  final text = _chatController.text.trim();
                  if (text.isEmpty || streamId.isEmpty) return;
                  _chatController.clear();
                  final name = widget.session.streamerName ?? 'Yayıncı';
                  unawaited(
                    ref.read(liveRoomProvider(streamId).notifier).sendMessage(
                          text,
                          selfName: name,
                        ),
                  );
                },
                onToggleVisibility: () => setState(() => _chatOpen = false),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LivePkImmersiveControls(
                items: [
                  LivePkControlItem(
                    icon: _trtc.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: 'Mikrofon',
                    active: _trtc.micOn,
                    onTap: isHost
                        ? () {
                            _trtc.setMicEnabled(!_trtc.micOn);
                            setState(() {});
                          }
                        : null,
                  ),
                  LivePkControlItem(
                    icon: _trtc.cameraOn
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: 'Kamera',
                    active: _trtc.cameraOn,
                    onTap: isHost
                        ? () {
                            _trtc.setCameraEnabled(!_trtc.cameraOn);
                            setState(() {});
                          }
                        : null,
                  ),
                  LivePkControlItem(
                    icon: opponentMuted
                        ? Icons.volume_off_rounded
                        : Icons.hearing_rounded,
                    label: 'Rakip ses',
                    active: !opponentMuted,
                    onTap: () {
                      if (streamId.isEmpty) return;
                      final next = !opponentMuted;
                      ref
                          .read(livePkOpponentMutedProvider(streamId).notifier)
                          .state = next;
                      final opp = opponentUserId.trim();
                      if (opp.isNotEmpty) {
                        _trtc.muteRemoteAudio(opp, next);
                      }
                      setState(() {});
                    },
                  ),
                  LivePkControlItem(
                    icon: _chatOpen
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    label: 'Sohbet',
                    onTap: () => setState(() => _chatOpen = !_chatOpen),
                  ),
                  LivePkControlItem(
                    icon: Icons.stop_circle_outlined,
                    label: 'Bitir',
                    danger: true,
                    onTap: pkActive && isHost ? _end : null,
                  ),
                ],
              ),
            ),
            LivePkIntroOverlay(visible: pkActive),
            LivePkScorePopOverlay(
              burstToken: pk.reactionBurst,
              delta: _lastGiftDelta,
              toLeft: _lastGiftSideLeft,
            ),
            PkFloatingReactions(
              burstToken: pk.reactionBurst,
              enabled: pkState.isActive,
            ),
            PkGiftExplosionFlash(
              token: pk.reactionBurst,
              toLeft: _lastGiftSideLeft,
            ),
            GiftEngineSeatEffectsOverlay(event: activeGift),
            Positioned.fill(
              child: IgnorePointer(
                child: GiftEngineOverlay(
                  event: activeGift,
                  stage: GiftStageContext.liveStream,
                  onFinished: (id) => ref
                      .read(giftSessionProvider(streamId).notifier)
                      .dequeueAnimation(id),
                ),
              ),
            ),
            PkWinnerCelebration(
              state: pkState,
              onRestart: () {
                final dur = remote?.durationSeconds ?? pkDefaultDurationSeconds;
                ref.read(pkBattleProvider.notifier).restart(durationSeconds: dur);
              },
              onClose: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      return CanlifalNetworkImage(url: url, fit: BoxFit.cover);
    }
    return const ColoredBox(color: Color(0xFF120A1E));
  }

  Widget _opponentVideo({
    required String opponentUserId,
    required bool opponentMuted,
  }) {
    final playback = widget.opponentStream?.playbackUrl;
    final thumb = widget.opponentStream?.thumbnailUrl;
    return ValueListenableBuilder<List<String>>(
      valueListenable: _trtc.remoteUserIdsNotifier,
      builder: (context, remoteIds, _) {
        final opp = opponentUserId.trim();
        if (_trtcReady && opp.isNotEmpty && remoteIds.contains(opp)) {
          return TrtcRemoteVideoView(manager: _trtc, userId: opp);
        }
        if (playback != null && playback.trim().isNotEmpty) {
          return LivePlaybackBridge(
            key: ValueKey('pk_opp_$opponentMuted'),
            playbackUrl: playback,
            thumbnailUrl: thumb,
            audible: !opponentMuted,
          );
        }
        return _fallbackThumb(thumb);
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.timer});

  final VoidCallback onBack;
  final Widget timer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
            Expanded(child: Center(child: timer)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: const Color(0xFF1A1F35),
              onSelected: (_) {},
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('Bildir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

