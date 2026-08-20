import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';

void main() {
  group('BanaOzelCatalogEntity', () {
    test('parses production catalog shape', () {
      const sample = {
        'items': [
          {
            'id': '1',
            'slug': 'gunluk-tarot',
            'nameTr': 'Günlük Tarot Kartı',
            'icon': '🃏',
            'jetonCost': 5,
            'category': 'tarot',
            'sortOrder': 1,
          },
        ],
        'jetonBalance': 12,
        'streak': {'currentStreak': 2, 'longestStreak': 5, 'totalFortunes': 9},
      };

      final catalog = BanaOzelCatalogEntity.fromJson(sample);
      expect(catalog.items, hasLength(1));
      expect(catalog.items.first.slug, 'gunluk-tarot');
      expect(catalog.jetonBalance, 12);
      expect(catalog.streak.currentStreak, 2);
    });
  });

  group('BanaOzelOpenResultEntity', () {
    test('parses open response content fields', () {
      const item = BanaOzelItemEntity(
        id: '1',
        slug: 'sansli-sayilar',
        nameTr: 'Şanslı Sayılar',
        icon: '🍀',
        jetonCost: 2,
        category: 'fortune',
      );
      final result = BanaOzelOpenResultEntity.fromJson(
        {
          'content': 'Bugün şanslı sayılarınız: 7, 14, 21',
          'jetonSpent': 2,
          'jetonBalance': 10,
        },
        item: item,
      );
      expect(result.hasContent, isTrue);
      expect(result.jetonBalance, 10);
      expect(result.itemName, 'Şanslı Sayılar');
    });
  });
}
