import '../../../../core/util/json_util.dart';

/// `GET /api/bana-ozel` katalog satırı.
class BanaOzelItemEntity {
  const BanaOzelItemEntity({
    required this.id,
    required this.slug,
    required this.nameTr,
    required this.icon,
    required this.jetonCost,
    required this.category,
    this.descTr,
    this.sortOrder = 0,
  });

  factory BanaOzelItemEntity.fromJson(Map<String, dynamic> json) {
    return BanaOzelItemEntity(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      slug: pick(json, ['slug', 'key'])?.toString() ?? '',
      nameTr: pick(json, ['nameTr', 'name', 'title', 'label'])?.toString() ??
          'İçerik',
      descTr: pick(json, ['descTr', 'description', 'desc'])?.toString(),
      icon: pick(json, ['icon', 'emoji'])?.toString() ?? '✨',
      jetonCost: asInt(pick(json, ['jetonCost', 'cost', 'price'])),
      category:
          pick(json, ['category', 'type'])?.toString() ?? 'fortune',
      sortOrder: asInt(pick(json, ['sortOrder', 'order'])),
    );
  }

  final String id;
  final String slug;
  final String nameTr;
  final String? descTr;
  final String icon;
  final int jetonCost;
  final String category;
  final int sortOrder;

  bool get isValid => slug.trim().isNotEmpty && nameTr.trim().isNotEmpty;

  String get categoryLabel => switch (category) {
        'tarot' => 'Tarot',
        'astrology' => 'Astroloji',
        'spiritual' => 'Spiritüel',
        _ => 'Fal',
      };
}

class BanaOzelStreakEntity {
  const BanaOzelStreakEntity({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalFortunes = 0,
  });

  factory BanaOzelStreakEntity.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BanaOzelStreakEntity();
    return BanaOzelStreakEntity(
      currentStreak: asInt(pick(json, ['currentStreak', 'streak'])),
      longestStreak: asInt(pick(json, ['longestStreak'])),
      totalFortunes: asInt(pick(json, ['totalFortunes', 'total'])),
    );
  }

  final int currentStreak;
  final int longestStreak;
  final int totalFortunes;
}

/// `GET /api/bana-ozel` yanıtı.
class BanaOzelCatalogEntity {
  const BanaOzelCatalogEntity({
    required this.items,
    this.jetonBalance = 0,
    this.streak = const BanaOzelStreakEntity(),
  });

  factory BanaOzelCatalogEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['catalog'] ?? json['data'];
    final items = asJsonList(rawItems)
        .map(BanaOzelItemEntity.fromJson)
        .where((e) => e.isValid)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final streakRaw = pick(json, ['streak', 'fortuneStreak']);
    return BanaOzelCatalogEntity(
      items: items,
      jetonBalance: asInt(pick(json, ['jetonBalance', 'balance', 'coins'])),
      streak: streakRaw is Map
          ? BanaOzelStreakEntity.fromJson(Map<String, dynamic>.from(streakRaw))
          : const BanaOzelStreakEntity(),
    );
  }

  final List<BanaOzelItemEntity> items;
  final int jetonBalance;
  final BanaOzelStreakEntity streak;

  List<BanaOzelItemEntity> itemsForCategory(String? category) {
    if (category == null || category == 'all') return items;
    return items.where((e) => e.category == category).toList();
  }

  List<String> get categories =>
      items.map((e) => e.category).toSet().toList()..sort();
}

/// `POST /api/bana-ozel/open` yanıtı.
class BanaOzelOpenResultEntity {
  const BanaOzelOpenResultEntity({
    required this.content,
    required this.itemSlug,
    required this.itemName,
    this.icon = '✨',
    this.jetonSpent = 0,
    this.jetonBalance = 0,
  });

  factory BanaOzelOpenResultEntity.fromJson(
    Map<String, dynamic> json, {
    required BanaOzelItemEntity item,
  }) {
    final nested = pick(json, ['item', 'data', 'result']);
    final itemMap = nested is Map ? Map<String, dynamic>.from(nested) : json;
    final content = pick(json, ['content', 'text', 'reading', 'message']) ??
        pick(itemMap, ['content', 'text', 'reading', 'message']);
    return BanaOzelOpenResultEntity(
      content: content?.toString().trim() ?? '',
      itemSlug: pick(itemMap, ['slug', 'itemSlug'])?.toString() ?? item.slug,
      itemName: pick(itemMap, ['nameTr', 'name', 'title'])?.toString() ??
          item.nameTr,
      icon: pick(itemMap, ['icon', 'emoji'])?.toString() ?? item.icon,
      jetonSpent: asInt(
        pick(json, ['jetonSpent', 'cost', 'spent']) ?? item.jetonCost,
      ),
      jetonBalance: asInt(
        pick(json, ['jetonBalance', 'newBalance', 'balance']),
      ),
    );
  }

  final String content;
  final String itemSlug;
  final String itemName;
  final String icon;
  final int jetonSpent;
  final int jetonBalance;

  bool get hasContent => content.trim().isNotEmpty;
}
