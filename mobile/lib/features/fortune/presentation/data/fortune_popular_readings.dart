import 'fortune_catalog.dart';

/// En çok bakılan / trend fallar — vitrin ve tür sayfalarında listelenir.
class FortunePopularReading {
  const FortunePopularReading({
    required this.slug,
    required this.title,
    required this.preview,
    required this.viewLabel,
  });

  final String slug;
  final String title;
  final String preview;
  final String viewLabel;
}

abstract final class FortunePopularReadings {
  static const items = <FortunePopularReading>[
    FortunePopularReading(
      slug: 'tarot',
      title: 'Yeni Başlangıç',
      preview: 'Kartlar cesur adımlar ve iç sesine güven mesajı veriyor.',
      viewLabel: '24.8K',
    ),
    FortunePopularReading(
      slug: 'ask-fali',
      title: 'Kalp Bağı',
      preview: 'Aşk enerjin yükseliyor; yakında güzel bir sürpriz var.',
      viewLabel: '19.2K',
    ),
    FortunePopularReading(
      slug: 'kahve-fali',
      title: 'Fincan Mesajı',
      preview: 'Fincanında yeni yol ve sıcak bir haber görünüyor.',
      viewLabel: '18.6K',
    ),
    FortunePopularReading(
      slug: 'numeroloji',
      title: '7 Enerjisi',
      preview: 'Kişisel sayıların bugün seni destekleyen bir döngüde.',
      viewLabel: '15.1K',
    ),
    FortunePopularReading(
      slug: 'yildiz-haritasi',
      title: 'Gökyüzü Rehberi',
      preview: 'Burç haritan yaratıcılığını öne çıkarman için uyumlu.',
      viewLabel: '14.3K',
    ),
    FortunePopularReading(
      slug: 'melek-kartlari',
      title: 'Melek Mesajı',
      preview: 'Meleklerden gelen şifa ve pozitif enerji mesajı.',
      viewLabel: '12.7K',
    ),
  ];

  /// Geçerli tür dışındaki popüler fallar (tür sayfası alt listesi).
  static List<FortunePopularReading> excluding(String slug) {
    return items.where((e) => e.slug != slug).take(5).toList();
  }

  static FortunePopularReading? bySlug(String slug) {
    for (final item in items) {
      if (item.slug == slug) return item;
    }
    return null;
  }

  static String titleForSlug(String slug) {
    return FortuneCatalog.bySlug(slug)?.title ??
        bySlug(slug)?.title ??
        'Fal';
  }
}
