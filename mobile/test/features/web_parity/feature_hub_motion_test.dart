import 'package:canlifal_social/core/design_system/cds_fx.dart';
import 'package:canlifal_social/core/motion/canlifal_motion.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/web_parity/domain/feature_catalog.dart';
import 'package:canlifal_social/features/web_parity/presentation/pages/feature_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Fx extends CdsFxNotifier {
  _Fx(this.performance);
  final bool performance;
  @override
  CdsFxState build() => CdsFxState(
        performanceMode: performance,
        sessionEntranceShown: false,
      );
}

Widget _app({
  bool performance = false,
  bool disableAnimations = false,
  GoRouter? router,
}) {
  Widget scope(Widget child) => ProviderScope(
        overrides: [cdsFxProvider.overrideWith(() => _Fx(performance))],
        child: child,
      );
  Widget wrapMq(BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      );
  if (router != null) {
    return scope(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        builder: wrapMq,
      ),
    );
  }
  return scope(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: wrapMq,
      home: const FeatureHubPage(),
    ),
  );
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(FeatureHubPage.resetEntranceForTest);

  testWidgets('ilk açılış: kademeli giriş oynar ve tamamen biter',
      (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app());
    expect(find.byType(Animate), findsWidgets);
    await tester.pumpAndSettle();
    for (final f in kFeatureCatalog) {
      expect(find.text(f.label), findsOneWidget, reason: f.label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('aynı oturumda ikinci açılışta giriş animasyonu tekrar oynamaz',
      (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('sistem «hareketi azalt» açıkken animasyon yok, basınç ölçeği 1',
      (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app(disableAnimations: true));
    expect(find.byType(Animate), findsNothing);
    final press = tester.widget<CanlifalPressable>(
      find.byType(CanlifalPressable).first,
    );
    expect(press.scale, 1);
  });

  testWidgets('performans modu açıkken animasyon yok', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app(performance: true));
    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('animasyon sürerken sayfa kapanırsa hata/sızıntı yok',
      (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('kutuya dokunmak ilgili sayfaya gider', (tester) async {
    _tallView(tester);
    final first = kFeatureCatalog.first;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const FeatureHubPage()),
        GoRoute(
          path: first.route,
          builder: (_, _) => const Scaffold(body: Text('hedef-sayfa')),
        ),
      ],
    );
    await tester.pumpWidget(_app(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text(first.label));
    await tester.pumpAndSettle();
    expect(find.text('hedef-sayfa'), findsOneWidget);
  });

  testWidgets('CanlifalMotionPolicy: iki kaynaktan biri yeterli',
      (tester) async {
    late bool a, b, c;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (ctx) {
            a = CanlifalMotionPolicy.reduced(ctx, performanceMode: false);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (ctx) {
            b = CanlifalMotionPolicy.reduced(ctx, performanceMode: true);
            c = CanlifalMotionPolicy.reduced(ctx, performanceMode: false);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(a, isTrue);
    expect(b, isTrue);
    expect(c, isFalse);
  });
}
