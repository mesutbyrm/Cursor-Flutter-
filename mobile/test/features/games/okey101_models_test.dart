import 'package:canlifal_social/features/games/domain/okey101/okey101_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Okey101PublicState parses server payload', () {
    const raw = {
      'gameType': 'okey101',
      'phase': 'playing',
      'status': 'playing',
      'openScoreTarget': 101,
      'deckCount': 40,
      'turnUserId': 'u1',
      'okey101': {
        'phase': 'playing',
        'turnUserId': 'u1',
        'turnName': 'Ali',
        'myHandPoints': 105,
        'players': [
          {
            'userId': 'u1',
            'displayName': 'Ali',
            'isMe': true,
            'handCount': 14,
            'hand': [
              {'id': 'red-5-a', 'color': 'red', 'value': 5},
            ],
          },
        ],
      },
    };

    final state = parseOkey101FromRoomRaw(raw);
    expect(state, isNotNull);
    expect(state!.phase, 'playing');
    expect(state.myHandPoints, 105);
    expect(state.me?.hand.length, 1);
    expect(state.isMyTurn('u1'), isTrue);
  });
}
