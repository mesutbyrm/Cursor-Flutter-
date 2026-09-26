import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/cfc_arena/domain/cfc_arena_contest_detail.dart';

void main() {
  // Üretim `GET /api/cfc-arena/{id}` yanıtının birebir şekli.
  const production = {
    'success': true,
    'data': {
      'contest': {
        'id': 'c1',
        'name': 'Haftalık yayıncı yarışması ',
        'status': 'active',
        'startsAt': '2026-09-22T01:47:00.000Z',
        'endsAt': '2026-10-22T01:47:00.000Z',
        '_count': {'participants': 4, 'teams': 0},
      },
      'leaderboard': [
        {
          'id': 'e1',
          'userId': 'u-admin',
          'displayName': null,
          'score': 0,
          'rank': null,
          'user': {'id': 'u-admin', 'name': 'Admin', 'image': 'a.jpg'},
        },
        {
          'id': 'e2',
          'userId': 'u-ilham',
          'displayName': 'İlham Perisi',
          'score': 120,
          'rank': null,
          'user': {'id': 'u-ilham', 'name': 'İlham Perisi'},
        },
      ],
      'teams': <dynamic>[],
      'page': 1,
      'limit': 50,
    },
  };

  group('CfcArenaContestDetail.parse', () {
    test('reads the contest and the leaderboard out of the envelope', () {
      final detail = CfcArenaContestDetail.parse(production);
      expect(detail.contest['id'], 'c1');
      expect(detail.entries, hasLength(2));
    });

    test('falls back to the nested user name when displayName is null', () {
      final detail = CfcArenaContestDetail.parse(production);
      final admin = detail.entryFor('u-admin');
      expect(admin?.name, 'Admin');
      expect(admin?.image, 'a.jpg');
    });

    test('prefers the entry displayName when the server sends one', () {
      final detail = CfcArenaContestDetail.parse(production);
      expect(detail.entryFor('u-ilham')?.name, 'İlham Perisi');
    });

    test('an entry without a user id is dropped', () {
      final detail = CfcArenaContestDetail.parse({
        'data': {
          'leaderboard': [
            {'score': 10},
            {'userId': 'u1', 'score': 5},
          ],
        },
      });
      expect(detail.entries, hasLength(1));
      expect(detail.entries.single.userId, 'u1');
    });

    test('a body that is not a map yields an empty detail', () {
      expect(CfcArenaContestDetail.parse(null).isEmpty, isTrue);
      expect(CfcArenaContestDetail.parse('x').isEmpty, isTrue);
    });

    test('also accepts a bare contest map with participants', () {
      final detail = CfcArenaContestDetail.parse({
        'id': 'c9',
        'participants': [
          {'userId': 'u1', 'score': 3},
        ],
      });
      expect(detail.contest['id'], 'c9');
      expect(detail.entries, hasLength(1));
    });
  });

  group('ranking', () {
    test('sorts by score when the server sends no rank', () {
      final detail = CfcArenaContestDetail.parse(production);
      expect(detail.ranked.first.userId, 'u-ilham');
      expect(detail.rankFor('u-ilham'), 1);
      expect(detail.rankFor('u-admin'), 2);
    });

    test('honours an explicit server rank', () {
      final detail = CfcArenaContestDetail.parse({
        'data': {
          'leaderboard': [
            {'userId': 'a', 'score': 5, 'rank': 2},
            {'userId': 'b', 'score': 1, 'rank': 1},
          ],
        },
      });
      expect(detail.ranked.first.userId, 'b');
      expect(detail.rankFor('a'), 2);
    });

    test('hasJoined is true only for a listed user', () {
      final detail = CfcArenaContestDetail.parse(production);
      expect(detail.hasJoined('u-admin'), isTrue);
      expect(detail.hasJoined('u-nobody'), isFalse);
      expect(detail.hasJoined(null), isFalse);
      expect(detail.hasJoined('  '), isFalse);
    });

    test('rankFor is null for someone who never joined', () {
      final detail = CfcArenaContestDetail.parse(production);
      expect(detail.rankFor('u-nobody'), isNull);
    });
  });

  group('cfcContestRemaining', () {
    test('returns the distance to endsAt', () {
      final detail = CfcArenaContestDetail.parse(production);
      final remaining = cfcContestRemaining(
        detail.contest,
        DateTime.utc(2026, 10, 20, 1, 47),
      );
      expect(remaining, const Duration(days: 2));
    });

    test('a finished contest reports zero, never a negative span', () {
      final detail = CfcArenaContestDetail.parse(production);
      final remaining = cfcContestRemaining(
        detail.contest,
        DateTime.utc(2026, 11, 1),
      );
      expect(remaining, Duration.zero);
    });

    test('an unknown end date reports null instead of guessing', () {
      expect(cfcContestRemaining(const {}, DateTime.utc(2026)), isNull);
      expect(
        cfcContestRemaining(const {'endsAt': 'not-a-date'}, DateTime.utc(2026)),
        isNull,
      );
    });
  });

  group('formatCfcRemaining', () {
    test('uses the largest sensible unit', () {
      expect(formatCfcRemaining(const Duration(days: 3)), '3 gün');
      expect(formatCfcRemaining(const Duration(hours: 5)), '5 sa');
      expect(formatCfcRemaining(const Duration(minutes: 40)), '40 dk');
      expect(formatCfcRemaining(const Duration(seconds: 20)), 'bitiyor');
    });
  });
}
