import 'package:animations/animations.dart';
import 'package:canlifal_social/core/design_system/cds_fx.dart';
import 'package:canlifal_social/core/navigation/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Fx extends CdsFxNotifier {
  _Fx(this.performance);
  final bool performance;
  @override
  CdsFxState build() =>
      CdsFxState(performanceMode: performance, sessionEntranceShown: false);
}

Widget _app({bool performance = false, bool disableAnimations = false}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/hedef'),
            child: const Text('aç'),
          ),
        ),
      ),
      GoRoute(
        path: '/hedef',
        pageBuilder: (context, state) => AppPageTransitions.premiumAxis(
          key: state.pageKey,
          child: const Scaffold(body: Text('hedef-sayfa')),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [cdsFxProvider.overrideWith(() => _Fx(performance))],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('normal modda shared-axis geçişi oynar ve biter', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SharedAxisTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('hedef-sayfa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«hareketi azalt» açıkken geçiş animasyonu yok', (tester) async {
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SharedAxisTransition), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('hedef-sayfa'), findsOneWidget);
  });

  testWidgets('performans modunda geçiş animasyonu yok', (tester) async {
    await tester.pumpWidget(_app(performance: true));
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SharedAxisTransition), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('hedef-sayfa'), findsOneWidget);
  });

  testWidgets('geri dönüş de sorunsuz biter', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text('hedef-sayfa'));
    GoRouter.of(ctx).pop();
    await tester.pumpAndSettle();
    expect(find.text('aç'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
