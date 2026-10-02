import 'package:canlifal_social/core/navigation/app_back_policy.dart';
import 'package:canlifal_social/core/navigation/app_back_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppBackPolicy', () {
    test('fallbackFor: ana sayfa null (çıkış onayı), sekmeler → ana sayfa', () {
      expect(AppBackPolicy.fallbackFor('/feed'), isNull);
      expect(AppBackPolicy.fallbackFor('/'), isNull);
      expect(AppBackPolicy.fallbackFor('/social'), '/feed');
      expect(AppBackPolicy.fallbackFor('/voice-rooms'), '/feed');
    });

    test('fallbackFor: derin yol → bölüm kökü; bilinmeyen → ana sayfa', () {
      expect(AppBackPolicy.fallbackFor('/fortune/bana-ozel'), '/fortune');
      expect(AppBackPolicy.fallbackFor('/profile/edit?x=1'), '/profile');
      expect(AppBackPolicy.fallbackFor('/jeton-store'), '/feed');
      expect(AppBackPolicy.fallbackFor('/wallet/history'), '/feed');
    });

    test('selfHandlesBack: oda/yayın/falcı oturumu ve sekme kökleri', () {
      expect(AppBackPolicy.selfHandlesBack('/voice-room/abc'), isTrue);
      expect(AppBackPolicy.selfHandlesBack('/voice-room/abc/pk'), isTrue);
      expect(AppBackPolicy.selfHandlesBack('/live/room'), isTrue);
      expect(AppBackPolicy.selfHandlesBack('/canli-falcilar/p1/session'), isTrue);
      expect(AppBackPolicy.selfHandlesBack('/feed'), isTrue);
      expect(AppBackPolicy.selfHandlesBack('/jeton-store'), isFalse);
    });
  });

  group('AppBackScope', () {
    GoRouter router(String initial) => GoRouter(
          initialLocation: initial,
          routes: [
            GoRoute(
              path: '/feed',
              builder: (_, __) => const Scaffold(body: Text('FEED')),
            ),
            GoRoute(
              path: '/jeton-store',
              builder: (_, __) => const AppBackScope(
                child: Scaffold(body: Text('STORE')),
              ),
            ),
            GoRoute(
              path: '/fortune/bana-ozel',
              builder: (_, __) => const AppBackScope(
                child: Scaffold(body: Text('BANA')),
              ),
            ),
            GoRoute(
              path: '/fortune',
              builder: (_, __) => const Scaffold(body: Text('FORTUNE')),
            ),
          ],
        );

    testWidgets('go() ile gelinen düz sayfada geri → ana sayfa (uygulama kapanmaz)',
        (tester) async {
      final r = router('/jeton-store');
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();
      expect(find.text('STORE'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue, reason: 'geri tuşu işlendi, sistem kapatmadı');
      expect(find.text('FEED'), findsOneWidget);
    });

    testWidgets('derin yol → bölüm köküne döner', (tester) async {
      final r = router('/fortune/bana-ozel');
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('FORTUNE'), findsOneWidget);
    });

    testWidgets('push() ile gelinen sayfada geri → önceki sayfa', (tester) async {
      final r = router('/feed');
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();
      r.push('/jeton-store');
      await tester.pumpAndSettle();
      expect(find.text('STORE'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('FEED'), findsOneWidget);
    });
  });
}
