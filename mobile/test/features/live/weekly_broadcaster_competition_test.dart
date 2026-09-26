import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/pk/weekly_broadcaster_competition_models.dart';

void main() {
  group('WeeklyBroadcasterCompetition.fromJson', () {
    test('parses the documented participants/winners shape', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'week': 39,
        'participants': [
          {'userId': 'u1', 'displayName': 'Ayşe', 'score': 120, 'rank': 1},
          {'userId': 'u2', 'displayName': 'Mehmet', 'score': 80},
        ],
        'winners': [
          {'userId': 'u1', 'displayName': 'Ayşe', 'isWinner': true},
        ],
      });

      expect(comp.week, 39);
      expect(comp.participants, hasLength(2));
      expect(comp.participants.first.displayName, 'Ayşe');
      expect(comp.participants.first.score, 120);
      expect(comp.winners.single.isWinner, isTrue);
    });

    test('accepts leaderboard as the participants key', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'weekNumber': 12,
        'leaderboard': [
          {'id': 'u9', 'name': 'Zeynep', 'points': 45},
        ],
      });

      expect(comp.week, 12);
      expect(comp.participants, hasLength(1));
      expect(comp.participants.single.userId, 'u9');
      expect(comp.participants.single.displayName, 'Zeynep');
      expect(comp.participants.single.score, 45);
    });

    test('accepts standings/entries/rankings as the participants key', () {
      for (final key in ['standings', 'entries', 'rankings', 'items']) {
        final comp = WeeklyBroadcasterCompetition.fromJson({
          key: [
            {'userId': 'a', 'totalScore': 7},
          ],
        });
        expect(comp.participants, hasLength(1), reason: 'key $key was dropped');
        expect(comp.participants.single.score, 7, reason: 'key $key score');
      }
    });

    test('falls back to positional rank when the server omits rank', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'participants': [
          {'userId': 'a'},
          {'userId': 'b'},
        ],
      });

      expect(comp.participants.map((p) => p.rank), [1, 2]);
    });

    test('missing lists yield empty collections instead of throwing', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({'week': 3});

      expect(comp.participants, isEmpty);
      expect(comp.winners, isEmpty);
      expect(comp.endsAt, isNull);
    });
  });
}
