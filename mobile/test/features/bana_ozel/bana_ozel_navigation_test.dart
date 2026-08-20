import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';

void main() {
  group('BanaOzelCatalogEntity.itemBySlug', () {
    test('finds item by slug', () {
      const catalog = BanaOzelCatalogEntity(
        items: [
          BanaOzelItemEntity(
            id: '1',
            slug: 'gunluk-tarot',
            nameTr: 'Günlük Tarot',
            icon: '🃏',
            jetonCost: 5,
            category: 'tarot',
          ),
        ],
      );
      expect(catalog.itemBySlug('gunluk-tarot')?.nameTr, 'Günlük Tarot');
      expect(catalog.itemBySlug('missing'), isNull);
    });
  });

  group('openBanaOzelCatalog path', () {
    test('builds slug query when slug provided', () {
      expect(
        Uri(path: '/fortune/bana-ozel', queryParameters: {'slug': 'gunluk-tarot'})
            .toString(),
        '/fortune/bana-ozel?slug=gunluk-tarot',
      );
    });
  });
}
