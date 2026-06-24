import 'dart:async';

import 'package:canlifal_social/app/app.dart';
import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/games/domain/game_center_models.dart';
import 'package:canlifal_social/features/games/presentation/game_center/providers/game_center_providers.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/membership/presentation/pages/premium_membership_page.dart';
import 'package:canlifal_social/features/messages/presentation/providers/messages_providers.dart';
import 'package:canlifal_social/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/shorts/domain/entities/short_video_entity.dart';
import 'package:canlifal_social/features/shorts/presentation/providers/shorts_providers.dart';
import 'package:canlifal_social/features/social/presentation/providers/social_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tam uygulama gri ekran teşhisi — üretim API çağrısı yapmaz (provider override).
///
/// Varsayılan `flutter test` bu dosyayı atlar. Manuel çalıştırma:
/// `flutter test test/gray_screen_diagnostic_test.dart --dart-define=GRAY_SCREEN_DIAG=true`
const _runGrayScreenDiag =
    bool.fromEnvironment('GRAY_SCREEN_DIAG', defaultValue: false);

const _skipReason =
    'Manuel teşhis: flutter test test/gray_screen_diagnostic_test.dart --dart-define=GRAY_SCREEN_DIAG=true';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final capturedErrors = <FlutterErrorDetails>[];

  setUp(() {
    capturedErrors.clear();
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      capturedErrors.add(details);
      debugPrint('CAPTURED_ERROR: ${details.exception}');
      debugPrint('CAPTURED_STACK: ${details.stack}');
      original?.call(details);
    };
  });

  testWidgets(
    'soğuk açılış oturumlu — exception ve barrier taraması',
    (tester) async {
      const user = UserEntity(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _diagnosticOverrides(
            authControllerProvider.overrideWith(() => _FakeAuthController(user)),
          ),
          child: const CanlifalApp(),
        ),
      );

      await _pumpAndScan(tester, capturedErrors, label: 'authed-cold-start');
      await _disposeApp(tester);
    },
    skip: !_runGrayScreenDiag,
  );

  testWidgets(
    'giriş geçişi — exception ve barrier taraması',
    (tester) async {
      final controller = _TransitionAuthController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: _diagnosticOverrides(
            authControllerProvider.overrideWith(() => controller),
          ),
          child: const CanlifalApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _scan(tester, capturedErrors, label: 'before-login');

      controller.completeLogin(
        const UserEntity(id: 'u1', username: 'testuser', displayName: 'Test'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      await _pumpAndScan(tester, capturedErrors, label: 'after-login');
      await _disposeApp(tester);
    },
    skip: !_runGrayScreenDiag,
  );
}

List<Override> _diagnosticOverrides(Override authOverride) {
  return [
    authOverride,
    cookieJarProvider.overrideWithValue(PersistCookieJar()),
    walletBalancesProvider.overrideWith(_StubWalletBalancesNotifier.new),
    gameCenterJetonProvider.overrideWith((ref) async => 0),
    gameCenterLeaderboardProvider.overrideWith((ref, period) async => []),
    homeBannersProvider.overrideWith((ref) async => []),
    homeFortuneCardsProvider.overrideWith((ref) async => []),
    homeAdvisorsProvider.overrideWith((ref) async => []),
    homeLiveStreamsProvider.overrideWith((ref) async => []),
    homeVoiceRoomsProvider.overrideWith((ref) async => []),
    homeGamesProvider.overrideWith((ref) async => []),
    homeDailyRewardsProvider.overrideWith((ref) async => []),
    homeTrendVideosProvider.overrideWith((ref) async => []),
    notificationsUnreadCountProvider.overrideWith((ref) => 0),
    messagesUnreadCountProvider.overrideWith((ref) => 0),
    membershipCatalogProvider.overrideWith(
      (ref) async => const MembershipCatalogEntity(
        packages: [],
        currentMembership: 'basic',
        jetonBalance: 0,
        cfcBalance: 0,
      ),
    ),
    socialStoryRingsProvider.overrideWith((ref) async => []),
    shortsFeedProvider.overrideWith(_StubShortsFeedNotifier.new),
    psychicsListControllerProvider.overrideWith(_StubPsychicsListController.new),
  ];
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

Future<void> _pumpAndScan(
  WidgetTester tester,
  List<FlutterErrorDetails> errors, {
  required String label,
}) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
  await _scan(tester, errors, label: label);
}

Future<void> _scan(
  WidgetTester tester,
  List<FlutterErrorDetails> errors, {
  required String label,
}) async {
  final barriers = <Element>[];
  final absorb = <Element>[];
  void visit(Element element) {
    final w = element.widget;
    if (w is ModalBarrier) barriers.add(element);
    if (w is AbsorbPointer && w.absorbing) absorb.add(element);
    element.visitChildren(visit);
  }
  tester.binding.rootElement?.visitChildren(visit);

  debugPrint('=== SCAN $label ===');
  debugPrint('Exceptions: ${errors.length}');
  for (final e in errors) {
    debugPrint('EX: ${e.exception}');
    debugPrint('AT: ${e.stack}');
  }
  debugPrint('ModalBarrier count: ${barriers.length}');
  debugPrint('AbsorbPointer count: ${absorb.length}');

  if (errors.isNotEmpty) {
    fail(
      errors.map((e) => '${e.exception}\n${e.stack}').join('\n---\n'),
    );
  }
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final UserEntity _user;
  @override
  Future<UserEntity?> build() async => _user;
}

class _TransitionAuthController extends AuthController {
  final _completer = Completer<UserEntity?>();

  void completeLogin(UserEntity user) {
    if (!_completer.isCompleted) {
      _completer.complete(user);
    }
    state = AsyncValue.data(user);
  }

  @override
  Future<UserEntity?> build() async {
    return _completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }
}

class _StubWalletBalancesNotifier extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() async => WalletBalances.empty;
}

class _StubShortsFeedNotifier extends ShortsFeedNotifier {
  @override
  Future<List<ShortVideoEntity>> build() async => [];
}

class _StubPsychicsListController extends PsychicsListController {
  @override
  Future<PsychicsListState> build() async => const PsychicsListState();
}
