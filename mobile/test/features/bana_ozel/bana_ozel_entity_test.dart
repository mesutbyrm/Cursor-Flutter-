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

    test('parses todayTasks list', () {
      const sample = {
        'items': [],
        'todayTasks': ['login', 'watch_ad'],
      };
      final catalog = BanaOzelCatalogEntity.fromJson(sample);
      expect(catalog.todayTasks, ['login', 'watch_ad']);
      expect(catalog.parsedTodayTasks.first.labelTr, 'Günlük giriş bonusu');
    });

    test('filters items by category', () {
      const sample = {
        'items': [
          {
            'id': '1',
            'slug': 'a',
            'nameTr': 'A',
            'icon': '✨',
            'jetonCost': 1,
            'category': 'tarot',
          },
          {
            'id': '2',
            'slug': 'b',
            'nameTr': 'B',
            'icon': '♈',
            'jetonCost': 1,
            'category': 'astrology',
          },
        ],
      };
      final catalog = BanaOzelCatalogEntity.fromJson(sample);
      expect(catalog.itemsForCategory('tarot'), hasLength(1));
      expect(catalog.itemsForCategory('all'), hasLength(2));
    });
  });

  group('BanaOzelTodayTask', () {
    test('maps known task keys to Turkish labels', () {
      expect(BanaOzelTodayTask.parse('login').labelTr, 'Günlük giriş bonusu');
      expect(BanaOzelTodayTask.parse('watch_ad').labelTr, 'Reklam izle');
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

    test('parses optional streak from open response', () {
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
          'content': 'ok',
          'jetonSpent': 2,
          'jetonBalance': 10,
          'streak': {'currentStreak': 3, 'longestStreak': 5, 'totalFortunes': 11},
        },
        item: item,
      );
      expect(result.streak?.currentStreak, 3);
    });
  });
}
