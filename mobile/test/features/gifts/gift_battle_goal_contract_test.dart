import 'package:canlifal_social/features/gifts/domain/gift_battle.dart';
import 'package:canlifal_social/features/gifts/domain/gift_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftBattle contract parsing', () {
    test('parses production battle JSON from BACKEND_API_REFERENCE', () {
      final battle = GiftBattle.fromJson({
        'id': 'cmrk08mtz000uuqo9uzyhyjll',
        'context': 'voice_room',
        'contextId': 'room_1783994459',
        'status': 'ended',
        'durationSec': 180,
        'startedAt': '2026-07-14T02:00:59.542Z',
        'endsAt': '2026-07-14T02:03:59.542Z',
        'secondsLeft': 0,
        'lastCallActive': false,
        'winnerId': 'cmrk08mlo000suqo9tm7rmfma',
        'totalScore': 0,
        'participants': [
          {
            'rank': 1,
            'participantId': 'cmrk08mlo000suqo9tm7rmfma',
            'displayName': 'A',
            'score': 0,
            'displayScore': '0',
          },
          {
            'rank': 2,
            'participantId': 'cmrk08mrs000tuqo9ngsopcz0',
            'displayName': 'B',
            'score': 0,
            'displayScore': '0',
          },
        ],
      });

      expect(battle.id, 'cmrk08mtz000uuqo9uzyhyjll');
      expect(battle.context, 'voice_room');
      expect(battle.remainingSec, 0);
      expect(battle.totalScore, 0);
      expect(battle.lastCallActive, isFalse);
      expect(battle.participants.length, 2);
      expect(battle.participants.first.rank, 1);
      expect(battle.participants.first.displayName, 'A');
      expect(battle.isEnded, isTrue);
    });
  });

  group('GiftGoal contract parsing', () {
    test('uses percent when provided', () {
      final goal = GiftGoal.fromJson({
        'id': 'g1',
        'title': 'Jeton hedefi',
        'targetAmount': 1000,
        'currentAmount': 250,
        'context': 'voice_room',
        'contextId': 'room1',
        'status': 'active',
        'percent': 25,
      });
      expect(goal.percent, 25);
      expect(goal.progress, 0.25);
    });
  });
}
