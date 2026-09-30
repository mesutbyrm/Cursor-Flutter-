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
            onVoice: () => taps.add('voice'),
            onCreate: () => taps.add('create'),
            onFortuneTarot: () => taps.add('fortune'),
            onMeet: () => taps.add('meet'),
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
    await tester.tap(find.text('Sesli'));
    await tester.tap(find.text('Yayın'));
    await tester.tap(find.text('Fal&Tarot'));
    await tester.tap(find.text('Tanış'));
    await tester.tap(find.text('Profil'));
    await tester.pump();

    expect(
      taps,
      ['home', 'social', 'voice', 'create', 'fortune', 'meet', 'profile'],
    );
  });

  testWidgets('etkin sekme erişilebilirlikte seçili olarak bildirilir',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(theme: AppTheme.light(), active: HomeBottomTab.fortuneTarot),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Fal&Tarot')),
      matchesSemantics(
        label: 'Fal&Tarot',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasLongPressAction: false,
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
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Tanış'), findsOneWidget);
    });
  }

  testWidgets('güvenli alan (gesture bar) kadar alt boşluk bırakır',
      (tester) async {
    await tester.pumpWidget(host(theme: AppTheme.dark()));
    final size = tester.getSize(find.byType(BottomNavigationWidget));
    expect(size.height, BottomNavigationWidget.barHeight + 24);
  });
}
