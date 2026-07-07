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
  });

  final int rank;
  final String name;
  final String diamonds;
  final Color avatarColor;
}

abstract final class VoiceRoomsMockData {
  static const userName = 'Ayşe';
  static const vipLevel = 8;
  static const notificationCount = 12;

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

  static const featured = [
    FeaturedRoomItem(
      id: 'f1',
      title: 'Gece Sohbetleri',
      subtitle: 'Gece geç saatte samimi sohbetler',
      badge: 'Günün Öne Çıkan Odası',
      iconKey: 'mic',
      gradient: [Color(0xFF7B2FF7), Color(0xFF4A00E0)],
      glowColor: VoiceRoomsUiTokens.purpleGlow,
    ),
    FeaturedRoomItem(
      id: 'f2',
      title: 'Müzik Keyfi',
      subtitle: 'En güzel şarkılar burada',
      badge: 'Canlı DJ',
      iconKey: 'headphones',
      gradient: [Color(0xFF448AFF), Color(0xFF7C4DFF)],
      glowColor: VoiceRoomsUiTokens.blue,
    ),
  ];

  static const popularRooms = [
    PopularRoomItem(
      id: 'p1',
      rank: 1,
      title: 'Gece Sohbetleri',
      description: 'Samimi muhabbet, sıcak ortam',
      viewers: '2.5K',
      tags: ['Sohbet', '18+'],
      participantCount: 128,
      themeColor: VoiceRoomsUiTokens.purpleGlow,
      iconKey: 'mic',
      avatarColors: [
        Color(0xFF7C4DFF),
        Color(0xFFE040FB),
        Color(0xFF448AFF),
      ],
    ),
    PopularRoomItem(
      id: 'p2',
      rank: 2,
      title: 'Müzik & Chill',
      description: 'Lo-fi ve pop karışımı',
      viewers: '1.8K',
      tags: ['Müzik', 'Chill'],
      participantCount: 96,
      themeColor: VoiceRoomsUiTokens.teal,
      iconKey: 'music',
      avatarColors: [
        Color(0xFF00BFA5),
        Color(0xFF1DE9B6),
        Color(0xFF00E5FF),
      ],
    ),
    PopularRoomItem(
      id: 'p3',
      rank: 3,
      title: 'Aşk Köşesi',
      description: 'Kalp atışları ve flört',
      viewers: '1.2K',
      tags: ['Aşk', 'Flört'],
      participantCount: 74,
      themeColor: VoiceRoomsUiTokens.coral,
      iconKey: 'heart',
      avatarColors: [
        Color(0xFFFF5252),
        Color(0xFFFF4081),
        Color(0xFFFF80AB),
      ],
    ),
    PopularRoomItem(
      id: 'p4',
      rank: 4,
      title: 'Oyun Gecesi',
      description: 'Among Us & daha fazlası',
      viewers: '980',
      tags: ['Oyun', 'Eğlence'],
      participantCount: 52,
      themeColor: VoiceRoomsUiTokens.orange,
      iconKey: 'game',
      avatarColors: [
        Color(0xFFFF9100),
        Color(0xFFFFAB40),
        Color(0xFFFF6D00),
      ],
    ),
  ];

  static const nearbyTabs = [
    'Yakındaki Odalar',
    'Yeni Odalar',
    'Arkadaşların Odaları',
  ];

  static const nearbyRooms = [
    NearbyRoomItem(
      id: 'n1',
      title: 'Kahve Sohbeti',
      subtitle: 'Sıcak bir muhabbet için katıl',
      tags: ['Sohbet', 'Sakin'],
      distance: '0.3 km',
      viewers: '890',
      ringColor: VoiceRoomsUiTokens.onlineGreen,
      avatarColor: Color(0xFF7C4DFF),
    ),
    NearbyRoomItem(
      id: 'n2',
      title: 'DJ Emre Live',
      subtitle: 'Canlı set — house & techno',
      tags: ['Müzik', 'Canlı'],
      distance: '0.8 km',
      viewers: '1.4K',
      ringColor: VoiceRoomsUiTokens.onlineGreen,
      avatarColor: Color(0xFF448AFF),
    ),
    NearbyRoomItem(
      id: 'n3',
      title: 'Gece Kuşları',
      subtitle: 'Uykusuzlar kulübü',
      tags: ['Gece', '18+'],
      distance: '1.2 km',
      viewers: '620',
      ringColor: VoiceRoomsUiTokens.purpleGlow,
      avatarColor: Color(0xFFE040FB),
    ),
    NearbyRoomItem(
      id: 'n4',
      title: 'Fal & Tarot',
      subtitle: 'Yıldızlar konuşuyor',
      tags: ['Fal', 'Mistik'],
      distance: '2.1 km',
      viewers: '410',
      ringColor: VoiceRoomsUiTokens.gold,
      avatarColor: Color(0xFFFFD54F),
    ),
    NearbyRoomItem(
      id: 'n5',
      title: 'Valorant Squad',
      subtitle: 'Ranked arıyoruz',
      tags: ['Oyun', 'Competitive'],
      distance: '2.5 km',
      viewers: '330',
      ringColor: VoiceRoomsUiTokens.onlineGreen,
      avatarColor: Color(0xFF00E676),
    ),
    NearbyRoomItem(
      id: 'n6',
      title: 'Romantik Akşam',
      subtitle: 'Kalp atışları burada',
      tags: ['Aşk', 'Flört'],
      distance: '3.0 km',
      viewers: '280',
      ringColor: VoiceRoomsUiTokens.coral,
      avatarColor: Color(0xFFFF4081),
    ),
  ];

  static const trendingTopics = [
    TrendingTopicItem(tag: '#GeceSohbeti', views: '3.2K'),
    TrendingTopicItem(tag: '#MüzikKeyfi', views: '2.8K'),
    TrendingTopicItem(tag: '#FlörtKöşesi', views: '1.9K'),
    TrendingTopicItem(tag: '#OyunGecesi', views: '1.5K'),
    TrendingTopicItem(tag: '#FalTarot', views: '980'),
  ];

  static const activeSpeakers = [
    ActiveSpeakerItem(
      rank: 1,
      name: 'Zeynep ✨',
      diamonds: '12.5K',
      avatarColor: Color(0xFFFFD54F),
    ),
    ActiveSpeakerItem(
      rank: 2,
      name: 'Emre 🎧',
      diamonds: '9.8K',
      avatarColor: Color(0xFF448AFF),
    ),
    ActiveSpeakerItem(
      rank: 3,
      name: 'Selin 💜',
      diamonds: '7.2K',
      avatarColor: Color(0xFFE040FB),
    ),
  ];

  static const musicTitle = 'Müzik Keyfi';
  static const musicArtist = 'DJ Emre çalıyor';
  static const musicTrack = 'Midnight Pulse';
}
