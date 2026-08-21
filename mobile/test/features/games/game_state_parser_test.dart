import 'package:canlifal_social/features/games/domain/game_state_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameStateParser', () {
    test('parseBoard supports list and string formats', () {
      expect(
        GameStateParser.parseBoard({'board': ['X', 'O', null, '-', '.', '']}),
        ['X', 'O', null, null, null, null, null, null, null],
      );
      expect(
        GameStateParser.parseBoard({'board': 'XOX---...'}),
        ['X', 'O', 'X', null, null, null, null, null, null],
      );
    });

    test('isMyTurn matches user id and player slots', () {
      final raw = {
        'currentTurn': 'player1',
        'player1Id': 'user-a',
        'player2Id': 'user-b',
      };
      expect(
        GameStateParser.isMyTurn(raw: raw, userId: 'user-a'),
        isTrue,
      );
      expect(
        GameStateParser.isMyTurn(raw: raw, userId: 'user-b'),
        isFalse,
      );
    });

    test('uniquePlayers dedupes duplicate identities', () {
      final raw = {
        'players': [
          {'id': 'u1', 'name': 'Ali'},
          {'userId': 'u1', 'username': 'Ali2'},
          {'id': 'u2', 'name': 'Veli'},
        ],
      };
      final players = GameStateParser.uniquePlayers(raw);
      expect(players.length, 2);
      expect(players.first['id'], 'u1');
    });

    test('roomMatches rejects mismatched room ids', () {
      expect(
        GameStateParser.roomMatches(
          expectedRoomId: 'room-a',
          raw: {'roomId': 'room-b'},
          snapshotRoomId: 'room-a',
        ),
        isFalse,
      );
      expect(
        GameStateParser.roomMatches(
          expectedRoomId: 'room-a',
          raw: {'roomId': 'room-a'},
          snapshotRoomId: 'room-a',
        ),
        isTrue,
      );
    });

    test('normalizeGameType maps aliases', () {
      expect(GameStateParser.normalizeGameType('tic-tac-toe'), 'xox');
      expect(GameStateParser.normalizeGameType('okey-101'), 'okey101');
    });
  });
}
