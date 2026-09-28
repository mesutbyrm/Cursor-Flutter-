import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/agency/domain/entities/agency_entity.dart';
import 'package:canlifal_social/features/agency/presentation/widgets/agency_weekly_task_card.dart';
import 'package:canlifal_social/features/astrology/presentation/pages/compatibility_page.dart';
import 'package:canlifal_social/features/dreams/domain/dream_contest.dart';
import 'package:canlifal_social/features/dreams/presentation/pages/dream_contest_pages.dart';
import 'package:canlifal_social/features/dreams/presentation/providers/dream_contest_providers.dart';
import 'package:canlifal_social/features/football/data/football_remote_datasource.dart';
import 'package:canlifal_social/features/football/domain/football_models.dart';
import 'package:canlifal_social/features/football/presentation/football_page.dart';
import 'package:canlifal_social/features/trtc/presentation/pages/voice_audio_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    );

final _contest = DreamContest.fromJson({
  'id': 'c1',
  'title': 'Haftanın rüyası',
  'description': 'En iyi yorumu yap',
  'dreamPrompt': 'Denizin üstünde yürüyordum',
  'isOngoing': true,
  'isEnded': false,
  'entryCount': 1,
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rüya yarışması listesi ve detayı', (tester) async {
    _phone(tester);
    final overrides = [
      dreamContestsProvider.overrideWith((ref) async => [_contest]),
      dreamContestEntriesProvider('c1').overrideWith(
        (ref) async => DreamContestEntries.fromJson({
          'entries': [
            {
              'id': 'e1',
              'userId': 'u2',
              'interpretation': 'Huzur ve özgürlük arayışı',
              'voteCount': 4,
              'user': {'name': 'Ayşe'},
            },
          ],
          'userVotedEntryIds': <String>[],
        }),
      ),
      currentUserIdProvider.overrideWithValue('u1'),
    ];
    await tester.pumpWidget(_app(const DreamContestListPage(), overrides: overrides));
    await tester.pumpAndSettle();
    expect(find.text('Haftanın rüyası'), findsOneWidget);
    expect(find.text('Devam ediyor'), findsOneWidget);

    await tester.pumpWidget(
      _app(const DreamContestDetailPage(contestId: 'c1'), overrides: overrides),
    );
    await tester.pumpAndSettle();
    expect(find.text('Denizin üstünde yürüyordum'), findsOneWidget);
    expect(find.text('Huzur ve özgürlük arayışı'), findsOneWidget);
    expect(find.text('Yorumu gönder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Futbol sayfası maç, puan durumu, gol krallığı', (tester) async {
    _phone(tester);
    final match = FootballMatch.fromJson({
      'id': 1,
      'utcDate': DateTime.now().toUtc().toIso8601String(),
      'status': 'IN_PLAY',
      'homeTeam': {'shortName': 'Galatasaray'},
      'awayTeam': {'shortName': 'Fenerbahçe'},
      'score': {'fullTime': {'home': 1, 'away': 0}},
      'competition': {'localName': 'Süper Lig', 'flag': '🇹🇷'},
    });
    await tester.pumpWidget(
      _app(
        const FootballPage(),
        overrides: [
          footballMatchesProvider.overrideWith((ref, day) async => [match]),
          footballStandingsProvider.overrideWith(
            (ref, code) async => FootballStandingRow.fromStandings([
              {
                'type': 'TOTAL',
                'table': [
                  {
                    'position': 1,
                    'team': {'shortName': 'Arsenal'},
                    'points': 16,
                  },
                ],
              },
            ]),
          ),
          footballScorersProvider.overrideWith(
            (ref, code) async => [
              FootballScorer.fromJson({
                'player': {'name': 'Haaland'},
                'team': {'name': 'Man City'},
                'goals': 9,
              }),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Galatasaray'), findsOneWidget);
    expect(find.text('1 - 0'), findsOneWidget);
    expect(find.text('CANLI'), findsOneWidget);

    await tester.tap(find.text('Puan durumu'));
    await tester.pumpAndSettle();
    expect(find.text('Arsenal'), findsOneWidget);

    await tester.tap(find.text('Gol krallığı'));
    await tester.pumpAndSettle();
    expect(find.text('Haaland'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burç uyumu sayfası açılır', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const CompatibilityPage()));
    await tester.pumpAndSettle();
    expect(find.text('Uyumu hesapla'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ses ayarları kaydedilir', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const VoiceAudioSettingsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Ses kalitesi'), findsOneWidget);
    await tester.tap(find.text('Müzik / Karaoke'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('voice_audio.quality'), 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ajans haftalık görev kartı', (tester) async {
    _phone(tester);
    final tasks = AgencyWeeklyTasks.fromJson({
      'currentTask': {
        'earningsTarget': 500,
        'earningsActual': 250,
        'newUsersTarget': 2,
        'newUsersActual': 1,
        'activeUsersTarget': 4,
        'activeUsersActual': 4,
        'completionPercent': 65,
      },
    });
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AgencyWeeklyTaskCard(task: tasks.current!, jetonLabel: 'Jeton'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('%65'), findsOneWidget);
    expect(find.text('250 / 500 Jeton'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
