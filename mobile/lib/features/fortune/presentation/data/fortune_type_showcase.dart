import 'package:flutter/material.dart';

import '../../domain/entities/fortune_type_entity.dart';
import 'fortune_catalog.dart';

/// Mockup — fal türü vitrin kartı (görsel, 3 özellik, Falını Aç).
class FortuneTypeShowcase {
  const FortuneTypeShowcase({
    required this.index,
    required this.type,
    required this.imageAsset,
    required this.features,
  });

  final int index;
  final FortuneTypeEntity type;
  final String imageAsset;
  final List<FortuneTypeFeature> features;

  String get numberedTitle => '$index. ${type.title}';

  static String imageAssetForSlug(String slug) =>
      'assets/fortune/$slug.png';

  static FortuneTypeShowcase? forSlug(String slug) {
    final type = FortuneCatalog.bySlug(slug);
    if (type == null || type.isDaily) return null;
    final idx = FortuneCatalog.types.indexWhere((t) => t.slug == slug);
    if (idx < 0) return null;
    return _all[idx];
  }

  static List<FortuneTypeShowcase> get hubShowcases {
    return [
      for (final e in FortuneCatalog.hubFortuneEntries)
        if (forSlug(e.slug) != null) forSlug(e.slug)!,
    ];
  }

  static final List<FortuneTypeShowcase> _all = [
    _s(
      1,
      FortuneCatalog.types[0],
      [
        _f(Icons.auto_stories_rounded, 'Derin Anlamlar'),
        _f(Icons.psychology_rounded, 'Kişisel Rehberlik'),
        _f(Icons.visibility_rounded, 'İçsel Farkındalık'),
      ],
    ),
    _s(
      2,
      FortuneCatalog.types[1],
      [
        _f(Icons.favorite_rounded, 'Aşk Enerjisi'),
        _f(Icons.people_rounded, 'İlişki Rehberi'),
        _f(Icons.volunteer_activism_rounded, 'Kalp Açılımı'),
      ],
    ),
    _s(
      3,
      FortuneCatalog.types[2],
      [
        _f(Icons.history_rounded, 'Geçmişin İzleri'),
        _f(Icons.timeline_rounded, 'Yakın Gelecek'),
        _f(Icons.check_circle_outline_rounded, 'Net Yorumlar'),
      ],
    ),
    _s(
      4,
      FortuneCatalog.types[3],
      [
        _f(Icons.star_half_rounded, 'Burç Yorumu'),
        _f(Icons.public_rounded, 'Gezegen Etkileri'),
        _f(Icons.insights_rounded, 'Kişisel Analiz'),
      ],
    ),
    _s(
      5,
      FortuneCatalog.types[4],
      [
        _f(Icons.gesture_rounded, 'Çizgi Yorumu'),
        _f(Icons.analytics_rounded, 'Hayat Analizi'),
        _f(Icons.trending_up_rounded, 'Gelecek Öngörü'),
      ],
    ),
    _s(
      6,
      FortuneCatalog.types[5],
      [
        _f(Icons.favorite_border_rounded, 'İlişki Analizi'),
        _f(Icons.sentiment_satisfied_alt_rounded, 'Duygusal Rehber'),
        _f(Icons.diversity_1_rounded, 'Aşk Yorumu'),
      ],
    ),
    _s(
      7,
      FortuneCatalog.types[6],
      [
        _f(Icons.history_edu_rounded, 'Geçmiş'),
        _f(Icons.access_time_rounded, 'Şimdi'),
        _f(Icons.forward_rounded, 'Gelecek'),
      ],
    ),
    _s(
      8,
      FortuneCatalog.types[7],
      [
        _f(Icons.flutter_dash_rounded, 'Melek Rehberliği'),
        _f(Icons.wb_sunny_rounded, 'İlahi Destek'),
        _f(Icons.spa_rounded, 'Pozitif Enerji'),
      ],
    ),
    _s(
      9,
      FortuneCatalog.types[8],
      [
        _f(Icons.route_rounded, 'Kişisel Yolculuk'),
        _f(Icons.pin_rounded, 'Kişisel Sayılar'),
        _f(Icons.query_stats_rounded, 'Gelecek Analizi'),
      ],
    ),
    _s(
      10,
      FortuneCatalog.types[9],
      [
        _f(Icons.nightlight_round_rounded, 'Nitelikli Yorum'),
        _f(Icons.category_rounded, 'Semboller'),
        _f(Icons.mail_outline_rounded, 'Mesajlar'),
      ],
    ),
    _s(
      11,
      FortuneCatalog.types[10],
      [
        _f(Icons.translate_rounded, 'Falı Çöz'),
        _f(Icons.handshake_rounded, 'Uygunluk'),
        _f(Icons.casino_rounded, 'Şans Yorumu'),
      ],
    ),
    _s(
      12,
      FortuneCatalog.types[11],
      [
        _f(Icons.lightbulb_outline_rounded, 'Netlik Kazan'),
        _f(Icons.speed_rounded, 'Enerji Ölçümü'),
        _f(Icons.schedule_rounded, 'Doğru Zaman'),
      ],
    ),
    _s(
      13,
      FortuneCatalog.types[12],
      [
        _f(Icons.font_download_rounded, 'Rune Çek'),
        _f(Icons.explore_rounded, 'Rehberlik'),
        _f(Icons.self_improvement_rounded, 'Spiritüel Kılavuz'),
      ],
    ),
    _s(
      14,
      FortuneCatalog.types[13],
      [
        _f(Icons.done_all_rounded, 'Net Cevap'),
        _f(Icons.support_rounded, 'Karar Desteği'),
        _f(Icons.flash_on_rounded, 'Hızlı Fal'),
      ],
    ),
  ];

  static List<FortuneTypeShowcase> get all => _all;

  static FortuneTypeShowcase _s(
    int index,
    FortuneTypeEntity type,
    List<FortuneTypeFeature> features,
  ) =>
      FortuneTypeShowcase(
        index: index,
        type: type,
        imageAsset: imageAssetForSlug(type.slug),
        features: features,
      );

  static FortuneTypeFeature _f(IconData icon, String label) =>
      FortuneTypeFeature(icon: icon, label: label);
}

class FortuneTypeFeature {
  const FortuneTypeFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
