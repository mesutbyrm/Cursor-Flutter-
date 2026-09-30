import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/home/presentation/widgets/approved/bottom_navigation_widget.dart';

void main() {
  late List<String> taps;

  Widget host({
    required ThemeData theme,
    HomeBottomTab active = HomeBottomTab.social,
    double width = 390,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(bottom: 24),
        ),
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: BottomNavigationWidget(
            activeTab: active,
            onHome: () => taps.add('home'),
            onSocial: () => taps.add('social'),
            onLive: () => taps.add('live'),
            onCreate: () => taps.add('create'),
            onFortune: () => taps.add('fortune'),
            onTarot: () => taps.add('tarot'),
            onProfile: () => taps.add('profile'),
          ),
        ),
      ),
    );
  }

  setUp(() => taps = []);

  testWidgets('her sekme kendi geri çağrısını tetikler', (tester) async {
    await tester.pumpWidget(host(theme: AppTheme.dark()));

    await tester.tap(find.text('Ana Sayfa'));
    await tester.tap(find.text('Sosyal'));
    await tester.tap(find.text('Canlı'));
    await tester.tap(find.text('Yükle'));
    await tester.tap(find.text('Fal'));
    await tester.tap(find.text('Tarot'));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(
      taps,
      ['home', 'social', 'live', 'create', 'fortune', 'tarot', 'profile'],
    );
  });

  testWidgets('etkin sekme erişilebilirlikte seçili olarak bildirilir',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(theme: AppTheme.light(), active: HomeBottomTab.fortune),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Fal')),
      matchesSemantics(
        label: 'Fal',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasLongPressAction: false,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Profil')),
      matchesSemantics(
        label: 'Profil',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  for (final theme in {'koyu': AppTheme.dark(), 'açık': AppTheme.light()}.entries) {
    testWidgets('${theme.key} tema: 320px genişlik + büyük yazıda taşma yok',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(theme: theme.value, width: 320, textScale: 1.6),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tarot'), findsOneWidget);
    });
  }

  testWidgets('güvenli alan (gesture bar) kadar alt boşluk bırakır',
      (tester) async {
    await tester.pumpWidget(host(theme: AppTheme.dark()));
    final size = tester.getSize(find.byType(BottomNavigationWidget));
    expect(size.height, BottomNavigationWidget.barHeight + 24);
  });
}
