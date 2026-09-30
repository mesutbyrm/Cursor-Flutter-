import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_team_label_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initiator sees Biz / Onlar', () {
    const battle = PkBattleRemote(
      id: 'b1',
      battleType: 'voice_room',
      status: 'active',
      challengerScore: 10,
      opponentScore: 5,
      secondsLeft: 120,
      durationSeconds: 180,
      targetScore: 1000,
      challengerId: 'u1',
    );
    final p = resolveVoicePkTeamPresentation(
      battle: battle,
      currentUserId: 'u1',
    );
    expect(p.leftLabel, 'Biz');
    expect(p.rightLabel, 'Onlar');
    expect(p.leftScore, 10);
  });

  test('viewer sees 1. Takım / 2. Takım', () {
    const battle = PkBattleRemote(
      id: 'b1',
      battleType: 'voice_room',
      status: 'active',
      challengerScore: 10,
      opponentScore: 5,
      secondsLeft: 120,
      durationSeconds: 180,
      targetScore: 1000,
      challengerId: 'u1',
    );
    final p = resolveVoicePkTeamPresentation(
      battle: battle,
      currentUserId: 'u2',
    );
    expect(p.leftLabel, '1. Takım');
    expect(p.rightLabel, '2. Takım');
  });
}
