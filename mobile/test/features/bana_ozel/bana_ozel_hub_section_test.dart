import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_providers.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/widgets/bana_ozel_hub_section.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/widgets/bana_ozel_premium_card.dart';

void main() {
  group('BanaOzelHubSection', () {
    testWidgets('renders premium cards when catalog has items', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            banaOzelCatalogProvider.overrideWith(_StubCatalogNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BanaOzelHubSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('BANA ÖZEL'), findsOneWidget);
      expect(find.textContaining('Günlük Tarot Kartı'), findsOneWidget);
      expect(find.byType(BanaOzelPremiumCard), findsOneWidget);
    });

    testWidgets('shows empty state when catalog is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            banaOzelCatalogProvider.overrideWith(_EmptyCatalogNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BanaOzelHubSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('BANA ÖZEL'), findsOneWidget);
      expect(
        find.text('Size özel yeni içerikler hazırlanıyor.'),
        findsOneWidget,
      );
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
      jetonBalance: 20,
    );
  }
}

class _EmptyCatalogNotifier extends BanaOzelCatalogNotifier {
  @override
  Future<BanaOzelCatalogEntity> build() async {
    return const BanaOzelCatalogEntity(items: []);
  }
}
