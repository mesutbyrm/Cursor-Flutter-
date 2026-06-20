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
    'tarot': '1509248961158-e54f6934749c',
    'kahve-fali': '1511920170033-f8396924c10b',
    'ask-fali': '1518199266791-5375a83190b7',
    'yildiz-haritasi': '1419242902214-272b3f66ee7a',
    'el-fali': '1600880292203-757bb62b4baf',
    'katina': '1596838132731-3301c3fd4317',
    'iskambil': '1571197119275-571a2ce9fccf',
    'melek-kartlari': '1518709268805-4e9042af2175',
    'numeroloji': '1635070041078-e363dbe005cb',
    'ruya-tabiri': '1495616811223-4d98c6e9c869',
    'cin-fali': '1528360983097-13cdb7de7656',
    'istihare': '1519681393784-d120267933ba',
    'aura': '1506126616188-8072cedaf28f',
    'evet-hayir': '1454165804606-c3d57bc86b40',
    'gunluk-fal': '1509248961158-e54f6934749c',
    'dogum-haritasi': '1464800860016-b2f083179a1f',
    'kursun-dokme': '1528360983097-13cdb7de7656',
  };

  static const _overlayHex = <String, List<int>>{
    'tarot': [0x442A1050, 0x881E0A3A, 0xE60A0118],
    'kahve-fali': [0x33D97706, 0x881A0F0A, 0xE60A0118],
    'ask-fali': [0x44DC2626, 0x884A0A18, 0xE60A0118],
    'yildiz-haritasi': [0x3338BDF8, 0x88050818, 0xE60A0118],
    'numeroloji': [0x33FFD700, 0x881A1508, 0xE60A0118],
    'melek-kartlari': [0x44FFFFFF, 0x881A2040, 0xE60A0118],
    'istihare': [0x3314B8A6, 0x88081020, 0xE60A0118],
    'aura': [0x448B5CF6, 0x88081830, 0xE60A0118],
    'el-fali': [0x334ADE80, 0x88081820, 0xE60A0118],
    'ruya-tabiri': [0x33818CF8, 0x88081028, 0xE60A0118],
    'katina': [0x33A855F7, 0x881A0F2E, 0xE60A0118],
    'evet-hayir': [0x33FBBF24, 0x88181808, 0xE60A0118],
    'gunluk-fal': [0x55B832FF, 0x990A0118, 0xE60A0118],
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
