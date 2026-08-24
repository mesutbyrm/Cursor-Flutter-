import 'package:flutter/material.dart';

/// Sinematik fal görselleri — premium 2026 (Unsplash CDN).
abstract final class FortuneTypeImages {
  static const _base = 'https://images.unsplash.com';

  static String sceneSlug(String slug) => _sceneSlug(slug);

  static String? assetPathFor(String slug) {
    final scene = _sceneSlug(slug);
    final file = _assetFiles[scene];
    return file != null ? 'assets/fortune/$file' : null;
  }

  static String urlFor(String slug, {int width = 1400}) {
    final scene = _sceneSlug(slug);
    final id = _photoIds[scene] ?? _photoIds['tarot']!;
    final crop = _cropFocus[scene] ?? 'entropy';
    return '$_base/photo-$id?auto=format&fit=crop&w=$width&q=92&fm=webp&crop=$crop';
  }

  static String heroTagFor(String slug) => 'fortune-hero-$slug';

  static String _sceneSlug(String slug) => switch (slug) {
        'gunluk-fal' => 'tarot',
        'aura-analizi' => 'aura',
        'kursundokme' => 'kursun-dokme',
        _ => slug,
      };

  static List<Color> overlayColors(String slug) {
    final scene = _sceneSlug(slug);
    final hex = _overlayHex[scene] ?? _overlayHex['tarot']!;
    return hex.map((h) => Color(h)).toList();
  }

  static Color glowColor(String slug) {
    final scene = _sceneSlug(slug);
    return Color(_glowHex[scene] ?? 0xFFB832FF);
  }

  static const _cropFocus = <String, String>{
    'tarot': 'entropy',
    'kahve-fali': 'center',
    'ask-fali': 'entropy',
    'yildiz-haritasi': 'entropy',
    'melek-kartlari': 'top',
    'numeroloji': 'center',
    'istihare': 'entropy',
    'aura': 'center',
    'el-fali': 'center',
    'ruya-tabiri': 'top',
  };

  static const _assetFiles = <String, String>{
    'tarot': 'tarot.webp',
    'kahve-fali': 'kahve-fali.webp',
    'ask-fali': 'ask-fali.webp',
    'yildiz-haritasi': 'yildiz-haritasi.webp',
    'el-fali': 'el-fali.webp',
    'katina': 'katina.webp',
    'iskambil': 'iskambil.webp',
    'melek-kartlari': 'melek-kartlari.webp',
    'numeroloji': 'numeroloji.webp',
    'ruya-tabiri': 'ruya-tabiri.webp',
    'cin-fali': 'cin-fali.webp',
    'istihare': 'pendul.webp',
    'aura': 'runik.webp',
    'evet-hayir': 'evet-hayir.webp',
    'gunluk-fal': 'tarot.webp',
  };

  static const _photoIds = <String, String>{
    'tarot': '1615739412122-529d88f59347', // tarot kartları
    'kahve-fali': '1511927619508-f553815789c7', // Türk kahvesi fincanı
    'ask-fali': '1522673609750-1b0e6a71928a', // kalp / aşk
    'yildiz-haritasi': '1462335937197-5ed9bc70de55', // yıldız haritası
    'el-fali': '1600880292203-757bb62b4baf', // el falı / avuç
    'katina': '1578662996442-48f60103fc96', // mistik kadın
    'iskambil': '1571197119275-571a2ce9fccf', // iskambil kartları
    'melek-kartlari': '1507408522659-9c339d1d0b9a', // melek / ışık
    'numeroloji': '1419242902214-272b3f66ee7a', // sayılar / kozmos
    'ruya-tabiri': '1506905925346-21bda4d32df4', // rüya / ay
    'cin-fali': '1528360983097-13cdb7de7656', // mistik çay / duman
    'istihare': '1519681393784-d120267933ba', // pendül / istihare
    'aura': '1534796998700-91747707550b', // aura / enerji
    'evet-hayir': '1454165804606-c3d57bc86b40', // evet-hayır kartı
    'gunluk-fal': '1559491867-1ebf5cbf7ab7', // günlük fal
    'dogum-haritasi': '1464800860016-b2f083179a1f', // doğum haritası
    'kursun-dokme': '1518131353823-3909e8946c78', // kurşun dökme
  };

  static const _overlayHex = <String, List<int>>{
    'tarot': [0x332A1050, 0x661E0A3A, 0xCC0A0118],
    'kahve-fali': [0x33D97706, 0x661A0F0A, 0xCC0A0118],
    'ask-fali': [0x44DC2626, 0x664A0A18, 0xCC0A0118],
    'yildiz-haritasi': [0x3338BDF8, 0x66050818, 0xCC0A0118],
    'numeroloji': [0x33FFD700, 0x661A1508, 0xCC0A0118],
    'melek-kartlari': [0x44FFFFFF, 0x661A2040, 0xCC0A0118],
    'istihare': [0x3314B8A6, 0x66081020, 0xCC0A0118],
    'aura': [0x448B5CF6, 0x66081830, 0xCC0A0118],
    'el-fali': [0x334ADE80, 0x66081820, 0xCC0A0118],
    'ruya-tabiri': [0x33818CF8, 0x66081028, 0xCC0A0118],
    'katina': [0x33A855F7, 0x661A0F2E, 0xCC0A0118],
    'evet-hayir': [0x33FBBF24, 0x66181808, 0xCC0A0118],
    'gunluk-fal': [0x44B832FF, 0x770A0118, 0xCC0A0118],
    'cin-fali': [0x33DC2626, 0x66180808, 0xCC0A0118],
    'iskambil': [0x33EF4444, 0x66100808, 0xCC0A0118],
  };

  static const _glowHex = <String, int>{
    'tarot': 0xFFB832FF,
    'kahve-fali': 0xFFD97706,
    'ask-fali': 0xFFE11D48,
    'yildiz-haritasi': 0xFF38BDF8,
    'numeroloji': 0xFFFFD700,
    'melek-kartlari': 0xFFFDE68A,
    'istihare': 0xFF14B8A6,
    'aura': 0xFF8B5CF6,
  };
}
