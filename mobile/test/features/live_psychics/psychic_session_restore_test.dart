import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_session_route.dart';
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

  group('PsychicSessionRestoreGate', () {
    testWidgets('loads waiting session from store when route extra is null',
        (tester) async {
      const session = PsychicSessionEntity(
        sessionId: 'sess_restore',
        psychic: PsychicEntity(
          id: 'teller_restore',
          name: 'Restore Falcı',
          isOnline: true,
        ),
        durationMinutes: 10,
        totalJeton: 100,
      );
      await PsychicSessionStore.save(session);

      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: 'sess_restore',
          status: PsychicSessionStatus.pending,
          isClient: true,
        ),
      );
      final router = GoRouter(
        initialLocation: '/canli-falcilar/teller_restore/waiting',
        routes: [
          GoRoute(
            path: '/canli-falcilar/:id/waiting',
            builder: (_, state) => PsychicWaitingRoute(
              psychicId: state.pathParameters['id'] ?? '',
              session: state.extra as PsychicSessionEntity?,
            ),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(480, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
      expect(find.text('Restore Falcı'), findsOneWidget);
    });

    testWidgets('uses route extra without reading store first', (tester) async {
      const session = PsychicSessionEntity(
        sessionId: 'sess_direct',
        psychic: PsychicEntity(
          id: 'teller_direct',
          name: 'Direct Falcı',
          isOnline: true,
        ),
        durationMinutes: 10,
        totalJeton: 50,
      );

      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: 'sess_direct',
          status: PsychicSessionStatus.pending,
          isClient: true,
        ),
      );
      final router = GoRouter(
        initialLocation: '/canli-falcilar/teller_direct/waiting',
        routes: [
          GoRoute(
            path: '/canli-falcilar/:id/waiting',
            builder: (_, state) => PsychicWaitingRoute(
              psychicId: state.pathParameters['id'] ?? '',
              session: session,
            ),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(480, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      expect(find.text('Direct Falcı'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
