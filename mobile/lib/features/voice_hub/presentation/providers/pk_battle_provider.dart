import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_battle_mode.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_battle_state.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';

/// PK savaş kontrolü — skor, zamanlayıcı, hediye gücü, kazanan.
class PkBattleNotifier extends Notifier<PkBattleState> {
  Timer? _tick;
  VoiceRoomEntity? _room;
  List<ChatRoomPresence> _presence = const [];

  @override
  PkBattleState build() => const PkBattleState();

  /// PK sayfası açılışında — sunucu onayı gelene kadar aktif sayma.
  void prepareShell({
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
    ChatRoomPresence? left,
    ChatRoomPresence? right,
    PkBattleMode mode = PkBattleMode.oneVsOne,
  }) {
    _room = room;
    _presence = presence;
    _tick?.cancel();

    final sides = _buildSides(
      presence: presence,
      room: room,
      left: left,
      right: right,
      mode: mode,
    );

    state = PkBattleState(
      mode: mode,
      phase: PkBattlePhase.ready,
      secondsLeft: 0,
      left: sides.$1,
      right: sides.$2,
    );
  }

  void init({
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
    ChatRoomPresence? left,
    ChatRoomPresence? right,
    PkBattleMode mode = PkBattleMode.oneVsOne,
    int durationSeconds = 300,
  }) {
    prepareShell(
      room: room,
      presence: presence,
      left: left,
      right: right,
      mode: mode,
    );
    state = state.copyWith(
      phase: PkBattlePhase.active,
      secondsLeft: durationSeconds,
    );
    ref.onDispose(() => _tick?.cancel());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  (PkSideState, PkSideState) _buildSides({
    required List<ChatRoomPresence> presence,
    required VoiceRoomEntity room,
    ChatRoomPresence? left,
    ChatRoomPresence? right,
    required PkBattleMode mode,
  }) {
    ChatRoomPresence? pick(int i) {
      if (presence.length > i) return presence[i];
      if (i == 0 && room.ownerName != null) {
        return ChatRoomPresence(
          id: room.ownerId ?? 'host',
          name: room.ownerName!,
          image: room.ownerAvatarUrl,
          chatRole: 'owner',
        );
      }
      return null;
    }

    final l = left ?? pick(0);
    final r = right ?? pick(1);

    if (mode == PkBattleMode.team) {
      final half = (presence.length / 2).ceil().clamp(1, presence.length);
      final teamA = presence.take(half).toList();
      final teamB = presence.skip(half).toList();
      return (
        PkSideState(
          score: 0,
          giftPower: 0,
          winStreak: 0,
          members: teamA,
          leader: l ?? (teamA.isNotEmpty ? teamA.first : null),
        ),
        PkSideState(
          score: 0,
          giftPower: 0,
          winStreak: 0,
          members: teamB,
          leader: r ?? (teamB.isNotEmpty ? teamB.first : null),
        ),
      );
    }

    return (
      PkSideState(
        score: 0,
        giftPower: 0,
        winStreak: 0,
        members: l != null ? [l] : const [],
        leader: l,
      ),
      PkSideState(
        score: 0,
        giftPower: 0,
        winStreak: 0,
        members: r != null ? [r] : const [],
        leader: r,
      ),
    );
  }

  void setMode(PkBattleMode mode) {
    if (_room == null) return;
    final sides = _buildSides(
      presence: _presence,
      room: _room!,
      left: state.left.leader,
      right: state.right.leader,
      mode: mode,
    );
    state = state.copyWith(
      mode: mode,
      left: sides.$1.copyWith(score: state.left.score, giftPower: state.left.giftPower),
      right: sides.$2.copyWith(score: state.right.score, giftPower: state.right.giftPower),
    );
  }

  void applyGift(LiveGiftEvent event, {required bool toLeft}) {
    if (!state.isActive || state.serverAuthoritative) return;
    if (!giftSideResolvable(event)) return;
    final power = event.jetonAmount;
    final bump = (power * 0.85).round().clamp(50, 500000);

    if (toLeft) {
      state = state.copyWith(
        left: state.left.copyWith(giftPower: state.left.giftPower + bump),
        reactionBurst: state.reactionBurst + 1,
      );
    } else {
      state = state.copyWith(
        right: state.right.copyWith(giftPower: state.right.giftPower + bump),
        reactionBurst: state.reactionBurst + 1,
      );
    }
  }

  /// Hediye hangi PK tarafına sayılır — alıcı id ile eşleme (tahmin yok).
  bool giftTargetsLeft(LiveGiftEvent event) {
    final leftIds = _sideUserIds(state.left);
    final rightIds = _sideUserIds(state.right);
    final rid = event.receiverId?.trim();
    if (rid != null && rid.isNotEmpty) {
      if (leftIds.contains(rid)) return true;
      if (rightIds.contains(rid)) return false;
    }
    final sid = event.senderId?.trim();
    if (sid != null && sid.isNotEmpty) {
      if (leftIds.contains(sid)) return true;
      if (rightIds.contains(sid)) return false;
    }
    return true;
  }

  bool giftSideResolvable(LiveGiftEvent event) {
    final leftIds = _sideUserIds(state.left);
    final rightIds = _sideUserIds(state.right);
    final rid = event.receiverId?.trim();
    if (rid != null && rid.isNotEmpty) {
      return leftIds.contains(rid) || rightIds.contains(rid);
    }
    final sid = event.senderId?.trim();
    if (sid != null && sid.isNotEmpty) {
      return leftIds.contains(sid) || rightIds.contains(sid);
    }
    return false;
  }

  Set<String> _sideUserIds(PkSideState side) {
    return {
      ...side.members.map((e) => e.id.trim()).where((id) => id.isNotEmpty),
      if (side.leader != null && side.leader!.id.trim().isNotEmpty)
        side.leader!.id.trim(),
    };
  }

  void applyRemoteBattle(PkBattleRemote remote) {
    _applyRemoteBattleInternal(remote, swapSides: false);
  }

  /// Sesli oda: sol taraf her zaman bu odanın tarafı (kendim).
  void applyRemoteBattleForVoiceRoom(
    PkBattleRemote remote,
    VoiceRoomEntity room,
  ) {
    final swap = !isPkChallengerRoom(remote, room);
    _applyRemoteBattleInternal(remote, swapSides: swap);
  }

  void _applyRemoteBattleInternal(
    PkBattleRemote remote, {
    required bool swapSides,
  }) {
    _tick?.cancel();
    final phase = remote.isActive
        ? PkBattlePhase.active
        : remote.isEnded
            ? PkBattlePhase.finished
            : PkBattlePhase.ready;

    PkBattleWinner winner = PkBattleWinner.none;
    if (remote.isEnded && remote.result != null) {
      final side = remote.result!.winnerSide;
      if (side == 'tie') {
        winner = PkBattleWinner.tie;
      } else if (side == 'challenger') {
        winner = swapSides ? PkBattleWinner.right : PkBattleWinner.left;
      } else if (side == 'opponent') {
        winner = swapSides ? PkBattleWinner.left : PkBattleWinner.right;
      }
    }

    ChatRoomPresence? leaderFrom(PkParticipantRemote? p) {
      if (p == null || p.userId.isEmpty) return null;
      return ChatRoomPresence(
        id: p.userId,
        name: p.displayName ?? 'Yayıncı',
        image: p.avatarUrl,
        chatRole: 'owner',
      );
    }

    final leftScore =
        swapSides ? remote.opponentScore : remote.challengerScore;
    final rightScore =
        swapSides ? remote.challengerScore : remote.opponentScore;
    final leftLeader = leaderFrom(
      swapSides ? remote.opponent : remote.challenger,
    );
    final rightLeader = leaderFrom(
      swapSides ? remote.challenger : remote.opponent,
    );

    state = state.copyWith(
      phase: phase,
      secondsLeft: remote.secondsLeft,
      targetScore: remote.targetScore,
      remoteBattleId: remote.id,
      serverAuthoritative: true,
      winner: winner,
      left: state.left.copyWith(
        score: leftScore,
        giftPower: 0,
        winStreak: swapSides
            ? remote.opponent?.winStreak ?? state.left.winStreak
            : remote.challenger?.winStreak ?? state.left.winStreak,
        leader: leftLeader ?? state.left.leader,
      ),
      right: state.right.copyWith(
        score: rightScore,
        giftPower: 0,
        winStreak: swapSides
            ? remote.challenger?.winStreak ?? state.right.winStreak
            : remote.opponent?.winStreak ?? state.right.winStreak,
        leader: rightLeader ?? state.right.leader,
      ),
      reactionBurst:
          remote.isActive ? state.reactionBurst + 1 : state.reactionBurst,
    );
    if (remote.isActive && remote.secondsLeft > 0) {
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  void _onTick() {
    if (!state.isActive || state.serverAuthoritative) return;
    if (state.secondsLeft <= 1) {
      _finish();
      return;
    }
    state = state.copyWith(secondsLeft: state.secondsLeft - 1);
  }

  void _finish() {
    _tick?.cancel();
    final l = state.left.total;
    final r = state.right.total;
    final winner = l == r
        ? PkBattleWinner.tie
        : l > r
            ? PkBattleWinner.left
            : PkBattleWinner.right;
    state = state.copyWith(
      phase: PkBattlePhase.finished,
      secondsLeft: 0,
      winner: winner,
      reactionBurst: state.reactionBurst + 1,
    );
  }

  void restart({int durationSeconds = 300}) {
    final winner = state.winner;
    var leftStreak = state.left.winStreak;
    var rightStreak = state.right.winStreak;
    if (winner == PkBattleWinner.left) {
      leftStreak++;
      rightStreak = 0;
    } else if (winner == PkBattleWinner.right) {
      rightStreak++;
      leftStreak = 0;
    }

    state = state.copyWith(
      phase: PkBattlePhase.active,
      secondsLeft: durationSeconds,
      winner: PkBattleWinner.none,
      left: state.left.copyWith(giftPower: 0, winStreak: leftStreak),
      right: state.right.copyWith(giftPower: 0, winStreak: rightStreak),
    );
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

}

final pkBattleProvider = NotifierProvider<PkBattleNotifier, PkBattleState>(
  PkBattleNotifier.new,
);
