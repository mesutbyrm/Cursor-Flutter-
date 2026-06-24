import 'package:flutter/material.dart';

/// Sinematik fal görselleri — premium 2026 (Unsplash CDN).
abstract final class FortuneTypeImages {
  static const _base = 'https://images.unsplash.com';

  static String urlFor(String slug, {int width = 1400}) {
    final scene = _sceneSlug(slug);
    final id = _photoIds[scene] ?? _photoIds['tarot']!;
    final crop = _cropFocus[scene] ?? 'entropy';
    return '$_base/photo-$id?auto=format&fit=crop&w=$width&q=92&fm=webp&crop=$crop';
  }

  static String heroTagFor(String slug) => 'fortune-hero-$slug';

  static String _sceneSlug(String slug) => switch (slug) {
        'pendul' => 'istihare',
        'runik' => 'aura',
        'gunluk-fal' => 'tarot',
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

  static const _photoIds = <String, String>{
    'tarot': '1559491867-1ebf5cbf7ab7',
    'kahve-fali': '1514430372180-09286b5ebaef',
    'ask-fali': '1518199266791-5375a83190b7',
    'yildiz-haritasi': '1419242902214-272b3f66ee7a',
    'el-fali': '1600880292203-757bb62b4baf',
    'katina': '1578662996442-48f60103fc96',
    'iskambil': '1571197119275-571a2ce9fccf',
    'melek-kartlari': '1615739412122-529d88f59347',
    'numeroloji': '1635070041078-e363dbe005cb',
    'ruya-tabiri': '1495616811223-4d98c6e9c869',
    'cin-fali': '1528360983097-13cdb7de7656',
    'istihare': '1519681393784-d120267933ba',
    'aura': '1506126616188-8072cedaf28f',
    'evet-hayir': '1454165804606-c3d57bc86b40',
    'gunluk-fal': '1559491867-1ebf5cbf7ab7',
    'dogum-haritasi': '1464800860016-b2f083179a1f',
    'kursun-dokme': '1528360983097-13cdb7de7656',
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
