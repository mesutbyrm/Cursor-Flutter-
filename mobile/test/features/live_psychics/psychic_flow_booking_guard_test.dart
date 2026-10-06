import 'dart:async';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/core/diagnostics/cf_trace.dart';
import 'package:dio/dio.dart';
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

  String traceLine(String scenario, Stopwatch sw) {
    final t = CfTrace.recent.isEmpty ? null : CfTrace.recent.first;
    return 'METRIC $scenario | süre=${sw.elapsedMilliseconds}ms(gerçek) '
        '| traceId=${t?.traceId} | toplam=${t?.totalMs}ms '
        '| adımlar=${t?.steps.map((e) => '${e.name}:${e.ms}').join(',')} '
        '| createSession=${repo.createCalls}';
  }

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

    final sw0 = Stopwatch()..start();
    final session = await settle(tester, first); // StateError fırlatmamalı
    debugPrint(traceLine('T3-istek-sırasında-geri', sw0));
    expect(session?.sessionId, 'sess_1');
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('sunucu yanıt vermezse sonsuz yükleme kalmaz', (tester) async {
    await pumpHost(tester);
    final f = book(); // gate hiç tamamlanmıyor
    await tester.pump(const Duration(seconds: 26));
    final sw1 = Stopwatch()..start();
    final r = await settle(tester, f);
    debugPrint('${traceLine('T6-api-timeout(25sn+)', sw1)} | mesaj=${container.read(psychicBookingFeedbackProvider)}');
    expect(r, isNull);
    expect(
      container.read(psychicBookingFeedbackProvider),
      contains('zaman aşımına'),
    );
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('T1 tek tık → 1 istek, seans açılır, kapı açılır', (tester) async {
    await pumpHost(tester);
    final sw = Stopwatch()..start();
    final f = book();
    repo.gate.complete(_created);
    final r = await settle(tester, f);
    debugPrint(traceLine('T1-tek-tık', sw));
    expect(r?.sessionId, 'sess_1');
    expect(repo.createCalls, 1);
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('T2 10 kez hızlı tıklama → yalnız 1 istek', (tester) async {
    await pumpHost(tester);
    final sw = Stopwatch()..start();
    final first = book();
    await tester.pump(const Duration(milliseconds: 5));
    var rejected = 0;
    for (var i = 0; i < 9; i++) {
      final r = await settle(tester, book());
      if (r == null) rejected++;
    }
    repo.gate.complete(_created);
    final r1 = await settle(tester, first);
    debugPrint('${traceLine('T2-10x-tık', sw)} | reddedilen=$rejected');
    expect(r1?.sessionId, 'sess_1');
    expect(rejected, 9);
    expect(repo.createCalls, 1);
    expect(waitingPushes, greaterThanOrEqualTo(1));
  });

  testWidgets('T4 yavaş internet (8 sn) → UI kilitlenmez, istek tamamlanır',
      (tester) async {
    await pumpHost(tester);
    final sw = Stopwatch()..start();
    final f = book();
    var worstPump = 0;
    final pumpWatch = Stopwatch();
    for (var i = 0; i < 80; i++) {
      pumpWatch
        ..reset()
        ..start();
      await tester.pump(const Duration(milliseconds: 100));
      pumpWatch.stop();
      if (pumpWatch.elapsedMilliseconds > worstPump) {
        worstPump = pumpWatch.elapsedMilliseconds;
      }
    }
    expect(PsychicFlow.isBookingInFlight, isTrue);
    repo.gate.complete(_created);
    final r = await settle(tester, f);
    debugPrint('${traceLine('T4-yavaş-internet', sw)} | enUzunKareMs=$worstPump');
    expect(r?.sessionId, 'sess_1');
    expect(repo.createCalls, 1);
    expect(worstPump, lessThan(200), reason: 'bekleme sırasında UI bloklandı');
  });

  testWidgets('T5 internet kesik → anlaşılır hata, yükleme kapanır, tekrar denenir',
      (tester) async {
    await pumpHost(tester);
    final sw = Stopwatch()..start();
    repo.createError = DioException(
      requestOptions: RequestOptions(path: '/api/fortune-tellers/sessions'),
      type: DioExceptionType.connectionError,
    );
    final r = await settle(tester, book());
    debugPrint('${traceLine('T5-internet-kesik', sw)} '
        '| mesaj=${container.read(psychicBookingFeedbackProvider)}');
    expect(r, isNull);
    expect(container.read(psychicBookingFeedbackProvider), isNotNull);
    expect(PsychicFlow.isBookingInFlight, isFalse);
  });

  testWidgets('T10 aynı falcıya tekrar istek → 2. istek ancak 1. bitince', (tester) async {
    await pumpHost(tester);
    final sw = Stopwatch()..start();
    repo.gate.complete(_created);
    final a = await settle(tester, book());
    repo.gate = Completer();
    final f = book();
    repo.gate.complete(_created);
    final b = await settle(tester, f);
    debugPrint(traceLine('T10-aynı-falcı-tekrar', sw));
    expect(a?.sessionId, 'sess_1');
    expect(b?.sessionId, 'sess_1');
    expect(repo.createCalls, 2);
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
