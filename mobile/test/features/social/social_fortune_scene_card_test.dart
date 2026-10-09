import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/presentation/data/fortune_type_images.dart';
import 'package:canlifal_social/features/social/presentation/widgets/instagram/social_fortune_scene_card.dart';

void main() {
  group('fortuneSceneSlugFor', () {
    test('backend türleri sahne anahtarına eşlenir ve varlık dosyası var', () {
      const types = [
        'coffee', 'palm', 'tarot', 'love', 'numerology', 'aura', 'istikhara',
        'yesno', 'horoscope', 'angel', 'dream', 'birthchart', 'kursundokme',
        'katina', 'kahve-fali', 'el-fali',
      ];
      for (final t in types) {
        final slug = fortuneSceneSlugFor(t);
        expect(slug, isNotNull, reason: t);
        expect(FortuneTypeImages.assetPathFor(slug!), isNotNull, reason: t);
      }
    });

    test('bilinmeyen tür null', () {
      expect(fortuneSceneSlugFor('xyz'), isNull);
      expect(fortuneSceneSlugFor(null), isNull);
    });
  });

  for (final width in [320.0, 360.0, 430.0]) {
    testWidgets('$width px: uzun metinde taşma yok', (tester) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialFortuneSceneCard(
                fortuneType: 'coffee',
                typeLabel: 'Kahve Falı',
                body: 'Sevgili dostum, fincanının derinliklerine baktığımda. ' * 12,
                onTap: () => tapped = true,
                bottomOverlay: const SizedBox(height: 48),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.text('Kahve Falı'), findsOneWidget);
      // Metin görselin üst kısmında (tür etiketinin hemen altında).
      final cardTop = tester.getTopLeft(find.byType(SocialFortuneSceneCard)).dy;
      final textTop = tester
          .getTopLeft(find.textContaining('Sevgili dostum'))
          .dy;
      expect(textTop - cardTop, lessThan(80));
      // «daha fazla» detaya gitmez, metnin tamamını kartta açar.
      final closedH = tester.getSize(find.byType(SocialFortuneSceneCard)).height;
      await tester.tap(find.text('daha fazla'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tapped, isFalse);
      expect(find.text('daha az'), findsOneWidget);
      final openH = tester.getSize(find.byType(SocialFortuneSceneCard)).height;
      expect(openH, greaterThan(closedH));
      expect(tester.takeException(), isNull);
      // Kartın başka yerine dokunmak detayı açar.
      await tester.tap(find.text('Kahve Falı'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tapped, isTrue);
    });
  }

  testWidgets('kısa metinde «daha fazla» görünmez', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocialFortuneSceneCard(
              fortuneType: 'tarot',
              typeLabel: 'Tarot',
              body: 'Kısa bir fal.',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('daha fazla'), findsNothing);
  });
}
