import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../../voice_hub/domain/pk/pk_battle_mode.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/domain/pk/pk_battle_state.dart';
import '../../../voice_hub/domain/pk/pk_duration_options.dart';
import '../../../voice_hub/presentation/providers/pk_battle_provider.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_floating_reactions.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_gift_explosion_flash.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_loser_side_overlay.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_vs_emblem.dart';
import '../../../voice_hub/presentation/widgets/premium_2026/pk/pk_winner_celebration.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../../../gifts/presentation/sync/gift_event_listener.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../gifts/presentation/sync/gift_session_state.dart';
import '../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import '../../../voice_hub/presentation/widgets/premium/voice_gift_flight_overlay.dart';
import '../providers/pk_room_providers.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../widgets/broadcast_room/live_pk_score_bar.dart';

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
  var _lastGiftSideLeft = true;
  var _trtcReady = false;
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
    remote.connectSocket(streamId: streamId, battleId: ref.read(pkBattleRemoteProvider)?.id);

    ref.read(liveGiftSocketBridgeProvider).connect(
      streamId: streamId,
      onEvent: _onGift,
      onPkBattle: (battle) {
        final parsed = PkBattleRemote.fromJson(battle);
        if (parsed.id.isEmpty) return;
        ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(parsed);
        ref.read(pkBattleProvider.notifier).applyRemoteBattle(parsed);
      },
    );

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
    _pkPollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
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
    ref.read(pkBattleProvider.notifier).applyGift(event, toLeft: toLeft);
  }

  @override
  void dispose() {
    _pkPollTimer?.cancel();
    ref.read(liveGiftControllerProvider).detach();
    ref.read(liveGiftSocketBridgeProvider).disconnect();
    ref.read(pkBattleRemoteProvider.notifier).disconnectSocket();
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
    final remote = ref.watch(pkBattleRemoteProvider);
    final pk = ref.watch(pkBattleProvider);
    final streamId = _streamId ?? '';
    final giftSession = streamId.isNotEmpty
        ? ref.watch(giftSessionProvider(streamId))
        : const GiftSessionState();
    final flightEvents = giftSession.activeAnimation != null
        ? [giftSession.activeAnimation!]
        : const <LiveGiftEvent>[];

    final leftScore = remote?.challengerScore ?? pk.left.total;
    final rightScore = remote?.opponentScore ?? pk.right.total;
    final status = remote?.status ?? (pk.isActive ? 'active' : 'pending');
    final isHost = widget.session.isHost;
    final leftName = widget.session.streamerName ?? 'Sen';
    final rightName = widget.opponentStream?.streamerName ??
        remote?.opponent?.displayName ??
        'Rakip';
    final durationLabel = remote != null
        ? pkDurationBySeconds(remote.durationSeconds).shortLabel
        : null;

    final pkState = PkBattleState(
      phase: remote?.isEnded == true || pk.isFinished
          ? PkBattlePhase.finished
          : remote?.isActive == true || pk.isActive
              ? PkBattlePhase.active
              : PkBattlePhase.ready,
      secondsLeft: remote?.secondsLeft ?? pk.secondsLeft,
      left: pk.left.copyWith(score: leftScore, giftPower: 0),
      right: pk.right.copyWith(score: rightScore, giftPower: 0),
      winner: pk.winner,
      reactionBurst: pk.reactionBurst,
      serverAuthoritative: remote != null,
    );

    final leftWon = pkState.winner == PkBattleWinner.left;
    final rightWon = pkState.winner == PkBattleWinner.right;
    final showLoserFx = pkState.isFinished && pkState.winner != PkBattleWinner.tie;

    return GiftEventListener(
      sessionKey: streamId,
      isHost: widget.session.isHost,
      useVoiceRealtime: false,
      useLiveRealtime: streamId.isNotEmpty,
      liveStreamId: streamId.isEmpty ? null : streamId,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Canlı PK',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                      ),
                      if (durationLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            durationLabel,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: PkAnimatedScoreBar(state: pkState, compact: true),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PkVideoPane(
                            label: leftName,
                            accent: Colors.pinkAccent,
                            thumbnailUrl: widget.session.avatarUrl ??
                                widget.session.coverImageUrl,
                            trtc: _trtcReady ? _trtc : null,
                            isLocal: true,
                          ),
                        ),
                        Container(width: 2, color: Colors.white24),
                        Expanded(
                          child: _PkVideoPane(
                            label: rightName,
                            accent: Colors.cyanAccent,
                            thumbnailUrl: widget.opponentStream?.thumbnailUrl,
                            isLocal: false,
                          ),
                        ),
                      ],
                    ),
                    const PkVsEmblem(size: 72),
                    if (showLoserFx && rightWon)
                      const PkLoserSideOverlay(
                        visible: true,
                        alignment: Alignment.centerLeft,
                      ),
                    if (showLoserFx && leftWon)
                      const PkLoserSideOverlay(
                        visible: true,
                        alignment: Alignment.centerRight,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Geri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (remote?.isActive == true)
                      Expanded(
                        child: FilledButton(
                          onPressed: isHost ? _end : null,
                          child: const Text('PK Bitir'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          PkFloatingReactions(
            burstToken: pk.reactionBurst,
            enabled: pkState.isActive,
          ),
          PkGiftExplosionFlash(
            token: pk.reactionBurst,
            toLeft: _lastGiftSideLeft,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: VoiceGiftFlightOverlay(
                events: flightEvents,
                stageContext: GiftStageContext.liveStream,
                onFinished: (id) => ref
                    .read(giftSessionProvider(streamId).notifier)
                    .dequeueAnimation(id),
              ),
            ),
          ),
          SafePremiumGiftFullscreenOverlay(
            event: giftSession.activeFullscreen,
            stageContext: GiftStageContext.liveStream,
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
}

class _PkVideoPane extends StatelessWidget {
  const _PkVideoPane({
    required this.label,
    required this.accent,
    this.thumbnailUrl,
    this.trtc,
    this.isLocal = false,
  });

  final String label;
  final Color accent;
  final String? thumbnailUrl;
  final TrtcRoomManager? trtc;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    Widget videoChild;
    if (isLocal && trtc != null) {
      videoChild = TrtcLocalVideoView(manager: trtc!);
    } else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      videoChild = CanlifalNetworkImage(
        url: thumbnailUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      videoChild = Center(
        child: Icon(Icons.videocam_rounded, size: 48, color: accent),
      );
    }

    return Container(
      color: const Color(0xFF120A1E),
      child: Stack(
        fit: StackFit.expand,
        children: [
          videoChild,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
                stops: const [0, 0.45],
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
