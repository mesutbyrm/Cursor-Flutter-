import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PkCandidate.fromRoomJson reads rooms[] wire fields', () {
    final c = PkCandidate.fromRoomJson({
      'voiceRoomId': 'cuid-room-1',
      'ownerId': 'user-owner',
      'roomName': 'İlham Perisi',
      'onlineCount': 2,
    });
    expect(c.contextId, 'cuid-room-1');
    expect(c.userId, 'user-owner');
    expect(c.name, 'İlham Perisi');
    expect(c.viewers, 2);
  });

  test('parsePkBattleHttpBody create_user starting battle', () {
    final battle = parsePkBattleHttpBody({
      'id': 'pk-99',
      'status': 'starting',
      'scope': 'room_user',
      'stream1Id': 'room-a',
      'duration': 180,
      'countdownSec': 5,
    });
    expect(battle, isNotNull);
    expect(battle!.effectiveId, 'pk-99');
    expect(battle.voiceRoomId, 'room-a');
    expect(battle.status, 'starting');
  });
}
