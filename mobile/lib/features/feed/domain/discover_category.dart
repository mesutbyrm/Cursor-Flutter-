import 'package:flutter/material.dart';

import '../../live/domain/entities/voice_room_entity.dart';

/// Keşfet kategori tanımları (PART 2).
class DiscoverCategoryDef {
  const DiscoverCategoryDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Color> gradient;
}

abstract final class DiscoverCategories {
  static const all = <DiscoverCategoryDef>[
    DiscoverCategoryDef(
      id: 'night',
      label: 'Gece Muhabbeti',
      icon: Icons.nightlight_round,
      gradient: [Color(0xFF5B7CFF), Color(0xFF1E3A8A)],
    ),
    DiscoverCategoryDef(
      id: 'game',
      label: 'Oyun',
      icon: Icons.sports_esports_rounded,
      gradient: [Color(0xFF00E5C3), Color(0xFF00695C)],
    ),
    DiscoverCategoryDef(
      id: 'fortune',
      label: 'Fal & Tarot',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFFFD54F), Color(0xFFB8860B)],
    ),
    DiscoverCategoryDef(
      id: 'music',
      label: 'Müzik',
      icon: Icons.music_note_rounded,
      gradient: [Color(0xFFFF2D7A), Color(0xFF9B4DFF)],
    ),
    DiscoverCategoryDef(
      id: 'pk',
      label: 'PK',
      icon: Icons.flash_on_rounded,
      gradient: [Color(0xFFFF6B35), Color(0xFFB832FF)],
    ),
    DiscoverCategoryDef(
      id: 'vip',
      label: 'VIP',
      icon: Icons.workspace_premium_rounded,
      gradient: [Color(0xFFFFE082), Color(0xFFFF8F00)],
    ),
    DiscoverCategoryDef(
      id: 'entertainment',
      label: 'Eğlence',
      icon: Icons.celebration_rounded,
      gradient: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
    ),
    DiscoverCategoryDef(
      id: 'flirt',
      label: 'Flört',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFFF5C8A), Color(0xFF9C27B0)],
    ),
  ];
}

bool matchesDiscoverCategory(VoiceRoomEntity room, String categoryId) {
  final t = '${room.nameTr} ${room.descTr ?? ''} ${room.slug}'.toLowerCase();
  switch (categoryId) {
    case 'night':
      return t.contains('gece') ||
          t.contains('night') ||
          t.contains('muhabbet') ||
          t.contains('sohbet');
    case 'game':
      return t.contains('oyun') || t.contains('game');
    case 'fortune':
      return t.contains('fal') ||
          t.contains('tarot') ||
          t.contains('spirit') ||
          t.contains('mistik');
    case 'music':
      return t.contains('müzik') ||
          t.contains('muzik') ||
          t.contains('music') ||
          t.contains('dj');
    case 'pk':
      return t.contains('pk') || t.contains('savaş') || t.contains('battle');
    case 'vip':
      return t.contains('vip') || t.contains('gold') || t.contains('premium');
    case 'flirt':
      return t.contains('flört') ||
          t.contains('flort') ||
          t.contains('flirt') ||
          t.contains('dating');
    case 'entertainment':
      return t.contains('eğlence') ||
          t.contains('eglence') ||
          t.contains('party') ||
          t.contains('fun');
    default:
      return true;
  }
}

List<VoiceRoomEntity> filterDiscoverRooms({
  required List<VoiceRoomEntity> rooms,
  String? categoryId,
  String query = '',
}) {
  var out = rooms;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    out = out
        .where(
          (r) =>
              r.displayTitle.toLowerCase().contains(q) ||
              r.slug.toLowerCase().contains(q) ||
              (r.ownerName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
  if (categoryId != null && categoryId.isNotEmpty) {
    out = out.where((r) => matchesDiscoverCategory(r, categoryId)).toList();
  }
  return out;
}

List<VoiceRoomEntity> trendingRooms(List<VoiceRoomEntity> rooms, {int limit = 8}) {
  final sorted = List<VoiceRoomEntity>.from(rooms)
    ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
  return sorted.take(limit).toList();
}

List<VoiceRoomEntity> vipRooms(List<VoiceRoomEntity> rooms) =>
    rooms.where((r) => matchesDiscoverCategory(r, 'vip')).toList();
