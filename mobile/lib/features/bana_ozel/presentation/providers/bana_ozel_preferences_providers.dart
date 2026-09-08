import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bana_ozel_entities.dart';
import '../../data/bana_ozel_preferences_store.dart';

final banaOzelPreferencesStoreProvider =
    FutureProvider<BanaOzelPreferencesStore>((ref) async {
  return BanaOzelPreferencesStore.create();
});

final banaOzelSearchQueryProvider = StateProvider<String>((ref) => '');

final banaOzelSortModeProvider = StateProvider<BanaOzelSortMode>(
  (ref) => BanaOzelSortMode.catalog,
);

List<BanaOzelItemEntity> filterAndSortBanaOzelItems({
  required List<BanaOzelItemEntity> items,
  required String searchQuery,
  required BanaOzelSortMode sortMode,
  required Set<String> favoriteSlugs,
}) {
  var list = items;
  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list
        .where(
          (item) =>
              item.nameTr.toLowerCase().contains(q) ||
              item.slug.toLowerCase().contains(q) ||
              (item.descTr?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  list = List<BanaOzelItemEntity>.from(list);
  switch (sortMode) {
    case BanaOzelSortMode.name:
      list.sort((a, b) => a.nameTr.compareTo(b.nameTr));
    case BanaOzelSortMode.priceLow:
      list.sort((a, b) => a.jetonCost.compareTo(b.jetonCost));
    case BanaOzelSortMode.priceHigh:
      list.sort((a, b) => b.jetonCost.compareTo(a.jetonCost));
    case BanaOzelSortMode.catalog:
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  list.sort((a, b) {
    final af = favoriteSlugs.contains(a.slug);
    final bf = favoriteSlugs.contains(b.slug);
    if (af == bf) return 0;
    return af ? -1 : 1;
  });
  return list;
}

Future<void> refreshBanaOzelPreferences(WidgetRef ref) async {
  ref.invalidate(banaOzelPreferencesStoreProvider);
}
