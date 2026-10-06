import 'dart:async';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_booking_feedback_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/economy_test_scope.dart';
import 'support/fake_live_psychics_repository.dart';

class _GatedRepo extends FakeLivePsychicsRepository {
  int createCalls = 0;
  Completer<PsychicSessionCreateResult?> gate = Completer();
  Object? createError;

  @override
  Future<PsychicSessionCreateResult?> createSession({
    required String tellerId,
    required int durationMinutes,
    required String fortuneType,
  }) {
    createCalls++;
    final err = createError;
    if (err != null) return Future.error(err);
    return gate.future;
  }
}

const _psychic = PsychicEntity(id: 'teller_1', name: 'Test Falcı', isOnline: true);
const _created = PsychicSessionCreateResult(
  sessionId: 'sess_1',
  status: PsychicSessionStatus.pending,
);

void main() {
  late _GatedRepo repo;
  late GoRouter router;
  late WidgetRef ref;
  late ProviderContainer container;
  var waitingPushes = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _GatedRepo();
    waitingPushes = 0;
    router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/canli-falcilar/:id/waiting',
        builder: (_, __) {
          waitingPushes++;
          return const SizedBox();
        },
      ),
    ]);
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapEconomyScope(
        Consumer(
          builder: (context, r, _) {
            ref = r;
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(routerConfig: router);
          },
        ),
        overrides: [
          livePsychicsRepositoryProvider.overrideWithValue(repo),
          goRouterProvider.overrideWithValue(router),
        ],
      ),
    );
    await tester.pump();
  }

  Future<PsychicSessionEntity?> book() => PsychicFlow.bookAndOpenWaiting(
        ref: ref,
        router: router,
        psychic: _psychic,
        durationMinutes: 10,
        totalJeton: 100,
      );

  testWidgets('çok hızlı iki istek → tek createSession, ikinci reddedilir',
      (tester) async {
    await pumpHost(tester);
    final first = book();
    await tester.pump(const Duration(milliseconds: 10));
    expect(PsychicFlow.isBookingInFlight, isTrue);

    final second = await settle(tester, book());
    expect(second, isNull);
    expect(
      container.read(psychicBookingFeedbackProvider),
      contains('işleniyor'),
    );

    repo.gate.complete(_created);
    final session = await settle(tester, first);
    await tester.pump();
    await tester.pump();

    expect(session?.sessionId, 'sess_1');
    expect(repo.createCalls, 1);
    expect(waitingPushes, greaterThanOrEqualTo(1));
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('istek sürerken ekran kapanırsa crash yok, seans yine açılır',
      (tester) async {
    await pumpHost(tester);
    final first = book();
    await tester.pump(const Duration(milliseconds: 10));

    // Ekran (Consumer) söküldü — `ref` artık geçersiz.
    await tester.pumpWidget(const SizedBox());
    repo.gate.complete(_created);

    final session = await settle(tester, first); // StateError fırlatmamalı
    expect(session?.sessionId, 'sess_1');
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('sunucu yanıt vermezse sonsuz yükleme kalmaz', (tester) async {
    await pumpHost(tester);
    final f = book(); // gate hiç tamamlanmıyor
    await tester.pump(const Duration(seconds: 26));
    final r = await settle(tester, f);
    expect(r, isNull);
    expect(
      container.read(psychicBookingFeedbackProvider),
      contains('zaman aşımına'),
    );
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('hata sonrası kapı açılır ve tekrar denenebilir', (tester) async {
    await pumpHost(tester);
    repo.createError = StateError('sunucu hatası');
    expect(await settle(tester, book()), isNull);
    expect(PsychicFlow.isBookingInFlight, isFalse);
    expect(container.read(psychicBookingFeedbackProvider), isNotNull);

    repo.createError = null;
    repo.gate.complete(_created);
    final retry = await settle(tester, book());
    expect(retry?.sessionId, 'sess_1');
    expect(repo.createCalls, 2);
  });
}

/// FakeAsync altında gerçek async iş (SharedPreferences) ilerlesin diye
/// tamamlanana kadar kare pompalar.
Future<T> settle<T>(WidgetTester tester, Future<T> f, {int maxPumps = 60}) async {
  var done = false;
  late T value;
  Object? error;
  StackTrace? stack;
  unawaited(f.then((v) {
    value = v;
    done = true;
  }, onError: (Object e, StackTrace s) {
    error = e;
    stack = s;
    done = true;
  }));
  for (var i = 0; i < maxPumps && !done; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (!done) fail('future tamamlanmadı');
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return value;
}
