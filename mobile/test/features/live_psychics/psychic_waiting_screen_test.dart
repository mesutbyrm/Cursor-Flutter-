import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:canlifal_social/core/economy/domain/currency_branding_snapshot.dart';
import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';
import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/screens/psychic_waiting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_live_psychics_repository.dart';
import '../../helpers/economy_test_scope.dart';

class _StubWallet extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() async => WalletBalances.empty;
  @override
  Future<WalletBalances> refresh({bool force = false}) async =>
      WalletBalances.empty;
}

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
        wrapEconomyScope(
          MaterialApp.router(routerConfig: router),
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
            goRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lütfen Bekleyiniz...'), findsOneWidget);
      expect(find.text('Ayşe Falcı'), findsOneWidget);
    });
  });

  group('PsychicWaitingController — ağ dayanıklılığı', () {
    const session = PsychicSessionEntity(
      sessionId: 'sess_net',
      psychic: PsychicEntity(id: 'teller_net', name: 'Falcı', isOnline: true),
      durationMinutes: 10,
      totalJeton: 100,
    );

    ProviderContainer containerFor(FakeLivePsychicsRepository repo) {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/canli-falcilar/:id',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );
      final c = ProviderContainer(
        overrides: [
          currencyBrandingProvider.overrideWith(
            (ref) async => CurrencyBrandingSnapshot.defaults,
          ),
          walletBalancesProvider.overrideWith(_StubWallet.new),
          livePsychicsRepositoryProvider.overrideWithValue(repo),
          goRouterProvider.overrideWithValue(router),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sunucu seansı bilmiyorsa 3 turda bekleme biter (3 dk beklemez)', () async {
      final c = containerFor(FakeLivePsychicsRepository()); // notFound
      final sub = c.listen(psychicWaitingControllerProvider(session), (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      expect(
        c.read(psychicWaitingControllerProvider(session)).phase,
        PsychicWaitingPhase.rejected,
      );
    });

    test('ağ hatasında bekleme sürer (iptal/ret sanılmaz)', () async {
      final c = containerFor(FakeLivePsychicsRepository(lookupsFail: true));
      final sub = c.listen(psychicWaitingControllerProvider(session), (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      final st = c.read(psychicWaitingControllerProvider(session));
      expect(st.phase, PsychicWaitingPhase.waiting);
      expect(st.closed, isFalse);
    });
  });
}
