import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/presentation/sync/gift_event_listener.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/pk/pk_team_label_helper.dart';
import '../widgets/pk/pk_ends_at_countdown.dart';
import '../widgets/pk/voice_pk_invite_action_card.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_battle_mode.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk_room/pk_wire_event.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/pk/pk_battle_state.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_provider.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_combo_tracker.dart';
import '../providers/voice_gift_leaderboard_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../providers/voice_room_audio_providers.dart';
import '../audio/voice_trtc_engine.dart';
import '../providers/voice_room_ui_provider.dart';
import '../utils/voice_room_permissions.dart';
import '../theme/voice_room_tokens.dart';
import '../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../widgets/premium/voice_gift_stage_overlays.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../widgets/premium_2026/pk/pk_action_bottom_bar.dart';
import '../widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../widgets/premium_2026/pk/pk_floating_reactions.dart';
import '../widgets/premium_2026/pk/pk_gift_explosion_flash.dart';
import '../widgets/premium_2026/pk/pk_gift_feed_panel.dart';
import '../widgets/premium_2026/pk/pk_mic_participant_row.dart';
import '../widgets/premium_2026/pk/pk_mode_switcher.dart';
import '../widgets/premium_2026/pk/pk_player_hud_frame.dart';
import '../widgets/premium_2026/pk/pk_team_battle_strip.dart';
import '../widgets/premium_2026/pk/pk_vs_emblem.dart';
import '../widgets/voice_room_gift_sheet.dart';
import '../../../pk/presentation/widgets/pk_start_sheet.dart';
import '../../../pk/presentation/widgets/pk_battle_visuals.dart';

/// Premium 2026 PK savaş — 1v1, takım, realtime skor, hediye gücü, kazanan FX.
class VoicePkBattlePage extends ConsumerStatefulWidget {
  const VoicePkBattlePage({
    super.key,
    required this.room,
    this.leftUser,
    this.rightUser,
  });

  final VoiceRoomEntity room;
  final ChatRoomPresence? leftUser;
  final ChatRoomPresence? rightUser;

  @override
  ConsumerState<VoicePkBattlePage> createState() => _VoicePkBattlePageState();
}

class _VoicePkBattlePageState extends ConsumerState<VoicePkBattlePage> {
  StreamSubscription<LiveGiftEvent>? _giftSub;
  var _lastGiftSideLeft = true;
  var _supportToLeft = true;
  var _chatOpen = true; // sohbet PK sırasında varsayılan açık (yazılanlar görünür)
  var _soundMuted = false;
  var _opponentMuted = false;
  var _bridgeConnected = false;
  var _resultNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final live = ref.read(voiceRoomLiveProvider(widget.room.liveKey));
    ref.read(pkBattleProvider.notifier).prepareShell(
          room: widget.room,
          presence: live.presence,
          left: widget.leftUser,
          right: widget.rightUser,
        );
    _startGiftRealtime();
    unawaited(_startPkRemote());
  }

  Future<void> _startPkRemote() async {
    final r = widget.room;
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.loadRoomBattle(
      roomKey,
      alternateRoomId: r.slug != roomKey ? r.slug : null,
    );
    if (!mounted) return;
    final battle = ref.read(pkBattleRemoteProvider);
    if (battle == null || battle.isEnded) return;

    // Görsel shell'i BU odanın bağlamıyla doğrudan besle. Global senkron
    // (voiceRoomByIdProvider) ilk açılışta gecikirse katılımcılar boş kalıp
    // ancak yenilemede görünüyordu; sayfa kendi odasını bildiği için hemen dolar.
    if (pkBattleBelongsToRoom(battle, r)) {
      ref
          .read(pkBattleProvider.notifier)
          .applyRemoteBattleForVoiceRoom(battle, r);
    }

    if (battle.isActive) _connectOpponentAudio(battle);

    if (battle.isPending && !battle.isActive) {
      final userId = ref.read(authControllerProvider).valueOrNull?.id;
      final isTarget = isPkInviteTarget(battle, r, userId: userId);
      final isChallenger = isPkChallengerRoom(battle, r);
      if (!isTarget && !isChallenger) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await openVoicePkInviteSheet(context, ref, r);
        return;
      }
    }
  }

  void _startGiftRealtime() {
    ref.read(voiceRoomLiveProvider(widget.room.liveKey));
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    final r = widget.room;
    final key = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    service.start(key);
    _giftSub?.cancel();
    _giftSub = service.events.listen(_onGiftEvent);
  }

  void _onGiftEvent(LiveGiftEvent raw) {
    if (!mounted) return;
    final event = ref.read(voiceGiftComboTrackerProvider.notifier).enrich(raw);
    ref.read(voiceSessionGiftLeaderboardProvider.notifier).record(event);

    final toLeft = ref.read(pkBattleProvider.notifier).giftTargetsLeft(event);
    _lastGiftSideLeft = toLeft;
    ref.read(pkBattleProvider.notifier).applyGift(event, toLeft: toLeft);
  }

  var _supporting = false;

  ChatRoomPresence? _self(VoiceRoomLiveState live) {
    final me = ref.read(authControllerProvider).valueOrNull?.id;
    if (me == null) return null;
    for (final p in live.presence) {
      if (p.id == me) return p;
    }
    return null;
  }

  bool _selfSeated(VoiceRoomLiveState live) {
    final p = _self(live);
    return p != null && p.seatIndex != null && p.seatIndex! >= 0;
  }

  bool _selfMicOpen(VoiceRoomLiveState live) => _self(live)?.micOpen ?? false;

  /// "Destekle": sunucu BULUNDUĞUN odanın tarafına +3 yazar ve iki odaya anında
  /// yayınlar. Taraf istemciden seçilmez (oda-vs-oda); yalnızca oda içi takım
  /// PK'sında desteklenen takım seçilir.
  Future<void> _onPkSupport() async {
    if (_supporting) return;
    final remote = ref.read(pkBattleRemoteProvider);
    if (remote == null || !remote.isActive) return;
    _supporting = true;
    final r = widget.room;
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    final battleId = remote.effectiveId;
    try {
      final res = await ref.read(chatRoomRemoteProvider).supportPk(
            roomKey: roomKey,
            alternateKey: r.slug != roomKey ? r.slug : null,
            battleId: battleId,
            side: remote.isInRoomUser ? (_supportToLeft ? 1 : 2) : null,
          );
      if (!mounted) return;
      // Anında yansıt: sunucunun kesin skoru (SSE aynı değeri iki odaya da taşır).
      ref.read(pkBattleRemoteProvider.notifier).applyScorePatch(
            PkWireEvent(
              kind: PkWireKind.score,
              battleId: battleId,
              raw: {
                'battleId': battleId,
                'score1': res.score1,
                'score2': res.score2,
              },
            ),
          );
      ref.read(pkBattleProvider.notifier).pulseReaction();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 900),
            content: Text('+${res.added > 0 ? res.added : 3} puan!'),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      _supporting = false;
    }
  }

  void _openResultPageIfNeeded({
    required PkBattleState pk,
    PkBattleRemote? remote,
  }) {
    if (_resultNavigated || !mounted) return;
    final ended = pk.isFinished || (remote?.isEnded ?? false);
    if (!ended) return;
    _resultNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement('/pk/result');
    });
  }

  /// Karşı odanın kullanıcıları: PK katılımcılarından benim tarafım dışındakiler
  /// + karşı oda sahibi.
  Set<String> _opponentUserIds(PkBattleRemote remote) {
    final mine = isPkChallengerRoom(remote, widget.room) ? 1 : 2;
    final ids = <String>{
      for (final p in remote.participants)
        if (p.side != 0 && p.side != mine && p.userId.isNotEmpty) p.userId,
    };
    final host = mine == 1
        ? (remote.opponent?.userId ?? remote.opponentId)
        : (remote.challenger?.userId ?? remote.challengerId);
    if (host != null && host.trim().isNotEmpty) ids.add(host.trim());
    return ids;
  }

  String? _opponentHostId(PkBattleRemote remote) {
    final mine = isPkChallengerRoom(remote, widget.room) ? 1 : 2;
    final host = mine == 1
        ? (remote.opponent?.userId ?? remote.opponentId)
        : (remote.challenger?.userId ?? remote.challengerId);
    final t = host?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  /// Oda sahibi PK başlayınca karşı oda sahibini TRTC cross-room ile arar:
  /// iki odanın dinleyicileri karşı sahibin sesini duyar. Başarısız olursa
  /// (ör. mikrofon yayını kapalı) sessizce geçilir; kendi oda sesi etkilenmez.
  void _connectOpponentAudio(PkBattleRemote remote) {
    if (_bridgeConnected || !remote.isActive) return;
    final me = ref.read(authControllerProvider).valueOrNull?.id ?? '';
    final iAmOwner = me.isNotEmpty && widget.room.ownerId == me;
    if (!iAmOwner || remote.isInRoomUser) return;
    final mineIsChallenger = isPkChallengerRoom(remote, widget.room);
    final oppRoomKey =
        (mineIsChallenger ? remote.opponentVoiceRoomId : remote.voiceRoomId)
                ?.trim() ??
            '';
    final oppHost = _opponentHostId(remote);
    if (oppRoomKey.isEmpty || oppHost == null) return;
    try {
      ref.read(voiceRoomAudioCoordinatorProvider).trtcManager.connectOtherRoom(
            strRoomId: VoiceTrtcEngine.trtcRoomIdFor(oppRoomKey),
            userId: oppHost,
          );
      _bridgeConnected = true;
    } catch (_) {}
  }

  /// Karşı tarafın sesini yalnızca BU cihazda kapat/aç.
  void _toggleOpponentSound() {
    final remote = ref.read(pkBattleRemoteProvider);
    if (remote == null) return;
    final muted = !_opponentMuted;
    setState(() => _opponentMuted = muted);
    ref
        .read(voiceRoomAudioCoordinatorProvider)
        .trtcManager
        .setLocallyMutedRemoteUsers(muted ? _opponentUserIds(remote) : const {});
  }

  /// Koltuktaki kullanıcı PK sırasında mikrofonunu açıp kapatır.
  Future<void> _toggleMic() async {
    final coord = ref.read(voiceRoomAudioCoordinatorProvider);
    final turnOn = !coord.micOn;
    if (turnOn) {
      final ok = await VoiceTrtcEngine.requestMicrophonePermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli')),
        );
        return;
      }
    }
    try {
      await coord.setMicEnabled(turnOn);
      if (!mounted) return;
      ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .applySelfMicOpen(turnOn);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  void _toggleSound() {
    final muted = !_soundMuted;
    setState(() => _soundMuted = muted);
    ref.read(voiceRoomAudioCoordinatorProvider).setHeadphonesOn(!muted);
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    // PK ses köprüsü ve yerel "karşı sesi kapat" yalnızca PK'ya özgüdür.
    try {
      final mgr = ref.read(voiceRoomAudioCoordinatorProvider).trtcManager;
      if (_opponentMuted) mgr.setLocallyMutedRemoteUsers(const {});
      if (_bridgeConnected) mgr.disconnectOtherRoom();
    } catch (_) {}
    // PK sayfası kapanırken uzak sesleri geri aç (oda sessizde kalmasın).
    if (_soundMuted) {
      try {
        ref.read(voiceRoomAudioCoordinatorProvider).setHeadphonesOn(true);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(voiceRoomLiveProvider(widget.room.liveKey));
    final pk = ref.watch(pkBattleProvider);
    final remote = ref.watch(pkBattleForRoomProvider(widget.room));
    final leadingLeft = pk.left.total >= pk.right.total;
    final isChallenger = remote != null &&
        [widget.room.apiRoomKey, widget.room.id, widget.room.slug]
            .contains(remote.voiceRoomId);
    final room = widget.room;
    final sessionKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final pkGiftAnimating = ref.watch(
      giftSessionProvider(sessionKey)
          .select((s) => s.activeAnimation != null),
    );
    final user = ref.watch(authControllerProvider).valueOrNull;
    ChatRoomPresence? selfPresence;
    if (user != null) {
      for (final p in List<ChatRoomPresence>.from(live.presence)) {
        if (p.id == user.id) {
          selfPresence = p;
          break;
        }
      }
    }
    final perms = VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: selfPresence,
      server: live.serverPermissions,
    );
    final canControlPk =
        perms.isRoomOwner || perms.canModerate || perms.isSiteAdmin;

    ref.listen<PkBattleState>(pkBattleProvider, (prev, next) {
      _openResultPageIfNeeded(pk: next, remote: remote);
    });
    ref.listen<PkBattleRemote?>(pkBattleForRoomProvider(widget.room), (prev, next) {
      if (next != null && pkBattleBelongsToRoom(next, widget.room)) {
        ref
            .read(pkBattleProvider.notifier)
            .applyRemoteBattleForVoiceRoom(next, widget.room);
      }
      _openResultPageIfNeeded(pk: pk, remote: next);
    });

    return GiftEventListener(
      sessionKey: sessionKey,
      child: Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VoiceCosmicBackground(),
          Consumer(
            builder: (context, ref, _) {
              final activeGift = ref.watch(
                giftSessionProvider(sessionKey)
                    .select((s) => s.activeAnimation),
              );
              final giftsOn = ref.watch(
                voiceRoomUiProvider.select((s) => s.giftAnimationsEnabled),
              );
              return Positioned.fill(
                child: IgnorePointer(
                  child: GiftEngineOverlay(
                    event: activeGift,
                    enabled: giftsOn,
                    stage: GiftStageContext.voiceRoom,
                    sessionKey: sessionKey,
                    onFinished: (id) {
                      ref
                          .read(giftSessionProvider(sessionKey).notifier)
                          .dequeueAnimation(id);
                    },
                  ),
                ),
              );
            },
          ),
          PkFloatingReactions(
            burstToken: pk.reactionBurst,
            enabled: pk.isActive,
          ),
          PkGiftExplosionFlash(
            token: pk.reactionBurst,
            toLeft: _lastGiftSideLeft,
          ),
          SafeArea(
            child: Column(
              children: [
                _PkHeader(
                  timer: pk.timerLabel,
                  battleEndsAt: remote?.endsAt,
                  serverNow: DateTime.tryParse(remote?.serverNow ?? ''),
                  fallbackSeconds: remote?.resolvedSecondsLeft() ?? pk.secondsLeft,
                  phase: pk.phase,
                  onBack: () => context.pop(),
                  chatOpen: _chatOpen,
                  onToggleChat: () => setState(() => _chatOpen = !_chatOpen),
                  soundMuted: _soundMuted,
                  onToggleSound: _toggleSound,
                  opponentMuted: _opponentMuted,
                  onToggleOpponent: _toggleOpponentSound,
                  canMic: _selfSeated(live),
                  micOn: _selfMicOpen(live),
                  onToggleMic: _toggleMic,
                  onMode: pk.isActive && !pk.serverAuthoritative
                      ? (m) => ref.read(pkBattleProvider.notifier).setMode(m)
                      : null,
                  mode: pk.mode,
                ),
                Expanded(
                  flex: 3,
                  child: pk.mode == PkBattleMode.team
                      ? _TeamBattleBody(
                          state: pk,
                          leadingLeft: leadingLeft,
                        )
                      : _OneVsOneBody(
                          state: pk,
                          leadingLeft: leadingLeft,
                          hideHudScores: pkGiftAnimating,
                          supportToLeft: _supportToLeft,
                          onSelectSupportSide: (toLeft) {
                            setState(() => _supportToLeft = toLeft);
                            ref
                                .read(pkBattleProvider.notifier)
                                .setAudienceSupportSide(toLeft: toLeft);
                          },
                          leftTeamLabel: remote != null
                              ? resolveVoicePkTeamPresentation(
                                  battle: remote,
                                  currentUserId: user?.id,
                                  room: widget.room,
                                ).leftLabel
                              : null,
                          rightTeamLabel: remote != null
                              ? resolveVoicePkTeamPresentation(
                                  battle: remote,
                                  currentUserId: user?.id,
                                  room: widget.room,
                                ).rightLabel
                              : null,
                        ),
                ),
                if (pk.mode == PkBattleMode.team && remote != null)
                  PkTeamBattleStrip(
                    state: pk,
                    leftTitle: resolveVoicePkTeamPresentation(
                      battle: remote,
                      currentUserId: user?.id,
                      room: widget.room,
                    ).leftLabel.toUpperCase(),
                    rightTitle: resolveVoicePkTeamPresentation(
                      battle: remote,
                      currentUserId: user?.id,
                      room: widget.room,
                    ).rightLabel.toUpperCase(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: PkAnimatedScoreBar(
                    state: pk,
                    compact: true,
                    battleEndsAt: remote?.endsAt,
                    serverNow: DateTime.tryParse(remote?.serverNow ?? ''),
                    fallbackSeconds: remote?.resolvedSecondsLeft() ?? pk.secondsLeft,
                  ),
                ),
                if (remote != null &&
                    remote.isPending &&
                    !remote.isActive &&
                    user != null &&
                    isPkInviteTarget(remote, widget.room, userId: user.id) &&
                    !isPkChallengerRoom(remote, widget.room))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: VoicePkInviteActionCard(
                      onAccept: () {
                        final r = widget.room;
                        final roomKey =
                            r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
                        ref.read(pkBattleRemoteProvider.notifier).accept(
                              remote.effectiveId,
                              roomId: roomKey,
                              alternateRoomId:
                                  r.slug != roomKey ? r.slug : null,
                            );
                      },
                      onReject: () {
                        final r = widget.room;
                        final roomKey =
                            r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
                        ref.read(pkBattleRemoteProvider.notifier).reject(
                              remote.effectiveId,
                              roomId: roomKey,
                              alternateRoomId:
                                  r.slug != roomKey ? r.slug : null,
                            );
                      },
                    ),
                  )
                else if (remote?.isPending == true && isChallenger)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      'Rakip kabul edene kadar bekleniyor…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                PkMicParticipantRow(
                  presence: live.presence,
                  selfUserId: ref.read(authControllerProvider).valueOrNull?.id,
                ),
                Expanded(
                  flex: 2,
                  child: PkGiftFeedPanel(messages: live.messages),
                ),
                if (pk.isActive && canControlPk)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final battle = ref.read(
                            pkBattleForRoomProvider(widget.room),
                          );
                          final battleId = battle?.effectiveId ?? '';
                          if (battleId.isEmpty) return;
                          final r = widget.room;
                          final roomKey =
                              r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
                          PkEventLog.ending(battleId: battleId);
                          await ref.read(pkBattleRemoteProvider.notifier).end(
                                battleId,
                                roomId: roomKey,
                                alternateRoomId:
                                    r.slug != roomKey ? r.slug : null,
                              );
                          PkEventLog.ended(battleId: battleId);
                          if (context.mounted) context.pop();
                        },
                        icon: const Icon(Icons.stop_circle_outlined, size: 14),
                        label: const Text(
                          'Bitir',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
                PkActionBottomBar(
                  onSupport: _onPkSupport,
                  onGift: () {
                    final pkState = ref.read(pkBattleProvider);
                    final seated = <ChatRoomPresence>[
                      ...pkState.left.members,
                      ...pkState.right.members,
                    ];
                    final initial = _supportToLeft
                        ? pkState.left.leader
                        : pkState.right.leader;
                    showVoiceRoomGiftPicker(
                      context,
                      ref,
                      room: widget.room,
                      seatedUsers: seated,
                      initialReceiver: initial,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _PkQuickChat(
                    room: widget.room,
                    showMessages: _chatOpen,
                  ),
                ),
              ],
            ),
          ),
          VoiceGiftHudOverlays(sessionKey: sessionKey),
        ],
      ),
      ),
    );
  }
}

class _PkHeader extends StatelessWidget {
  const _PkHeader({
    required this.timer,
    required this.battleEndsAt,
    required this.serverNow,
    required this.fallbackSeconds,
    required this.mode,
    required this.phase,
    required this.onBack,
    required this.onMode,
    required this.chatOpen,
    required this.onToggleChat,
    required this.soundMuted,
    required this.onToggleSound,
    required this.opponentMuted,
    required this.onToggleOpponent,
    required this.canMic,
    required this.micOn,
    required this.onToggleMic,
  });

  final String timer;
  final DateTime? battleEndsAt;
  final DateTime? serverNow;
  final int fallbackSeconds;
  final PkBattleMode mode;
  final PkBattlePhase phase;
  final VoidCallback onBack;
  final ValueChanged<PkBattleMode>? onMode;
  final bool chatOpen;
  final VoidCallback onToggleChat;
  final bool soundMuted;
  final VoidCallback onToggleSound;
  final bool opponentMuted;
  final VoidCallback onToggleOpponent;
  final bool canMic;
  final bool micOn;
  final VoidCallback onToggleMic;

  @override
  Widget build(BuildContext context) {
    final liveLabel = phase == PkBattlePhase.finished ? 'BİTTİ' : timer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              const Expanded(
                child: Text(
                  'PK Savaşı',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              if (onMode != null) ...[
                PkModeSwitcher(mode: mode, onChanged: onMode!),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: chatOpen ? 'Sohbeti gizle' : 'Sohbeti göster',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleChat,
                icon: Icon(
                  chatOpen
                      ? Icons.chat_bubble_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: chatOpen ? VoiceRoomTokens.neonPurple : Colors.white,
                ),
              ),
              if (canMic)
                IconButton(
                  tooltip: micOn ? 'Mikrofonu kapat' : 'Mikrofonu aç',
                  visualDensity: VisualDensity.compact,
                  onPressed: onToggleMic,
                  icon: Icon(
                    micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 22,
                    color: micOn ? const Color(0xFF22C55E) : VoiceRoomTokens.neonPink,
                  ),
                ),
              IconButton(
                tooltip: opponentMuted
                    ? 'Karşı tarafın sesini aç'
                    : 'Karşı tarafın sesini kapat',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleOpponent,
                icon: Icon(
                  opponentMuted
                      ? Icons.person_off_rounded
                      : Icons.record_voice_over_rounded,
                  size: 22,
                  color: opponentMuted ? VoiceRoomTokens.neonPink : Colors.white,
                ),
              ),
              IconButton(
                tooltip: soundMuted ? 'Sesleri aç' : 'Sesleri kapat',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleSound,
                icon: Icon(
                  soundMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 22,
                  color: soundMuted ? VoiceRoomTokens.neonPink : Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phase != PkBattlePhase.finished) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppThemeColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppThemeColors.liveRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (phase == PkBattlePhase.finished)
                  Text(
                    liveLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      fontFeatures: [FontFeature.tabularFigures()],
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

class _PkQuickChat extends ConsumerStatefulWidget {
  const _PkQuickChat({required this.room, this.showMessages = false});

  final VoiceRoomEntity room;

  /// Son mesaj listesini göster (üst sağdaki sohbet ikonu). Yazma alanı her
  /// zaman görünür.
  final bool showMessages;

  @override
  ConsumerState<_PkQuickChat> createState() => _PkQuickChatState();
}

class _PkQuickChatState extends ConsumerState<_PkQuickChat> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(voiceRoomLiveProvider(widget.room.liveKey));
    final recent = live.messages.length <= 8
        ? live.messages
        : live.messages.sublist(live.messages.length - 8);

    Future<void> send() async {
      final t = _ctrl.text.trim();
      if (t.isEmpty) return;
      _ctrl.clear();
      await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .sendMessage(t);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showMessages && recent.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              reverse: true,
              itemCount: recent.length,
              itemBuilder: (_, i) {
                final m = recent[recent.length - 1 - i];
                final name = m.user?.displayName ?? 'Kullanıcı';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$name: ${m.content}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yaz…',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => send(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                child: Material(
                  color: const Color(0xFF25D366),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: send,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child:
                          Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OneVsOneBody extends StatelessWidget {
  const _OneVsOneBody({
    required this.state,
    required this.leadingLeft,
    this.hideHudScores = false,
    this.supportToLeft = true,
    this.onSelectSupportSide,
    this.leftTeamLabel,
    this.rightTeamLabel,
  });

  final PkBattleState state;
  final bool leadingLeft;
  final bool hideHudScores;
  final bool supportToLeft;
  final ValueChanged<bool>? onSelectSupportSide;
  final String? leftTeamLabel;
  final String? rightTeamLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: state.isActive
                    ? () => onSelectSupportSide?.call(true)
                    : null,
                child: PkOutcomeBorder(
                  outcome: pkSideOutcome(
                    isLeft: true,
                    leftScore: state.left.total,
                    rightScore: state.right.total,
                    battleActive: state.isActive,
                    leftWon: state.winner == PkBattleWinner.left,
                    rightWon: state.winner == PkBattleWinner.right,
                    isDraw: state.winner == PkBattleWinner.tie,
                  ),
                  urgentPulse: state.isActive &&
                      state.secondsLeft > 0 &&
                      state.secondsLeft <= 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: supportToLeft && state.isActive
                          ? Border.all(
                              color: VoiceRoomTokens.neonPink,
                              width: 2,
                            )
                          : null,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.center,
                        colors: [
                          VoiceRoomTokens.neonPink.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: PkPlayerHudFrame(
                      user: state.left.leader,
                      accent: VoiceRoomTokens.neonPurple,
                      label: (leftTeamLabel ?? '1. TAKIM').toUpperCase(),
                      score: state.left.total,
                      showScore: !hideHudScores,
                      isLeading: leadingLeft && state.isActive,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: state.isActive
                    ? () => onSelectSupportSide?.call(false)
                    : null,
                child: PkOutcomeBorder(
                  outcome: pkSideOutcome(
                    isLeft: false,
                    leftScore: state.left.total,
                    rightScore: state.right.total,
                    battleActive: state.isActive,
                    leftWon: state.winner == PkBattleWinner.left,
                    rightWon: state.winner == PkBattleWinner.right,
                    isDraw: state.winner == PkBattleWinner.tie,
                  ),
                  urgentPulse: state.isActive &&
                      state.secondsLeft > 0 &&
                      state.secondsLeft <= 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: !supportToLeft && state.isActive
                          ? Border.all(
                              color: VoiceRoomTokens.neonBlue,
                              width: 2,
                            )
                          : null,
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.center,
                        colors: [
                          VoiceRoomTokens.neonBlue.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: PkPlayerHudFrame(
                      user: state.right.leader,
                      accent: VoiceRoomTokens.neonBlue,
                      label: (rightTeamLabel ?? '2. TAKIM').toUpperCase(),
                      score: state.right.total,
                      showScore: !hideHudScores,
                      isLeading: !leadingLeft && state.isActive,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const PkVsEmblem(size: 92),
      ],
    );
  }
}

class _TeamBattleBody extends StatelessWidget {
  const _TeamBattleBody({
    required this.state,
    required this.leadingLeft,
  });

  final PkBattleState state;
  final bool leadingLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _TeamSidePanel(
                members: state.left.members,
                leader: state.left.leader,
                color: VoiceRoomTokens.neonPink,
                isLeading: leadingLeft,
              ),
            ),
            Expanded(
              child: _TeamSidePanel(
                members: state.right.members,
                leader: state.right.leader,
                color: VoiceRoomTokens.neonBlue,
                isLeading: !leadingLeft,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const PkVsEmblem(size: 80),
      ],
    );
  }
}

class _TeamSidePanel extends StatelessWidget {
  const _TeamSidePanel({
    required this.members,
    required this.leader,
    required this.color,
    required this.isLeading,
    this.alignEnd = false,
  });

  final List<ChatRoomPresence> members;
  final ChatRoomPresence? leader;
  final Color color;
  final bool isLeading;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          end: Alignment.center,
          colors: [color.withValues(alpha: 0.28), Colors.transparent],
        ),
      ),
      child: PkPlayerHudFrame(
        user: leader ?? (members.isNotEmpty ? members.first : null),
        accent: color,
        label: alignEnd ? 'TAKIM B' : 'TAKIM A',
        isLeading: isLeading,
      ),
    );
  }
}

