import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PkBattleRemoteDataSource ds;

  setUp(() {
    ds = PkBattleRemoteDataSource(Dio());
  });

  group('PkBattleRemoteDataSource.parseBattleForTest', () {
    test('empty GET wrapper returns null', () {
      expect(
        ds.parseBattleForTest({
          'roomId': 'cmokyb9o9007iod09gi6pb1tb',
          'activeBattle': null,
          'pendingInvite': null,
        }),
        isNull,
      );
    });

    test('pendingInvite is parsed', () {
      final battle = ds.parseBattleForTest({
        'roomId': 'room-a',
        'activeBattle': null,
        'pendingInvite': {
          'inviteId': 'inv-1',
          'status': 'pending',
          'voiceRoomId': 'room-a',
          'opponentVoiceRoomId': 'room-b',
          'opponentId': 'user-b',
          'durationSeconds': 180,
        },
      });
      expect(battle, isNotNull);
      expect(battle!.effectiveId, 'inv-1');
      expect(battle.isPending, isTrue);
    });

    test('activeBattle is parsed', () {
      final battle = ds.parseBattleForTest({
        'roomId': 'room-a',
        'activeBattle': {
          'id': 'battle-1',
          'status': 'active',
          'challengerScore': 100,
          'opponentScore': 50,
        },
        'pendingInvite': null,
      });
      expect(battle, isNotNull);
      expect(battle!.id, 'battle-1');
      expect(battle.isActive, isTrue);
    });

    test('legacy battle key still works', () {
      final battle = ds.parseBattleForTest({
        'battle': {
          'id': 'b-legacy',
          'status': 'active',
        },
      });
      expect(battle?.id, 'b-legacy');
    });
  });
}
