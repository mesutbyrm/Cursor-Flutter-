import '../../../core/config/env.dart';

/// Sesli oda tema kataloğu — gradient + arkaplan (admin örnek seti).
class VoiceRoomTheme {
  const VoiceRoomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    this.backgroundUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int primaryColor;
  final int secondaryColor;
  final String? backgroundUrl;
  final int sortOrder;
}

abstract final class VoiceRoomThemeCatalog {
  static String get _origin {
    var base = Env.webOrigin.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return base;
  }

  static const _palette = <(String, int, int)>[
    ('Mor Gece', 0xFF6B21A8, 0xFF1E1B4B),
    ('Neon Pembe', 0xFFDB2777, 0xFF4C1D95),
    ('Okyanus', 0xFF0284C7, 0xFF0F172A),
    ('Altın VIP', 0xFFF59E0B, 0xFF451A03),
    ('Zümrüt', 0xFF059669, 0xFF064E3B),
    ('Lavanta', 0xFF8B5CF6, 0xFF312E81),
    ('Gün Batımı', 0xFFF97316, 0xFF7C2D12),
    ('Buz Kristali', 0xFF38BDF8, 0xFF0C4A6E),
    ('Kozmik', 0xFF6366F1, 0xFF111827),
    ('Ateş', 0xFFEF4444, 0xFF450A0A),
    ('Gül', 0xFFEC4899, 0xFF500724),
    ('Orman', 0xFF22C55E, 0xFF14532D),
    ('Şampanya', 0xFFFDE68A, 0xFF78350F),
    ('Gece Mavisi', 0xFF1D4ED8, 0xFF020617),
    ('Turkuaz', 0xFF14B8A6, 0xFF134E4A),
    ('Galaksi', 0xFF7C3AED, 0xFF020617),
    ('Kiraz', 0xFFBE123C, 0xFF4C0519),
    ('Mint', 0xFF6EE7B7, 0xFF065F46),
    ('Platin', 0xFFE5E7EB, 0xFF374151),
    ('Canlı Kırmızı', 0xFFDC2626, 0xFF1F2937),
  ];

  static final List<VoiceRoomTheme> samples = List.generate(
    _palette.length,
    (i) {
      final (name, primary, secondary) = _palette[i];
      final n = i + 1;
      return VoiceRoomTheme(
        id: 'room_theme_$n',
        name: name,
        primaryColor: primary,
        secondaryColor: secondary,
        backgroundUrl: '$_origin/images/voice-bg-$n.jpg',
        sortOrder: n,
      );
    },
  );
}
