import 'package:flutter/material.dart';

/// Fal türleri için premium vitrin görselleri (Unsplash CDN, yüksek çözünürlük).
abstract final class FortuneTypeImages {
  static const _base = 'https://images.unsplash.com';

  /// Hero / kart / kapak için optimize URL (2x retina, WebP/JPEG).
  static String urlFor(String slug, {int width = 1200}) {
    final id = _photoIds[slug] ?? _photoIds['tarot']!;
    final crop = _cropFocus[slug] ?? 'entropy';
    return '$_base/photo-$id?auto=format&fit=crop&w=$width&q=90&fm=webp&crop=$crop';
  }

  static String heroTagFor(String slug) => 'fortune-hero-$slug';

  /// Fal türüne özel renk vurgusu (gradient overlay).
  static List<Color> overlayColors(String slug) {
    final hex = _overlayHex[slug] ?? _overlayHex['tarot']!;
    return hex.map((h) => Color(h)).toList();
  }

  static const _cropFocus = <String, String>{
    'tarot': 'faces',
    'kahve-fali': 'center',
    'el-fali': 'center',
    'yildiz-haritasi': 'entropy',
    'ruya-tabiri': 'top',
  };

  /// Premium temalı Unsplash fotoğraf kimlikleri.
  static const _photoIds = <String, String>{
    'tarot': '1509248961158-e54f6934749c',
    'ask-fali': '1518199266791-5375a83190b7',
    'kahve-fali': '1511920170033-f8396924c10b',
    'yildiz-haritasi': '1419242902214-272b3f66ee7a',
    'el-fali': '1600880292203-757bb62b4baf',
    'katina': '1596838132731-3301c3fd4317',
    'iskambil': '1571197119275-571a2ce9fccf',
    'melek-kartlari': '1518709268805-4e9042af2175',
    'numeroloji': '1635070041078-e363dbe005cb',
    'ruya-tabiri': '1495616811223-4d98c6e9c869',
    'cin-fali': '1528360983097-13cdb7de7656',
    'pendul': '1618172193622-ae2d025f4032',
    'runik': '1506905925346-21bda4d32df4',
    'evet-hayir': '1454165804606-c3d57bc86b40',
    'gunluk-fal': '1518546305927-5a555bb7020d',
    'dogum-haritasi': '1419242902214-272b3f66ee7a',
    'istihare': '1618172193622-ae2d025f4032',
    'aura': '1506905925346-21bda4d32df4',
    'kursun-dokme': '1528360983097-13cdb7de7656',
  };

  static const _overlayHex = <String, List<int>>{
    'tarot': [0x66B832FF, 0x99FFD700, 0xCC0A0118],
    'kahve-fali': [0x44D97706, 0x88FFD700, 0xCC1A0F0A],
    'el-fali': [0x554ADE80, 0x8800FFFF, 0xCC0A0118],
    'yildiz-haritasi': [0x5538BDF8, 0x886366F1, 0xCC0A0118],
    'numeroloji': [0x5534D399, 0x88FFD700, 0xCC0A0118],
    'runik': [0x5594A3B8, 0x88FF6B9D, 0xCC0A0118],
    'melek-kartlari': [0x5567E8F9, 0x88FFFFFF, 0xCC0A0118],
    'ruya-tabiri': [0x55818CF8, 0x88C4B5FD, 0xCC0A0118],
    'ask-fali': [0x55FF4EC8, 0x88FF6B9D, 0xCC0A0118],
    'cin-fali': [0x55EF4444, 0x88FFD700, 0xCC0A0118],
    'pendul': [0x5514B8A6, 0x886366F1, 0xCC0A0118],
    'katina': [0x55A855F7, 0x88FFD700, 0xCC1A0F2E],
    'evet-hayir': [0x55FBBF24, 0x88FFFFFF, 0xCC0A0118],
    'gunluk-fal': [0x55B832FF, 0x88FFD700, 0xCC0A0118],
  };
}
