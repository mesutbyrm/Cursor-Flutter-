import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_providers.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/widgets/bana_ozel_premium_card.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/widgets/home_bana_ozel_section.dart';

void main() {
  group('HomeBanaOzelSection', () {
    testWidgets('renders preview cards when catalog has items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            banaOzelCatalogProvider.overrideWith(_StubCatalogNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeBanaOzelSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bana Özel'), findsOneWidget);
      expect(find.textContaining('Günlük Tarot Kartı'), findsOneWidget);
      expect(find.text('5 Jeton'), findsOneWidget);
    });

    testWidgets('shows empty state when catalog is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            banaOzelCatalogProvider.overrideWith(_EmptyCatalogNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeBanaOzelSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bana Özel'), findsOneWidget);
      expect(
        find.text('Size özel yeni içerikler hazırlanıyor.'),
        findsOneWidget,
      );
    });
  });

  group('BanaOzelPremiumCard', () {
    testWidgets('hides price badge when jetonCost is zero', (tester) async {
      const item = BanaOzelItemEntity(
        id: '1',
        slug: 'free-item',
        nameTr: 'Ücretsiz',
        icon: '✨',
        jetonCost: 0,
        category: 'fortune',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BanaOzelPremiumCard(item: item, onTap: () {}),
          ),
        ),
      );
      expect(find.textContaining('Jeton'), findsNothing);
    });
  });
}

class _StubCatalogNotifier extends BanaOzelCatalogNotifier {
  @override
  Future<BanaOzelCatalogEntity> build() async {
    return const BanaOzelCatalogEntity(
      items: [
        BanaOzelItemEntity(
          id: '1',
          slug: 'gunluk-tarot',
          nameTr: 'Günlük Tarot Kartı',
          icon: '🃏',
          jetonCost: 5,
          category: 'tarot',
        ),
      ],
      jetonBalance: 12,
    );
  }
}

class _EmptyCatalogNotifier extends BanaOzelCatalogNotifier {
  @override
  Future<BanaOzelCatalogEntity> build() async {
    return const BanaOzelCatalogEntity(items: []);
  }
}
