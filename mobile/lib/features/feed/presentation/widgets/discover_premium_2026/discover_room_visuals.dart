import 'package:flutter/material.dart';

import '../../../domain/discover_category.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';

/// Oda kartı arka planı — backend görseli yoksa kategori teması.
abstract final class DiscoverRoomVisuals {
  static const _fortune = [Color(0xFF4A148C), Color(0xFF1A237E)];
  static const _tarot = [Color(0xFF311B92), Color(0xFF880E4F)];
  static const _burc = [Color(0xFF0D47A1), Color(0xFF4A148C)];
  static const _gold = [Color(0xFFFFB300), Color(0xFFE65100)];
  static const _kahve = [Color(0xFF5D4037), Color(0xFF3E2723)];
  static const _night = [Color(0xFF4C1D95), Color(0xFF1E1033)];
  static const _music = [Color(0xFFFF2D7A), Color(0xFF9B4DFF)];
  static const _default = [Color(0xFF4C1D95), Color(0xFF1E1033)];

  static List<Color> gradientFor(VoiceRoomEntity room) {
    final t =
        '${room.nameTr} ${room.descTr ?? ''} ${room.slug} ${room.roomType ?? ''}'
            .toLowerCase();

    if (t.contains('burc') || t.contains('zodiac') || t.contains('astro')) {
      return _burc;
    }
    if (t.contains('tarot')) return _tarot;
    if (t.contains('kahve') || t.contains('coffee')) return _kahve;
    if (t.contains('fal') || t.contains('mistik') || t.contains('spirit')) {
      return _fortune;
    }
    if (room.isVip == true ||
        t.contains('gold') ||
        t.contains('vip') ||
        t.contains('premium')) {
      return _gold;
    }
    if (matchesDiscoverCategory(room, 'music')) return _music;
    if (matchesDiscoverCategory(room, 'night')) return _night;
    if (matchesDiscoverCategory(room, 'fortune')) return _fortune;
    if (matchesDiscoverCategory(room, 'vip')) return _gold;

    return _default;
  }

  static Decoration fallbackDecoration(VoiceRoomEntity room) {
    final colors = gradientFor(room);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    );
  }

  static String? categoryLabel(VoiceRoomEntity room) {
    final t =
        '${room.nameTr} ${room.descTr ?? ''} ${room.slug}'.toLowerCase();
    if (t.contains('tarot')) return 'Tarot';
    if (t.contains('burc') || t.contains('zodiac')) return 'Burç';
    if (t.contains('kahve')) return 'Kahve Falı';
    if (t.contains('fal')) return 'Fal';
    if (room.isVip == true || t.contains('gold')) return 'Gold';
    if (t.contains('vip')) return 'VIP';
    return null;
  }
}
