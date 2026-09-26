import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/pk/weekly_broadcaster_competition_models.dart';
import 'package:canlifal_social/features/live/presentation/widgets/weekly_broadcaster_competition_card.dart';

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

    test('reads title and start/end under alternative keys', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'name': 'Eylül Kupası',
        'startAt': '2026-09-20T00:00:00.000Z',
        'finishesAt': '2026-09-27T00:00:00.000Z',
      });

      expect(comp.displayTitle, 'Eylül Kupası');
      expect(comp.startsAt, isNotNull);
      expect(comp.endsAt, isNotNull);
    });

    test('displayTitle falls back to the week number', () {
      expect(
        WeeklyBroadcasterCompetition.fromJson({'week': 39}).displayTitle,
        '39. Hafta Yarışması',
      );
      expect(
        WeeklyBroadcasterCompetition.fromJson({}).displayTitle,
        'Haftalık Yarışma',
      );
    });

    test('missing lists yield empty collections instead of throwing', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({'week': 3});

      expect(comp.participants, isEmpty);
      expect(comp.winners, isEmpty);
      expect(comp.endsAt, isNull);
    });
  });

  group('WeeklyBroadcasterCompetition phase and rank', () {
    final start = DateTime.utc(2026, 9, 20);
    final end = DateTime.utc(2026, 9, 27);

    WeeklyBroadcasterCompetition build() =>
        WeeklyBroadcasterCompetition.fromJson({
          'week': 39,
          'startsAt': start.toIso8601String(),
          'endsAt': end.toIso8601String(),
          'participants': [
            {'userId': 'u1', 'displayName': 'Ayşe', 'score': 120},
            {'userId': 'me', 'displayName': 'Ben', 'score': 80},
          ],
        });

    test('phase reflects the server window', () {
      final comp = build();
      expect(
        comp.phaseAt(DateTime.utc(2026, 9, 19)),
        WeeklyCompetitionPhase.upcoming,
      );
      expect(
        comp.phaseAt(DateTime.utc(2026, 9, 23)),
        WeeklyCompetitionPhase.running,
      );
      expect(
        comp.phaseAt(DateTime.utc(2026, 9, 28)),
        WeeklyCompetitionPhase.finished,
      );
    });

    test('without dates the competition is treated as running', () {
      final comp = WeeklyBroadcasterCompetition.fromJson({'week': 1});
      expect(comp.phaseAt(DateTime.now()), WeeklyCompetitionPhase.running);
      expect(comp.remainingAt(DateTime.now()), isNull);
    });

    test('remaining time is null once the window closed', () {
      final comp = build();
      expect(comp.remainingAt(DateTime.utc(2026, 9, 26)), isNotNull);
      expect(comp.remainingAt(DateTime.utc(2026, 9, 28)), isNull);
    });

    test('entryFor finds the signed-in user rank and score', () {
      final comp = build();
      final mine = comp.entryFor('me');
      expect(mine, isNotNull);
      expect(mine!.rank, 2);
      expect(mine.score, 80);
      expect(comp.entryFor('nobody'), isNull);
      expect(comp.entryFor(null), isNull);
      expect(comp.entryFor('  '), isNull);
    });
  });

  group('WeeklyBroadcasterCompetitionCard', () {
    testWidgets('shows title, status and participant count, not the full list',
        (tester) async {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'week': 39,
        'endsAt': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'participants': [
          {'userId': 'u1', 'displayName': 'Ayşe', 'score': 120},
          {'userId': 'u2', 'displayName': 'Mehmet', 'score': 80},
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBroadcasterCompetitionCard(competition: comp),
          ),
        ),
      );

      expect(find.textContaining('39. Hafta'), findsOneWidget);
      expect(find.text('Devam ediyor'), findsOneWidget);
      expect(find.textContaining('👥 2'), findsOneWidget);
      expect(find.text('Sıralamayı gör'), findsOneWidget);
      // Tam liste kutuda değil, detay sayfasında gösterilir.
      expect(find.text('Ayşe'), findsNothing);
      expect(find.text('Mehmet'), findsNothing);
    });

    testWidgets('collapses to a pill and restores', (tester) async {
      final comp = WeeklyBroadcasterCompetition.fromJson({'week': 4});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBroadcasterCompetitionCard(competition: comp),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();
      expect(find.text('Sıralamayı gör'), findsNothing);

      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pump();
      expect(find.text('Sıralamayı gör'), findsOneWidget);
    });

    testWidgets('a finished competition hides the countdown', (tester) async {
      final comp = WeeklyBroadcasterCompetition.fromJson({
        'week': 2,
        'endsAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'participants': [
          {'userId': 'u1', 'score': 5},
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBroadcasterCompetitionCard(competition: comp),
          ),
        ),
      );

      expect(find.text('Sona erdi'), findsOneWidget);
      expect(find.textContaining('⏱'), findsNothing);
    });
  });
}
