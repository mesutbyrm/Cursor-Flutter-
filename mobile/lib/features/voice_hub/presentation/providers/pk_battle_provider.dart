import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_battle_mode.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_battle_state.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../../../live/domain/pk/live_pk_like_budget.dart';

/// PK savaş kontrolü — skor, zamanlayıcı, hediye gücü, kazanan.
class PkBattleNotifier extends Notifier<PkBattleState> {
  Timer? _tick;
  Timer? _endsAtSync;
  DateTime? _endsAtUtc;
  Duration _clockSkew = Duration.zero;
  VoiceRoomEntity? _room;
  List<ChatRoomPresence> _presence = const [];
  final _audienceSupportBudget = LivePkLikeBudget();

  @override
  PkBattleState build() {
    ref.onDispose(() {
      _tick?.cancel();
      _tick = null;
      _endsAtSync?.cancel();
      _endsAtSync = null;
    });
    return const PkBattleState();
  }

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
    _tick?.cancel();
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

  /// Jetonsuz izleyici desteği — taraf başına en fazla 3 puan (istemci gösterimi).
  bool applyAudienceSupport({
    required String battleId,
    required String userId,
    int points = 3,
    bool toLeft = true,
  }) {
    if (!state.isActive) return false;
    final bid = battleId.trim();
    final uid = userId.trim();
    if (bid.isEmpty || uid.isEmpty) return false;
    if (!_audienceSupportBudget.canAward(bid, uid, points)) return false;
    _audienceSupportBudget.record(bid, uid, points);
    if (toLeft) {
      state = state.copyWith(
        left: state.left.copyWith(
          audienceSupport: state.left.audienceSupport + points,
        ),
        reactionBurst: state.reactionBurst + 1,
      );
    } else {
      state = state.copyWith(
        right: state.right.copyWith(
          audienceSupport: state.right.audienceSupport + points,
        ),
        reactionBurst: state.reactionBurst + 1,
      );
    }
    return true;
  }

  int audienceSupportRemaining(String battleId, String userId) {
    return _audienceSupportBudget.remaining(battleId, userId);
  }

  List<ChatRoomPresence> _membersFromRemote({
    required PkBattleRemote remote,
    required int side,
    required ChatRoomPresence? leader,
    required List<ChatRoomPresence> fallbackPresence,
  }) {
    ChatRoomPresence fromParticipant(PkParticipantRemote p) {
      return ChatRoomPresence(
        id: p.userId,
        name: p.displayName ?? 'Katılımcı',
        image: p.avatarUrl,
        chatRole: p.userId == leader?.id ? 'owner' : 'member',
      );
    }

    final fromRemote = remote.participants
        .where((p) => p.side == side)
        .map(fromParticipant)
        .toList();
    if (fromRemote.isNotEmpty) {
      if (leader != null &&
          !fromRemote.any((m) => m.id.trim() == leader.id.trim())) {
        return [leader, ...fromRemote];
      }
      return fromRemote;
    }

    if (remote.participants.isEmpty && fallbackPresence.isNotEmpty) {
      if (state.mode == PkBattleMode.team) {
        final half = (fallbackPresence.length / 2).ceil().clamp(1, fallbackPresence.length);
        return side == 1
            ? fallbackPresence.take(half).toList()
            : fallbackPresence.skip(half).toList();
      }
    }

    if (leader != null) return [leader];
    return const [];
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
      final side = remote.result!.winnerSide?.toLowerCase().trim();
      if (side == 'tie' || side == 'draw') {
        winner = PkBattleWinner.tie;
      } else if (side == 'challenger' || side == 'host' || side == '1' || side == 'left') {
        winner = swapSides ? PkBattleWinner.right : PkBattleWinner.left;
      } else if (side == 'opponent' || side == 'guest' || side == '2' || side == 'right') {
        winner = swapSides ? PkBattleWinner.left : PkBattleWinner.right;
      } else if (remote.winnerId != null &&
          remote.winnerId!.trim().isNotEmpty) {
        final wid = remote.winnerId!.trim();
        final leftId = (swapSides ? remote.opponentId : remote.challengerId)?.trim();
        final rightId = (swapSides ? remote.challengerId : remote.opponentId)?.trim();
        if (wid == leftId) {
          winner = PkBattleWinner.left;
        } else if (wid == rightId) {
          winner = PkBattleWinner.right;
        }
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

    final leftMembers = _membersFromRemote(
      remote: remote,
      side: swapSides ? 2 : 1,
      leader: leftLeader,
      fallbackPresence: _presence,
    );
    final rightMembers = _membersFromRemote(
      remote: remote,
      side: swapSides ? 1 : 2,
      leader: rightLeader,
      fallbackPresence: _presence,
    );

    final newEndUtc = remote.endsAt?.toUtc();
    final endsAtChanged = newEndUtc != _endsAtUtc;
    final secLeft = remote.endsAt != null
        ? (endsAtChanged
            ? remote.resolvedSecondsLeft()
            : state.secondsLeft)
        : remote.secondsLeft;

    state = state.copyWith(
      phase: phase,
      secondsLeft: secLeft,
      targetScore: remote.targetScore,
      remoteBattleId: remote.id,
      serverAuthoritative: true,
      winner: winner,
      left: state.left.copyWith(
        score: leftScore,
        giftPower: 0,
        audienceSupport: state.left.audienceSupport,
        winStreak: swapSides
            ? remote.opponent?.winStreak ?? state.left.winStreak
            : remote.challenger?.winStreak ?? state.left.winStreak,
        leader: leftLeader ?? state.left.leader,
        members: leftMembers.isNotEmpty ? leftMembers : state.left.members,
      ),
      right: state.right.copyWith(
        score: rightScore,
        giftPower: 0,
        audienceSupport: state.right.audienceSupport,
        winStreak: swapSides
            ? remote.challenger?.winStreak ?? state.right.winStreak
            : remote.opponent?.winStreak ?? state.right.winStreak,
        leader: rightLeader ?? state.right.leader,
        members: rightMembers.isNotEmpty ? rightMembers : state.right.members,
      ),
      reactionBurst:
          remote.isActive ? state.reactionBurst + 1 : state.reactionBurst,
    );
    _tick?.cancel();
    _startEndsAtSync(
      endsAt: remote.endsAt,
      serverNow: remote.serverNow,
      phase: phase,
    );
  }

  void _startEndsAtSync({
    required DateTime? endsAt,
    required String? serverNow,
    required PkBattlePhase phase,
  }) {
    _endsAtSync?.cancel();
    _endsAtSync = null;
    _endsAtUtc = endsAt?.toUtc();
    _clockSkew = Duration.zero;
    final parsedNow = serverNow != null ? DateTime.tryParse(serverNow) : null;
    if (parsedNow != null) {
      _clockSkew =
          parsedNow.toUtc().difference(DateTime.now().toUtc());
    }
    if (_endsAtUtc == null || phase != PkBattlePhase.active) return;
    _endsAtSync = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isActive || !state.serverAuthoritative) return;
      final end = _endsAtUtc;
      if (end == null) return;
      final now = DateTime.now().toUtc().add(_clockSkew);
      final sec = end.difference(now).inSeconds.clamp(0, 86400);
      if (sec != state.secondsLeft) {
        state = state.copyWith(secondsLeft: sec);
      }
    });
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

  void reset() {
    _tick?.cancel();
    _tick = null;
    _endsAtSync?.cancel();
    _endsAtSync = null;
    _endsAtUtc = null;
    _room = null;
    _presence = const [];
    state = const PkBattleState();
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
