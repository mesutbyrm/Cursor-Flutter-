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
    this.isActive = true,
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
      isActive: json['isActive'] != false && json['isVisible'] != false,
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
  final bool isActive;

  bool get isValid =>
      slug.trim().isNotEmpty && nameTr.trim().isNotEmpty && isActive;

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

/// Günlük jeton görev anahtarı — `GET /api/bana-ozel` `todayTasks[]`.
enum BanaOzelTodayTask {
  login,
  watchAd,
  openContent,
  share,
  unknown;

  static BanaOzelTodayTask parse(String raw) {
    final key = raw.trim().toLowerCase().replaceAll('-', '_');
    return switch (key) {
      'login' || 'daily_login' => BanaOzelTodayTask.login,
      'watch_ad' || 'watchad' || 'ad' => BanaOzelTodayTask.watchAd,
      'open_content' ||
      'open_fortune' ||
      'bana_ozel' ||
      'open' =>
        BanaOzelTodayTask.openContent,
      'share' || 'share_fortune' => BanaOzelTodayTask.share,
      _ => BanaOzelTodayTask.unknown,
    };
  }

  String get labelTr => switch (this) {
        BanaOzelTodayTask.login => 'Günlük giriş bonusu',
        BanaOzelTodayTask.watchAd => 'Reklam izle',
        BanaOzelTodayTask.openContent => 'Bana Özel içerik aç',
        BanaOzelTodayTask.share => 'Falını paylaş',
        BanaOzelTodayTask.unknown => 'Günlük görev',
      };

  /// Mobil yönlendirme — web görev merkezi parity.
  String? get routePath => switch (this) {
        BanaOzelTodayTask.login || BanaOzelTodayTask.watchAd =>
          '/profile/growth',
        BanaOzelTodayTask.share => '/social/create',
        _ => null,
      };
}

/// `GET /api/bana-ozel` yanıtı.
class BanaOzelCatalogEntity {
  const BanaOzelCatalogEntity({
    required this.items,
    this.jetonBalance = 0,
    this.streak = const BanaOzelStreakEntity(),
    this.todayTasks = const [],
  });

  factory BanaOzelCatalogEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['catalog'] ?? json['data'];
    final items = asJsonList(rawItems)
        .map(BanaOzelItemEntity.fromJson)
        .where((e) => e.isValid)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final streakRaw = pick(json, ['streak', 'fortuneStreak']);
    final rawTasks = json['todayTasks'] ?? json['tasks'];
    final tasks = _parseStringList(rawTasks);
    return BanaOzelCatalogEntity(
      items: items,
      jetonBalance: asInt(pick(json, ['jetonBalance', 'balance', 'coins'])),
      streak: streakRaw is Map
          ? BanaOzelStreakEntity.fromJson(Map<String, dynamic>.from(streakRaw))
          : const BanaOzelStreakEntity(),
      todayTasks: tasks,
    );
  }

  final List<BanaOzelItemEntity> items;
  final int jetonBalance;
  final BanaOzelStreakEntity streak;
  final List<String> todayTasks;

  List<BanaOzelTodayTask> get parsedTodayTasks =>
      todayTasks.map(BanaOzelTodayTask.parse).toList();

  List<BanaOzelItemEntity> itemsForCategory(String? category) {
    if (category == null || category == 'all') return items;
    return items.where((e) => e.category == category).toList();
  }

  BanaOzelItemEntity? itemBySlug(String slug) {
    final key = slug.trim();
    if (key.isEmpty) return null;
    for (final item in items) {
      if (item.slug == key) return item;
    }
    return null;
  }

  List<String> get categories =>
      items.map((e) => e.category).toSet().toList()..sort();
}

/// Open sonrası jeton bakiyesi — `POST /api/bana-ozel/open` yanıtı + mevcut bakiye.
int resolveJetonBalanceAfterOpen({
  required int currentBalance,
  required BanaOzelOpenResultEntity result,
}) {
  if (result.jetonBalance > 0) return result.jetonBalance;
  return (currentBalance - result.jetonSpent).clamp(0, 1 << 30);
}

List<String> _parseStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e?.toString() ?? '')
      .where((e) => e.trim().isNotEmpty)
      .toList();
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
    this.streak,
  });

  factory BanaOzelOpenResultEntity.fromJson(
    Map<String, dynamic> json, {
    required BanaOzelItemEntity item,
  }) {
    final nested = pick(json, ['item', 'data', 'result']);
    final itemMap = nested is Map ? Map<String, dynamic>.from(nested) : json;
    final content = pick(json, ['content', 'text', 'reading', 'message']) ??
        pick(itemMap, ['content', 'text', 'reading', 'message']);
    final streakRaw = pick(json, ['streak', 'fortuneStreak']);
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
      streak: streakRaw is Map
          ? BanaOzelStreakEntity.fromJson(Map<String, dynamic>.from(streakRaw))
          : null,
    );
  }

  final String content;
  final String itemSlug;
  final String itemName;
  final String icon;
  final int jetonSpent;
  final int jetonBalance;
  final BanaOzelStreakEntity? streak;

  bool get hasContent => content.trim().isNotEmpty;
}
