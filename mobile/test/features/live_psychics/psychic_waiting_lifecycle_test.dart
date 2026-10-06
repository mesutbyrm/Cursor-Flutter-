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
  int inFlight = 0;
  int maxInFlight = 0;
  Duration latency = Duration.zero;

  @override
  Future<PsychicStatusLookup> fetchSessionStatusLookup(String sessionId) async {
    statusCalls++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      if (latency > Duration.zero) await Future<void>.delayed(latency);
      return await super.fetchSessionStatusLookup(sessionId);
    } finally {
      inFlight--;
    }
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

  Future<void> mount(WidgetTester tester, _CountingRepo repo) async {
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
  }

  testWidgets('bekleme: yavaş ağda (5 sn) yoklama istek biriktirmez',
      (tester) async {
    final repo = _CountingRepo()..latency = const Duration(seconds: 5);
    await tester.binding.setSurfaceSize(const Size(480, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, repo);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    debugPrint('METRIC bekleme-yavaş-ağ | istek=${repo.statusCalls} '
        '| maxEşzamanlı=${repo.maxInFlight}');
    expect(repo.maxInFlight, lessThanOrEqualTo(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bekleme: istek havadayken ekran kapanırsa (geri tuşu) hata yok, sızıntı yok',
      (tester) async {
    final repo = _CountingRepo()..latency = const Duration(seconds: 3);
    await tester.binding.setSurfaceSize(const Size(480, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, repo);
    await tester.pump(const Duration(milliseconds: 1500)); // istek havada
    expect(repo.inFlight, 1);
    await tester.pumpWidget(const SizedBox()); // geri tuşu / ekran kapandı
    await tester.pump(const Duration(seconds: 4)); // yanıt dispose sonrası gelir
    final after = repo.statusCalls;
    await tester.pump(const Duration(seconds: 30));
    debugPrint('METRIC bekleme-geri-tuşu | istek=${repo.statusCalls} '
        '| sızan=${repo.statusCalls - after}');
    expect(tester.takeException(), isNull,
        reason: 'dispose sonrası await tamamlanınca state güncellemesi hata verdi');
    expect(repo.statusCalls, after);
  });

  testWidgets('bekleme: sunucu hiç yanıt vermezse yoklama yığılmaz',
      (tester) async {
    final repo = _CountingRepo()..latency = const Duration(hours: 1);
    await tester.binding.setSurfaceSize(const Size(480, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, repo);
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    debugPrint('METRIC bekleme-hang | istek=${repo.statusCalls} '
        '| maxEşzamanlı=${repo.maxInFlight}');
    expect(repo.maxInFlight, 1);
    expect(repo.statusCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(hours: 2));
  });
}
