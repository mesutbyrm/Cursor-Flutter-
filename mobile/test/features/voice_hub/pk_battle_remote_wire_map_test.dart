import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeWireMap maps production stream1Id/stream2Id to room ids', () {
    final battle = PkBattleRemote.fromJson({
      'id': 'pk-1',
      'status': 'pending',
      'stream1Id': 'room-challenger',
      'stream2Id': 'room-opponent',
      'user1Id': 'user-a',
      'user2Id': 'user-b',
      'duration': 180,
    });
    expect(battle.voiceRoomId, 'room-challenger');
    expect(battle.opponentVoiceRoomId, 'room-opponent');
    expect(battle.challengerId, 'user-a');
    expect(battle.opponentId, 'user-b');
    expect(battle.isPending, isTrue);
  });

  test('fromJson maps me/invites envelope fields', () {
    final battle = PkBattleRemote.fromJson({
      'battleId': 'pk-99',
      'challengerRoomId': 'room-a',
      'opponentRoomId': 'room-b',
      'incoming': true,
      'status': 'pending',
    });
    expect(battle.effectiveId, 'pk-99');
    expect(battle.opponentVoiceRoomId, 'room-b');
    expect(battle.voiceRoomId, 'room-a');
  });
}
