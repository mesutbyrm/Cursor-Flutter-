import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:flutter/material.dart';

import '../../../fortune/presentation/data/fortune_catalog.dart';
import '../../domain/entities/bana_ozel_entities.dart';

/// Bana Özel vitrin kartı — görsel slug + accent (API öncelikli).
abstract final class BanaOzelDisplayResolver {
  static String coverSlugFor(BanaOzelItemEntity item) {
    final catalogMatch = FortuneCatalog.bySlug(item.slug);
    if (catalogMatch != null) return catalogMatch.slug;

    final slug = item.slug.toLowerCase();
    if (slug.contains('tarot')) return 'tarot';
    if (slug.contains('burc') ||
        slug.contains('horoscope') ||
        slug.contains('zodiac')) {
      return 'yildiz-haritasi';
    }
    if (slug.contains('yildiz') || slug.contains('yildizname')) {
      return 'yildiz-haritasi';
    }
    if (slug.contains('kahve') || slug.contains('coffee')) {
      return 'kahve-fali';
    }
    if (slug.contains('ruya') || slug.contains('dream')) {
      return 'ruya-tabiri';
    }
    if (slug.contains('el') || slug.contains('palm')) return 'el-fali';
    if (slug.contains('numeroloji') || slug.contains('numerology')) {
      return 'numeroloji';
    }
    if (slug.contains('aura')) return 'aura-analizi';
    if (slug.contains('melek') || slug.contains('angel')) {
      return 'melek-kartlari';
    }
    if (slug.contains('ask') || slug.contains('love')) return 'ask-fali';
    if (slug.contains('dogum') || slug.contains('birth')) {
      return 'dogum-haritasi';
    }
    if (slug.contains('istihare')) return 'istihare';
    if (slug.contains('kursun')) return 'kursundokme';

    return switch (item.category) {
      'tarot' => 'tarot',
      'astrology' => 'yildiz-haritasi',
      'spiritual' => 'melek-kartlari',
      _ => 'tarot',
    };
  }

  static Color accentFor(BanaOzelItemEntity item) {
    final catalog = FortuneCatalog.bySlug(coverSlugFor(item));
    return catalog?.accent ?? const Color(0xFFB832FF);
  }

  static String? imageUrlFor(BanaOzelItemEntity item) {
    final raw = item.imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    return CanlifalImageUrls.resolve(raw);
  }

  static String? subtitleFor(BanaOzelItemEntity item) {
    final desc = item.descTr?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final sign = item.horoscopeSign?.trim();
    if (sign != null && sign.isNotEmpty) return sign;
    return null;
  }

  static String titleWithIcon(BanaOzelItemEntity item) {
    final icon = item.icon.trim();
    if (icon.isNotEmpty && !icon.startsWith('http')) {
      return '$icon ${item.nameTr}';
    }
    return item.nameTr;
  }
}
