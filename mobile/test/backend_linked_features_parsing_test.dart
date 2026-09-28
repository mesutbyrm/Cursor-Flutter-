import 'package:canlifal_social/features/agency/domain/entities/agency_entity.dart';
import 'package:canlifal_social/features/dreams/domain/dream_contest.dart';
import 'package:canlifal_social/features/football/domain/football_models.dart';
import 'package:canlifal_social/features/live/presentation/utils/co_broadcast_invite_actions.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON örnekleri canlifal backend route handler'larının döndürdüğü biçimdir.
void main() {
  group('DreamContest (GET /api/dream-contest)', () {
    test('contest ve entries ayrıştırılır', () {
      final c = DreamContest.fromJson({
        'id': 'c1',
        'title': 'Haftanın rüyası',
        'description': 'Açıklama',
        'dreamPrompt': 'Uçtuğumu gördüm',
        'startDate': '2026-09-20T00:00:00.000Z',
        'endDate': '2026-09-30T00:00:00.000Z',
        'isActive': true,
        'isOngoing': true,
        'isEnded': false,
        'entryCount': 3,
      });
      expect(c.id, 'c1');
      expect(c.dreamPrompt, 'Uçtuğumu gördüm');
      expect(c.acceptsEntries, isTrue);
      expect(c.entryCount, 3);

      final e = DreamContestEntries.fromJson({
        'entries': [
          {
            'id': 'e1',
            'userId': 'u1',
            'interpretation': 'Özgürlük arayışı',
            'voteCount': 5,
            'user': {'id': 'u1', 'name': null, 'username': 'ayse', 'image': null},
          },
        ],
        'userVotedEntryIds': ['e1'],
      });
      expect(e.entries.single.userName, '@ayse');
      expect(e.entries.single.voteCount, 5);
      expect(e.votedEntryIds, {'e1'});
    });
  });

  group('Football (GET /api/football)', () {
    test('maç: fullTime skoru, localName ve canlı durumu', () {
      final m = FootballMatch.fromJson({
        'id': 1,
        'utcDate': '2026-09-28T18:00:00Z',
        'status': 'IN_PLAY',
        'homeTeam': {'name': 'Galatasaray SK', 'shortName': 'Galatasaray', 'crest': 'x.png'},
        'awayTeam': {'name': 'Fenerbahçe SK', 'shortName': 'Fenerbahçe'},
        'score': {
          'fullTime': {'home': 2, 'away': 1},
        },
        'competition': {'name': 'UEFA Champions League', 'localName': 'Şampiyonlar Ligi', 'flag': '🇪🇺'},
      });
      expect(m.home.name, 'Galatasaray');
      expect(m.isLive, isTrue);
      expect(m.hasScore, isTrue);
      expect('${m.homeGoals}-${m.awayGoals}', '2-1');
      expect(m.competitionName, 'Şampiyonlar Ligi');
    });

    test('başlamamış maçta skor yok', () {
      final m = FootballMatch.fromJson({
        'status': 'TIMED',
        'score': {'fullTime': {'home': null, 'away': null}},
      });
      expect(m.hasScore, isFalse);
      expect(m.statusLabel, '');
    });

    test('puan durumu TOTAL tablosunu seçer', () {
      final rows = FootballStandingRow.fromStandings([
        {'type': 'HOME', 'table': [{'position': 9}]},
        {
          'type': 'TOTAL',
          'table': [
            {
              'position': 1,
              'team': {'name': 'Arsenal FC', 'shortName': 'Arsenal'},
              'playedGames': 6,
              'won': 5,
              'draw': 1,
              'lost': 0,
              'goalDifference': 10,
              'points': 16,
            },
          ],
        },
      ]);
      expect(rows.single.position, 1);
      expect(rows.single.points, 16);
      expect(rows.single.team.name, 'Arsenal');
    });

    test('gol krallığı', () {
      final s = FootballScorer.fromJson({
        'player': {'name': 'Haaland'},
        'team': {'name': 'Manchester City'},
        'goals': 9,
      });
      expect(s.player, 'Haaland');
      expect(s.goals, 9);
    });
  });

  group('Agency weekly task (GET /api/agency/tasks)', () {
    test('currentTask + pastTasks', () {
      final t = AgencyWeeklyTasks.fromJson({
        'currentTask': {
          'id': 't1',
          'weekStart': '2026-09-28T00:00:00.000Z',
          'weekEnd': '2026-10-04T23:59:59.999Z',
          'earningsTarget': 500,
          'earningsActual': 250.5,
          'newUsersTarget': 3,
          'newUsersActual': 1,
          'activeUsersTarget': 6,
          'activeUsersActual': 6,
          'completionPercent': 61.6,
          'status': 'active',
        },
        'pastTasks': [
          {'id': 't0', 'completionPercent': 100},
        ],
      });
      expect(t.current!.earningsActual, 250.5);
      expect(t.current!.activeUsersActual, 6);
      expect(t.current!.completionPercent, closeTo(61.6, 0.01));
      expect(t.past.single.id, 't0');
    });

    test('currentTask yoksa null', () {
      expect(AgencyWeeklyTasks.fromJson({'error': 'Üye değilsiniz'}).current, isNull);
    });
  });

  group('Co-broadcast invites (GET /api/user/co-broadcast-invites)', () {
    final invite = {
      'id': 'i1',
      'streamId': 's1',
      'status': 'invited',
      'broadcaster': {'id': 'h1', 'name': 'Zeynep', 'image': null},
      'streamTitle': 'Akşam yayını',
    };

    test('userId alanı olmayan davet oturumdaki kullanıcıya aittir', () {
      expect(isPendingCoBroadcastInvite(invite, 'me'), isTrue);
      expect(coBroadcastInviteStreamId(invite), 's1');
      expect(coBroadcastInviteHostName(invite), 'Zeynep');
    });

    test('başka kullanıcıyı hedefleyen veya bitmiş davet elenir', () {
      expect(isPendingCoBroadcastInvite({...invite, 'userId': 'other'}, 'me'), isFalse);
      expect(isPendingCoBroadcastInvite({...invite, 'status': 'ended'}, 'me'), isFalse);
    });
  });
}
