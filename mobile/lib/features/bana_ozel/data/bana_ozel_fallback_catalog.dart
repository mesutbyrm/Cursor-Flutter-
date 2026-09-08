import '../../fortune/presentation/data/fortune_catalog.dart';
import '../domain/entities/bana_ozel_entities.dart';

/// API boş veya erişilemez olduğunda vitrin yedek kataloğu.
abstract final class BanaOzelFallbackCatalog {
  static const _previewSlugs = [
    'gunluk-fal',
    'tarot',
    'kahve-fali',
    'ask-fali',
    'yildiz-haritasi',
    'melek-kartlari',
    'numeroloji',
    'dogum-haritasi',
  ];

  static BanaOzelCatalogEntity build({
    int jetonBalance = 0,
    int cfcBalance = 0,
    BanaOzelStreakEntity streak = const BanaOzelStreakEntity(),
    List<String> todayTasks = const [],
  }) {
    final items = <BanaOzelItemEntity>[];
    var order = 0;
    for (final slug in _previewSlugs) {
      final type = FortuneCatalog.bySlug(slug);
      if (type == null) continue;
      items.add(
        BanaOzelItemEntity(
          id: 'fallback-$slug',
          slug: slug,
          nameTr: type.title,
          descTr: type.description,
          icon: type.emoji,
          jetonCost: slug == 'gunluk-fal' ? 0 : 12,
          category: _categoryFor(slug),
          sortOrder: order++,
        ),
      );
    }
    return BanaOzelCatalogEntity(
      items: items,
      jetonBalance: jetonBalance,
      cfcBalance: cfcBalance,
      streak: streak,
      todayTasks: todayTasks,
    );
  }

  static String _categoryFor(String slug) {
    if (slug == 'gunluk-fal' || slug == 'tarot') return 'tarot';
    if (slug == 'melek-kartlari') return 'spiritual';
    if (slug == 'yildiz-haritasi' ||
        slug == 'dogum-haritasi' ||
        slug == 'numeroloji') {
      return 'astrology';
    }
    return 'fortune';
  }
}
