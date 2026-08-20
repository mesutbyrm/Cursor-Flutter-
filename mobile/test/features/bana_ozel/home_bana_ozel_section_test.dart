import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_providers.dart';
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
      expect(find.text('Günlük Tarot Kartı'), findsOneWidget);
      expect(find.text('5 jeton'), findsOneWidget);
    });

    testWidgets('hides when catalog is empty', (tester) async {
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

      expect(find.text('Bana Özel'), findsNothing);
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
