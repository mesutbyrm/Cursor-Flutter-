import '../../../live/domain/entities/voice_room_entity.dart';
import 'pk_battle_remote_models.dart';

/// Sol/sağ PK etiketleri ve skorları — başlatan vs izleyici.
class PkTeamSidePresentation {
  const PkTeamSidePresentation({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftScore,
    required this.rightScore,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftScore;
  final int rightScore;
}

String resolvePkInitiatorUserId(PkBattleRemote battle) {
  return (battle.challengerId ?? battle.challenger?.userId ?? '').trim();
}

/// Başlatan: sol «Biz», sağ «Onlar». Diğerleri: «1. Takım» / «2. Takım» (sol = başlatan tarafı).
PkTeamSidePresentation resolveVoicePkTeamPresentation({
  required PkBattleRemote battle,
  required String? currentUserId,
  VoiceRoomEntity? room,
}) {
  final initiatorId = resolvePkInitiatorUserId(battle);
  final uid = currentUserId?.trim() ?? '';
  final isInitiator = uid.isNotEmpty && uid == initiatorId;

  final leftScore = battle.challengerScore;
  final rightScore = battle.opponentScore;

  if (isInitiator) {
    return PkTeamSidePresentation(
      leftLabel: 'Biz',
      rightLabel: 'Onlar',
      leftScore: leftScore,
      rightScore: rightScore,
    );
  }
  return PkTeamSidePresentation(
    leftLabel: '1. Takım',
    rightLabel: '2. Takım',
    leftScore: leftScore,
    rightScore: rightScore,
  );
}
