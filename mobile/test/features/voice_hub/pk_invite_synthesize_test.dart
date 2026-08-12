import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PkBattleRemoteDataSource ds;

  setUp(() {
    ds = PkBattleRemoteDataSource(Dio());
  });

  test('synthesizePendingBattle from success inviteId response', () {
    final battle = ds.parseBattleForTest({
      'success': true,
      'inviteId': 'inv-xyz',
      'status': 'pending',
    });
    expect(battle, isNotNull);
    expect(battle!.effectiveId, 'inv-xyz');
    expect(battle.isPending, isTrue);
  });
}
