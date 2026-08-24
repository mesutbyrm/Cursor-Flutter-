import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_live_psychics_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PsychicFlow resumeFromPush', () {
    testWidgets('client active session opens ad-transition', (tester) async {
      final navigations = <String>[];
      const tellerId = 'teller_profile_a';
      const sessionId = 'sess_client_1';
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: sessionId,
          status: PsychicSessionStatus.active,
          isClient: true,
          tellerProfileId: tellerId,
          durationMinutes: 10,
        ),
        roomResult: PsychicRoomEntity(
          sessionId: sessionId,
          status: PsychicSessionStatus.active,
          maxMinutes: 10,
          timerStarted: true,
          roomId: 'room_abc',
          clientId: 'client_user',
        ),
        psychicResult: const PsychicEntity(
          id: tellerId,
          name: 'Test Falcı',
          isOnline: true,
        ),
      );
      final router = _psychicTestRouter(navigations);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await PsychicFlow.resumeFromPush(
        router: router,
        repo: repo,
        sessionId: sessionId,
        tellerId: tellerId,
      );
      await tester.pumpAndSettle();

      expect(navigations, contains('/canli-falcilar/$tellerId/ad-transition'));
      final stored = await PsychicSessionStore.load();
      expect(stored?.isClient, isTrue);
      expect(stored?.sessionId, sessionId);
    });

    testWidgets('skips teller-side status', (tester) async {
      final navigations = <String>[];
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: 'sess_teller',
          status: PsychicSessionStatus.active,
          isClient: false,
        ),
      );
      final router = _psychicTestRouter(navigations);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await PsychicFlow.resumeFromPush(
        router: router,
        repo: repo,
        sessionId: 'sess_teller',
      );
      await tester.pumpAndSettle();

      expect(navigations, isEmpty);
    });

    testWidgets('waiting route replaces with ad-transition', (tester) async {
      final navigations = <String>[];
      const tellerId = 'teller_b';
      const sessionId = 'sess_wait';
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: sessionId,
          status: PsychicSessionStatus.active,
          isClient: true,
          tellerProfileId: tellerId,
        ),
        psychicResult: const PsychicEntity(id: tellerId, name: 'Falcı B'),
      );
      final router = GoRouter(
        initialLocation: '/canli-falcilar/$tellerId/waiting',
        routes: [
          GoRoute(
            path: '/canli-falcilar/:id/waiting',
            builder: (_, _) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/canli-falcilar/:id/ad-transition',
            builder: (context, state) {
              navigations.add(state.uri.path);
              return const SizedBox.shrink();
            },
          ),
          GoRoute(
            path: '/canli-falcilar/:id/session',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await PsychicFlow.resumeFromPush(
        router: router,
        repo: repo,
        sessionId: sessionId,
        tellerId: tellerId,
      );
      await tester.pumpAndSettle();

      expect(navigations, contains('/canli-falcilar/$tellerId/ad-transition'));
    });
  });

  group('PsychicFlow openTellerSessionFromPush', () {
    testWidgets('teller active session opens session screen', (tester) async {
      final navigations = <String>[];
      const tellerId = 'teller_profile_c';
      const sessionId = 'sess_teller_active';
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: sessionId,
          status: PsychicSessionStatus.active,
          isClient: false,
          tellerProfileId: tellerId,
          tellerUserId: 'user_teller_c',
        ),
        roomResult: PsychicRoomEntity(
          sessionId: sessionId,
          status: PsychicSessionStatus.active,
          maxMinutes: 15,
          timerStarted: true,
          roomId: 'room_teller',
          clientId: 'client_xyz',
        ),
        psychicResult: const PsychicEntity(
          id: tellerId,
          name: 'Falcı C',
          userId: 'user_teller_c',
        ),
      );
      final router = _psychicTestRouter(navigations);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await PsychicFlow.openTellerSessionFromPush(
        router: router,
        repo: repo,
        sessionId: sessionId,
        tellerId: tellerId,
      );
      await tester.pumpAndSettle();

      expect(navigations, contains('/canli-falcilar/$tellerId/session'));
      final stored = await PsychicSessionStore.load();
      expect(stored?.isClient, isFalse);
      expect(stored?.sessionId, sessionId);
    });

    testWidgets('does not navigate when already on session route', (tester) async {
      final navigations = <String>[];
      const tellerId = 'teller_d';
      final repo = FakeLivePsychicsRepository(
        statusResult: const PsychicSessionStatusResult(
          sessionId: 'sess_on_session',
          status: PsychicSessionStatus.active,
          isClient: false,
          tellerProfileId: tellerId,
        ),
      );
      final router = GoRouter(
        initialLocation: '/canli-falcilar/$tellerId/session',
        routes: [
          GoRoute(
            path: '/canli-falcilar/:id/session',
            builder: (_, _) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/canli-falcilar/:id/ad-transition',
            builder: (context, state) {
              navigations.add(state.uri.path);
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await PsychicFlow.openTellerSessionFromPush(
        router: router,
        repo: repo,
        sessionId: 'sess_on_session',
        tellerId: tellerId,
      );
      await tester.pumpAndSettle();

      expect(navigations, isEmpty);
    });
  });
}

GoRouter _psychicTestRouter(List<String> navigations) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/canli-falcilar/:id/waiting',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/canli-falcilar/:id/ad-transition',
        builder: (context, state) {
          navigations.add(state.uri.path);
          return const SizedBox.shrink();
        },
      ),
      GoRoute(
        path: '/canli-falcilar/:id/session',
        builder: (context, state) {
          navigations.add(state.uri.path);
          return const SizedBox.shrink();
        },
      ),
    ],
  );
}
