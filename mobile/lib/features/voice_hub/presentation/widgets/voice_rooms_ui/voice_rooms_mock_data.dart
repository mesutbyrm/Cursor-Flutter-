import 'package:flutter/material.dart';

import 'voice_rooms_ui_tokens.dart';

class VoiceCategoryItem {
  const VoiceCategoryItem({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.colors,
    this.active = false,
  });

  final String id;
  final String label;
  final String iconKey;
  final List<Color> colors;
  final bool active;
}

class FeaturedRoomItem {
  const FeaturedRoomItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.iconKey,
    required this.gradient,
    required this.glowColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String iconKey;
  final List<Color> gradient;
  final Color glowColor;
}

class PopularRoomItem {
  const PopularRoomItem({
    required this.id,
    required this.rank,
    required this.title,
    required this.description,
    required this.viewers,
    required this.tags,
    required this.participantCount,
    required this.themeColor,
    required this.iconKey,
    required this.avatarColors,
  });

  final String id;
  final int rank;
  final String title;
  final String description;
  final String viewers;
  final List<String> tags;
  final int participantCount;
  final Color themeColor;
  final String iconKey;
  final List<Color> avatarColors;
}

class NearbyRoomItem {
  const NearbyRoomItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.distance,
    required this.viewers,
    required this.ringColor,
    required this.avatarColor,
    this.avatarUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
  final String distance;
  final String viewers;
  final Color ringColor;
  final Color avatarColor;
  final String? avatarUrl;
}

class TrendingTopicItem {
  const TrendingTopicItem({
    required this.tag,
    required this.views,
  });

  final String tag;
  final String views;
}

class ActiveSpeakerItem {
  const ActiveSpeakerItem({
    required this.rank,
    required this.name,
    required this.diamonds,
    required this.avatarColor,
    this.avatarUrl,
    this.onlineLabel,
  });

  final int rank;
  final String name;
  final String diamonds;
  final Color avatarColor;
  final String? avatarUrl;
  final String? onlineLabel;
}

/// Sabit kategori ve sekme etiketleri (adı tarihsel; sahte oda/kullanıcı
/// verisi içermez — oda, konuşmacı ve trend verileri API'den gelir).
abstract final class VoiceRoomsMockData {
  static const categories = [
    VoiceCategoryItem(
      id: 'all',
      label: 'Tümü',
      iconKey: 'soundwave',
      colors: [VoiceRoomsUiTokens.purpleStart, VoiceRoomsUiTokens.purpleEnd],
      active: true,
    ),
    VoiceCategoryItem(
      id: 'popular',
      label: 'Popüler',
      iconKey: 'fire',
      colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
    ),
    VoiceCategoryItem(
      id: 'chat',
      label: 'Sohbet',
      iconKey: 'chat',
      colors: [Color(0xFF448AFF), Color(0xFF2962FF)],
    ),
    VoiceCategoryItem(
      id: 'music',
      label: 'Müzik',
      iconKey: 'music',
      colors: [Color(0xFFE040FB), Color(0xFF9B4DFF)],
    ),
    VoiceCategoryItem(
      id: 'love',
      label: 'Aşk',
      iconKey: 'heart',
      colors: [Color(0xFFFF4081), Color(0xFFC51162)],
    ),
    VoiceCategoryItem(
      id: 'game',
      label: 'Oyun',
      iconKey: 'game',
      colors: [Color(0xFF00E676), Color(0xFF00C853)],
    ),
    VoiceCategoryItem(
      id: 'night',
      label: 'Gece',
      iconKey: 'moon',
      colors: [Color(0xFF7C4DFF), Color(0xFF311B92)],
    ),
  ];

  static const nearbyTabs = [
    'Yakındaki Odalar',
    'Yeni Odalar',
    'Arkadaşların Odaları',
  ];

}
