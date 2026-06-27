import 'package:equatable/equatable.dart';

import '../entities/chat_room_presence.dart';
import 'pk_battle_mode.dart';

/// Tek PK tarafı skorları ve üyeleri.
class PkSideState extends Equatable {
  const PkSideState({
    required this.score,
    required this.giftPower,
    this.winStreak = 0,
    this.members = const [],
    this.leader,
  });

  final int score;
  final int giftPower;
  final int winStreak;
  final List<ChatRoomPresence> members;
  final ChatRoomPresence? leader;

  int get total => score + giftPower;

  PkSideState copyWith({
    int? score,
    int? giftPower,
    int? winStreak,
    List<ChatRoomPresence>? members,
    ChatRoomPresence? leader,
  }) {
    return PkSideState(
      score: score ?? this.score,
      giftPower: giftPower ?? this.giftPower,
      winStreak: winStreak ?? this.winStreak,
      members: members ?? this.members,
      leader: leader ?? this.leader,
    );
  }

  @override
  List<Object?> get props => [score, giftPower, winStreak, members, leader];
}

/// Tam PK savaş durumu.
class PkBattleState extends Equatable {
  const PkBattleState({
    this.mode = PkBattleMode.oneVsOne,
    this.phase = PkBattlePhase.ready,
    this.secondsLeft = 300,
    this.left = const PkSideState(score: 0, giftPower: 0),
    this.right = const PkSideState(score: 0, giftPower: 0),
    this.winner = PkBattleWinner.none,
    this.reactionBurst = 0,
    this.remoteBattleId,
    this.targetScore = 150000,
    this.serverAuthoritative = false,
  });

  final PkBattleMode mode;
  final PkBattlePhase phase;
  final int secondsLeft;
  final PkSideState left;
  final PkSideState right;
  final PkBattleWinner winner;

  /// Hediye patlaması tetikleyici (artırılınca UI animasyonu).
  final int reactionBurst;

  /// Sunucu PK oturumu — web ile senkron.
  final String? remoteBattleId;
  final int targetScore;
  final bool serverAuthoritative;

  double get leftRatio {
    final t = left.total + right.total;
    if (t <= 0) return 0.5;
    return (left.total / t).clamp(0.08, 0.92);
  }

  bool get isActive => phase == PkBattlePhase.active;
  bool get isFinished => phase == PkBattlePhase.finished;

  String get timerLabel {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PkBattleState copyWith({
    PkBattleMode? mode,
    PkBattlePhase? phase,
    int? secondsLeft,
    PkSideState? left,
    PkSideState? right,
    PkBattleWinner? winner,
    int? reactionBurst,
    String? remoteBattleId,
    int? targetScore,
    bool? serverAuthoritative,
  }) {
    return PkBattleState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      left: left ?? this.left,
      right: right ?? this.right,
      winner: winner ?? this.winner,
      reactionBurst: reactionBurst ?? this.reactionBurst,
      remoteBattleId: remoteBattleId ?? this.remoteBattleId,
      targetScore: targetScore ?? this.targetScore,
      serverAuthoritative: serverAuthoritative ?? this.serverAuthoritative,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        phase,
        secondsLeft,
        left,
        right,
        winner,
        reactionBurst,
        remoteBattleId,
        targetScore,
        serverAuthoritative,
      ];
}
