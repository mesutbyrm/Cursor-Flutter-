import '../../../voice_hub/domain/entities/chat_room_presence.dart';
import '../../../voice_hub/domain/pk/pk_battle_mode.dart';
import '../../../voice_hub/domain/pk/pk_battle_state.dart';
import 'pk_status_helper.dart';

/// Canlı yayın PK battle map → `PkBattleState` (sonuç ekranı).
PkBattleState livePkBattleStateFromBroadcast({
  required Map<String, dynamic>? battle,
  required String status,
  required int leftScore,
  required int rightScore,
  String? leftDisplayName,
  String? rightDisplayName,
}) {
  final ended = _isEndedStatus(status);
  final active = isLivePkActiveStatus(status);

  final phase = active
      ? PkBattlePhase.active
      : ended
          ? PkBattlePhase.finished
          : PkBattlePhase.ready;

  final winner = ended
      ? _resolveWinner(
          battle: battle,
          leftScore: leftScore,
          rightScore: rightScore,
        )
      : PkBattleWinner.none;

  ChatRoomPresence? leader(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return null;
    return ChatRoomPresence(
      id: '',
      name: n,
      chatRole: 'owner',
    );
  }

  return PkBattleState(
    phase: phase,
    left: PkSideState(
      score: leftScore,
      giftPower: 0,
      leader: leader(leftDisplayName),
    ),
    right: PkSideState(
      score: rightScore,
      giftPower: 0,
      leader: leader(rightDisplayName),
    ),
    winner: winner,
    serverAuthoritative: true,
  );
}

bool _isEndedStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'ended' || s == 'completed' || s == 'finished';
}

PkBattleWinner _resolveWinner({
  required Map<String, dynamic>? battle,
  required int leftScore,
  required int rightScore,
}) {
  final raw = battle?['winnerSide']?.toString().toLowerCase().trim() ?? '';
  if (raw.contains('draw') || raw == 'tie' || raw == 'berabere') {
    return PkBattleWinner.tie;
  }
  if (raw.contains('left') ||
      raw == 'challenger' ||
      raw == 'host' ||
      raw == 'score1') {
    return PkBattleWinner.left;
  }
  if (raw.contains('right') ||
      raw == 'opponent' ||
      raw == 'target' ||
      raw == 'score2') {
    return PkBattleWinner.right;
  }
  if (leftScore == rightScore) return PkBattleWinner.tie;
  return leftScore > rightScore ? PkBattleWinner.left : PkBattleWinner.right;
}
