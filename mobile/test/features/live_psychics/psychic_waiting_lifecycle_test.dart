import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_session_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/economy_test_scope.dart';
import 'support/fake_live_psychics_repository.dart';

class _CountingRepo extends FakeLivePsychicsRepository {
  _CountingRepo()
      : super(
          statusResult: const PsychicSessionStatusResult(
            sessionId: 'sess_leak',
            status: PsychicSessionStatus.pending,
            isClient: true,
          ),
        );

  int statusCalls = 0;

  @override
  Future<PsychicStatusLookup> fetchSessionStatusLookup(String sessionId) {
    statusCalls++;
    return super.fetchSessionStatusLookup(sessionId);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const session = PsychicSessionEntity(
    sessionId: 'sess_leak',
    psychic: PsychicEntity(id: 'teller_leak', name: 'Leak Falcı', isOnline: true),
    durationMinutes: 10,
    totalJeton: 100,
  );

  testWidgets('bekleme ekranına 10 kez girip çıkınca zamanlayıcı/yoklama sızmaz',
      (tester) async {
    final repo = _CountingRepo();
    await tester.binding.setSurfaceSize(const Size(480, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (var i = 0; i < 10; i++) {
      final router = GoRouter(
        initialLocation: '/canli-falcilar/teller_leak/waiting',
        routes: [
          GoRoute(
            path: '/canli-falcilar/:id/waiting',
            builder: (_, state) => PsychicWaitingRoute(
              psychicId: 'teller_leak',
              session: session,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        wrapEconomyScope(
          MaterialApp.router(routerConfig: router),
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
            goRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // Ekranı kapat (autoDispose controller kendini temizlemeli).
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    final afterAll = repo.statusCalls;
    expect(afterAll, greaterThan(0), reason: 'yoklama çalışmalıydı');

    // Tüm ekranlar kapalı: zaman ilerlese de hiçbir yoklama devam etmemeli.
    await tester.pump(const Duration(seconds: 30));
    expect(repo.statusCalls, afterAll,
        reason: 'kapalı ekranlardan yoklama sızıyor (timer/dispose sorunu)');
  });
}
