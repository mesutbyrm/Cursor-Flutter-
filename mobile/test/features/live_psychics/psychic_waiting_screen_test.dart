import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_waiting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_live_psychics_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PsychicWaitingState', () {
    test('remainingLabel formats mm:ss', () {
      const state = PsychicWaitingState(remainingSeconds: 125);
      expect(state.remainingLabel, '2:05');
      expect(state.statusLabel, 'REQUESTING');
    });

    test('phase labels map correctly', () {
      expect(
        const PsychicWaitingState(phase: PsychicWaitingPhase.accepted).statusLabel,
        'ACCEPTING',
      );
      expect(
        const PsychicWaitingState(phase: PsychicWaitingPhase.expired).statusLabel,
        'TIMEOUT',
      );
    });
  });

  group('PsychicWaitingScreen', () {
    testWidgets('shows waiting copy while session is pending', (tester) async {
      const session = PsychicSessionEntity(
        sessionId: 'sess_wait_ui',
        psychic: PsychicEntity(
          id: 'teller_wait',
          name: 'Ayşe Falcı',
          isOnline: true,
        ),
        durationMinutes: 10,
        totalJeton: 100,
      );
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: 'sess_wait_ui',
          status: PsychicSessionStatus.pending,
          isClient: true,
        ),
      );
      final router = GoRouter(
        initialLocation: '/waiting',
        routes: [
          GoRoute(
            path: '/waiting',
            builder: (_, _) => const PsychicWaitingScreen(session: session),
          ),
          GoRoute(
            path: '/canli-falcilar/:id',
            builder: (_, _) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/canli-falcilar/:id/ad-transition',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
            goRouterProvider.overrideWithValue(router),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lütfen Bekleyiniz...'), findsOneWidget);
      expect(find.text('Ayşe Falcı'), findsOneWidget);
    });
  });
}
