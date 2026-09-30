import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsePkBattleHttpBody reads participants and user1/user2', () {
    final battle = parsePkBattleHttpBody({
      'id': 'pk1',
      'status': 'active',
      'score1': 10,
      'score2': 20,
      'participants': [
        {
          'userId': 'u1',
          'side': 1,
          'name': 'Alpha',
          'image': 'https://example.com/a.png',
        },
        {
          'userId': 'u2',
          'side': 2,
          'name': 'Beta',
        },
      ],
      'user1': {'id': 'u1', 'name': 'Alpha'},
      'user2': {'id': 'u2', 'name': 'Beta'},
    });
    expect(battle, isNotNull);
    expect(battle!.participants.length, 2);
    expect(battle.participants.first.side, 1);
    expect(battle.participants.last.displayName, 'Beta');
  });
}
