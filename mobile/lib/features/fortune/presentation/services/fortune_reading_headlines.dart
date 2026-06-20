import 'package:flutter/material.dart';

import '../../domain/entities/fortune_reading_section.dart';
import '../../domain/entities/fortune_type_entity.dart';

/// Fal sonucu için sinematik başlık ve enerji etiketi.
abstract final class FortuneReadingHeadlines {
  static const _titles = [
    'Yeni Başlangıçlar',
    'Aşk Kapıda',
    'Maddi Bereket',
    'Şanslı Dönem',
    'Ruhsal Uyanış',
    'Pozitif Dönüşüm',
    'İç Işığın Parlıyor',
    'Kader Seninle',
  ];

  static const _energyTags = [
    'Pozitif Enerji',
    'Yükselen Frekans',
    'Kozmik Uyum',
    'Güçlü Aura',
    'Şanslı Akış',
  ];

  static String headlineFor(FortuneReadingResult result) {
    final seed = (result.summary.hashCode ^ result.type.slug.hashCode).abs();
    final slug = result.type.slug;
    if (slug == 'ask-fali') return 'Aşk Kapıda';
    if (slug == 'kahve-fali') return 'Yeni Başlangıçlar';
    if (slug == 'yildiz-haritasi') return 'Şanslı Dönem';
    if (slug == 'numeroloji') return 'Maddi Bereket';
    if (slug == 'runik') return 'Ruhsal Uyanış';
    return _titles[seed % _titles.length];
  }

  static String energyTagFor(FortuneReadingResult result) {
    final seed = DateTime.now().day + result.summary.length;
    return _energyTags[seed % _energyTags.length];
  }

  static IconData sectionIcon(String key) => switch (key) {
        FortuneSectionKeys.love => Icons.favorite_rounded,
        FortuneSectionKeys.career => Icons.work_rounded,
        FortuneSectionKeys.money => Icons.payments_rounded,
        FortuneSectionKeys.future => Icons.nightlight_round,
        FortuneSectionKeys.advice => Icons.star_rounded,
        _ => Icons.auto_awesome_rounded,
      };

  static String sectionLabel(String key) => switch (key) {
        FortuneSectionKeys.general => 'GENEL YORUM',
        FortuneSectionKeys.love => 'Aşk',
        FortuneSectionKeys.career => 'Kariyer',
        FortuneSectionKeys.money => 'Para',
        FortuneSectionKeys.future => 'Ruhsal Durum',
        FortuneSectionKeys.advice => 'Tavsiye',
        _ => 'Yorum',
      };
}
