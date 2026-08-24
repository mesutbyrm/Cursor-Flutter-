import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PkBattleRemoteDataSource ds;

  setUp(() {
    ds = PkBattleRemoteDataSource(Dio());
  });

  test('parseBattleForTest handles pk me invites list item', () {
    final battle = ds.parseBattleForTest({
      'inviteId': 'inv-rest-1',
      'status': 'pending',
      'voiceRoomId': 'room-host',
      'opponentVoiceRoomId': 'room-guest',
      'durationSeconds': 180,
    });
    expect(battle, isNotNull);
    expect(battle!.effectiveId, 'inv-rest-1');
    expect(battle.isPending, isTrue);
  });

  test('parseBattleForTest handles invited status', () {
    final battle = ds.parseBattleForTest({
      'inviteId': 'inv-invited',
      'status': 'invited',
      'voiceRoomId': 'room-host',
      'opponentVoiceRoomId': 'room-guest',
    });
    expect(battle, isNotNull);
    expect(battle!.isPending, isTrue);
    expect(battle.effectiveId, 'inv-invited');
  });
}
