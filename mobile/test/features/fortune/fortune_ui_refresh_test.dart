import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/core/l10n/app_localizations_config.dart';
import 'package:canlifal_social/core/motion/canlifal_tarot_flip_card.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/fortune/domain/entities/fortune_reading_section.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_catalog.dart';
import 'package:canlifal_social/features/fortune/presentation/design/fortune_lane_theme.dart';
import 'package:canlifal_social/features/fortune/presentation/pages/fortune_type_intro_page.dart';
import 'package:canlifal_social/features/fortune/presentation/services/fortune_reading_headlines.dart';
import 'package:canlifal_social/features/fortune/presentation/widgets/premium_ai/premium_fortune_open_button.dart';

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

void main() {
  group('FortuneLaneTheme', () {
    Future<Brightness> inner(WidgetTester tester, ThemeData outer) async {
      late Brightness b;
      await tester.pumpWidget(
        MaterialApp(
          theme: outer,
          home: FortuneLaneTheme(
            child: Builder(
              builder: (context) {
                b = Theme.of(context).brightness;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return b;
    }

    testWidgets('açık temada fal bölümü koyu temayı alır', (tester) async {
      expect(await inner(tester, AppTheme.light()), Brightness.dark);
    });

    testWidgets('koyu/AMOLED seçimine dokunmaz', (tester) async {
      late Color bg;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.amoled(),
          home: FortuneLaneTheme(
            child: Builder(
              builder: (context) {
                bg = Theme.of(context).scaffoldBackgroundColor;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(bg, AppTheme.amoled().scaffoldBackgroundColor);
    });
  });

  group('FortuneReadingHeadlines.sectionTitle', () {
    test('bilinen anahtarda sabit etiket', () {
      expect(
        FortuneReadingHeadlines.sectionTitle(
          const FortuneReadingSection(key: 'love', title: 'x', body: 'b'),
        ),
        'Aşk',
      );
    });

    test('bilinmeyen anahtarda sunucu başlığı ("Yorum" değil)', () {
      expect(
        FortuneReadingHeadlines.sectionTitle(
          const FortuneReadingSection(key: 'past', title: 'Geçmiş', body: 'b'),
        ),
        'Geçmiş',
      );
    });

    test('başlık boşsa genel etikete düşer', () {
      expect(
        FortuneReadingHeadlines.sectionTitle(
          const FortuneReadingSection(key: 'past', title: ' ', body: 'b'),
        ),
        'Yorum',
      );
    });
  });

  group('CanlifalTarotFlipCard', () {
    Widget host({
      required bool flipped,
      VoidCallback? onDone,
      bool reduce = false,
    }) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Center(
          child: CanlifalTarotFlipCard(
            flipped: flipped,
            onFlipComplete: onDone,
            front: const ColoredBox(color: Colors.blue, child: Text('ön')),
            back: const ColoredBox(color: Colors.red, child: Text('arka')),
          ),
        ),
      ),
    );

    testWidgets('çevrilince arka yüz görünür ve tamamlanma bildirilir', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(host(flipped: false, onDone: () => done++));
      expect(find.text('ön'), findsOneWidget);

      await tester.pumpWidget(host(flipped: true, onDone: () => done++));
      await tester.pump(const Duration(milliseconds: 200));
      expect(done, 0, reason: 'animasyon sürüyor');
      await tester.pumpAndSettle();
      expect(find.text('arka'), findsOneWidget);
      expect(done, 1);
    });

    testWidgets('"animasyonları azalt" açıkken anında çevrilir', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        host(flipped: false, onDone: () => done++, reduce: true),
      );
      await tester.pumpWidget(
        host(flipped: true, onDone: () => done++, reduce: true),
      );
      await tester.pump();
      expect(find.text('arka'), findsOneWidget);
      expect(done, 1);
    });
  });

  testWidgets(
    'fotoğraf gereken fal türünde "Falını Aç" sessiz kalmaz, fotoğraf sayfasını açar',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final coffee = FortuneCatalog.bySlug('kahve-fali')!;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => FortuneTypeIntroPage(type: coffee),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(_NoAuth.new)],
          child: MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
            locale: AppLocalizationsConfig.locale,
            supportedLocales: AppLocalizationsConfig.supportedLocales,
            localizationsDelegates: AppLocalizationsConfig.delegates,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final button = find.byType(PremiumFortuneOpenButton);
      await tester.ensureVisible(button);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(button);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
