import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_battle_mode.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_battle_state.dart';

/// PK savaş kontrolü — skor, zamanlayıcı, hediye gücü, kazanan.
class PkBattleNotifier extends Notifier<PkBattleState> {
  Timer? _tick;
  VoiceRoomEntity? _room;
  List<ChatRoomPresence> _presence = const [];

  @override
  PkBattleState build() => const PkBattleState();

  void init({
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
    ChatRoomPresence? left,
    ChatRoomPresence? right,
    PkBattleMode mode = PkBattleMode.oneVsOne,
    int durationSeconds = 300,
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
      phase: PkBattlePhase.active,
      secondsLeft: durationSeconds,
      left: sides.$1,
      right: sides.$2,
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
          score: _baseScore(teamA),
          giftPower: 0,
          winStreak: 2,
          members: teamA,
          leader: l ?? (teamA.isNotEmpty ? teamA.first : null),
        ),
        PkSideState(
          score: _baseScore(teamB),
          giftPower: 0,
          winStreak: 0,
          members: teamB,
          leader: r ?? (teamB.isNotEmpty ? teamB.first : null),
        ),
      );
    }

    return (
      PkSideState(
        score: _baseScore(l != null ? [l] : const []),
        giftPower: 0,
        winStreak: 3,
        members: l != null ? [l] : const [],
        leader: l,
      ),
      PkSideState(
        score: _baseScore(r != null ? [r] : const []),
        giftPower: 0,
        winStreak: 1,
        members: r != null ? [r] : const [],
        leader: r,
      ),
    );
  }

  int _baseScore(List<ChatRoomPresence> users) {
    var s = 0;
    for (final u in users) {
      s += 8000 + (u.id.hashCode.abs() % 4000);
    }
    return s;
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
    final power = event.coinCost * event.quantity * (event.combo.clamp(1, 99));
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

  /// Gönderici hangi tarafta — id veya isim eşlemesi.
  bool giftTargetsLeft(LiveGiftEvent event) {
    final leftIds = {
      ...state.left.members.map((e) => e.id),
      if (state.left.leader != null) state.left.leader!.id,
    };
    final sid = event.senderId;
    if (sid != null && leftIds.contains(sid)) return true;
    final rightIds = {
      ...state.right.members.map((e) => e.id),
      if (state.right.leader != null) state.right.leader!.id,
    };
    if (sid != null && rightIds.contains(sid)) return false;
    return event.senderName.hashCode.isEven;
  }

  void applyRemoteBattle(PkBattleRemote remote) {
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
        winner = PkBattleWinner.left;
      } else if (side == 'opponent') {
        winner = PkBattleWinner.right;
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

    state = state.copyWith(
      phase: phase,
      secondsLeft: remote.secondsLeft,
      targetScore: remote.targetScore,
      remoteBattleId: remote.id,
      serverAuthoritative: true,
      winner: winner,
      left: state.left.copyWith(
        score: remote.challengerScore,
        giftPower: 0,
        winStreak: remote.challenger?.winStreak ?? state.left.winStreak,
        leader: leaderFrom(remote.challenger) ?? state.left.leader,
      ),
      right: state.right.copyWith(
        score: remote.opponentScore,
        giftPower: 0,
        winStreak: remote.opponent?.winStreak ?? state.right.winStreak,
        leader: leaderFrom(remote.opponent) ?? state.right.leader,
      ),
      reactionBurst: remote.isActive ? state.reactionBurst + 1 : state.reactionBurst,
    );
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
