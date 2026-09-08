import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/data/bana_ozel_preferences_store.dart';
import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_preferences_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_hub_providers.dart';

void main() {
  group('fortuneHubMatchesSearch', () {
    test('boş sorgu her şeyi eşleştirir', () {
      expect(
        fortuneHubMatchesSearch(
          query: '',
          title: 'Tarot',
          slug: 'tarot',
        ),
        isTrue,
      );
    });

    test('slug ve başlık araması', () {
      expect(
        fortuneHubMatchesSearch(
          query: 'kahve',
          title: 'Kahve Falı',
          slug: 'kahve-fali',
        ),
        isTrue,
      );
      expect(
        fortuneHubMatchesSearch(
          query: 'xyz',
          title: 'Tarot',
          slug: 'tarot',
        ),
        isFalse,
      );
    });
  });

  group('filterAndSortBanaOzelItems', () {
    const items = [
      BanaOzelItemEntity(
        id: '1',
        slug: 'tarot-a',
        nameTr: 'Tarot A',
        icon: '🃏',
        jetonCost: 5,
        category: 'tarot',
        sortOrder: 2,
      ),
      BanaOzelItemEntity(
        id: '2',
        slug: 'ask-b',
        nameTr: 'Aşk B',
        icon: '💕',
        jetonCost: 1,
        category: 'fortune',
        sortOrder: 1,
      ),
    ];

    test('favoriler öne alınır', () {
      final sorted = filterAndSortBanaOzelItems(
        items: items,
        searchQuery: '',
        sortMode: BanaOzelSortMode.catalog,
        favoriteSlugs: {'tarot-a'},
      );
      expect(sorted.first.slug, 'tarot-a');
    });

    test('arama filtreler', () {
      final filtered = filterAndSortBanaOzelItems(
        items: items,
        searchQuery: 'aşk',
        sortMode: BanaOzelSortMode.catalog,
        favoriteSlugs: const {},
      );
      expect(filtered.length, 1);
      expect(filtered.first.slug, 'ask-b');
    });
  });
}
