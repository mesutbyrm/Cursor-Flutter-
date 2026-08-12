import 'package:flutter/material.dart';

import '../../core/util/json_util.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/fortune/domain/entities/fortune_type_entity.dart';
import '../../features/home/domain/entities/home_banner_entity.dart';
import '../../features/home/domain/entities/home_fortune_card_entity.dart';
import '../../features/home/domain/entities/online_advisor_entity.dart';
import '../../features/live/domain/entities/live_stream_entity.dart';
import '../../features/live/domain/entities/voice_room_entity.dart';
import '../../features/profile/domain/entities/profile_extended_entity.dart';
import '../../features/profile/domain/entities/profile_stats_entity.dart';

/// `GET /api/mobile/home` — tek istekte ana sayfa verisi.
class MobileHomeBundle {
  const MobileHomeBundle({
    this.liveStreams = const [],
    this.voiceRooms = const [],
    this.fortuneCards = const [],
    this.banners = const [],
    this.advisors = const [],
    this.unreadNotifications,
    this.raw = const {},
  });

  final List<LiveStreamEntity> liveStreams;
  final List<VoiceRoomEntity> voiceRooms;
  final List<HomeFortuneCardEntity> fortuneCards;
  final List<HomeBannerEntity> banners;
  final List<OnlineAdvisorEntity> advisors;
  final int? unreadNotifications;
  final Map<String, dynamic> raw;

  factory MobileHomeBundle.fromJson(Map<String, dynamic> json) {
    return MobileHomeBundle(
      liveStreams: _mapList(json['liveStreams'], _mapLiveStream)
          .where((s) => s.id.isNotEmpty)
          .toList(growable: false),
      voiceRooms: _mapList(json['voiceRooms'], _mapVoiceRoom)
          .where((r) => r.id.isNotEmpty)
          .toList(growable: false),
      fortuneCards: _mapList(json['fortuneCards'], _mapFortuneCard)
          .where((c) => c.title.isNotEmpty)
          .toList(growable: false),
      banners: _mapList(json['announcements'], _mapAnnouncement)
          .where((b) => b.title.isNotEmpty)
          .toList(growable: false),
      advisors: _mapList(json['liveTellers'], _mapLiveTeller)
          .where((a) => a.id.isNotEmpty)
          .toList(growable: false),
      unreadNotifications: _int(
        json['user'] is Map ? asJsonMap(json['user'])['unreadNotifications'] : null,
      ),
      raw: json,
    );
  }
}

/// `GET /api/mobile/fortune-menu`
class MobileFortuneMenuBundle {
  const MobileFortuneMenuBundle({
    this.fortuneTypes = const [],
    this.fortuneCards = const [],
    this.jetonBalance = 0,
    this.creditBalance = 0,
    this.creditsPerMinute = 1,
    this.raw = const {},
  });

  final List<FortuneTypeEntity> fortuneTypes;
  final List<HomeFortuneCardEntity> fortuneCards;
  final int jetonBalance;
  final int creditBalance;
  final int creditsPerMinute;
  final Map<String, dynamic> raw;

  factory MobileFortuneMenuBundle.fromJson(Map<String, dynamic> json) {
    final credits = json['userCredits'] is Map
        ? asJsonMap(json['userCredits'])
        : const <String, dynamic>{};
    return MobileFortuneMenuBundle(
      fortuneTypes: _mapList(json['fortuneTypes'], _mapFortuneType)
          .where((t) => t.slug.isNotEmpty)
          .toList(growable: false),
      fortuneCards: _mapList(json['fortuneCards'], _mapFortuneCard)
          .where((c) => c.title.isNotEmpty)
          .toList(growable: false),
      jetonBalance: _int(credits['jetons']) ?? 0,
      creditBalance: _int(credits['credits']) ?? 0,
      creditsPerMinute: _int(json['creditsPerMinute']) ?? 1,
      raw: json,
    );
  }
}

/// `GET /api/mobile/user-profile/{userId}`
class MobileUserProfileBundle {
  const MobileUserProfileBundle({
    required this.user,
    this.stats = const ProfileStatsEntity(),
    this.extended = const ProfileExtendedEntity(),
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isOwnProfile = false,
    this.raw = const {},
  });

  final UserEntity user;
  final ProfileStatsEntity stats;
  final ProfileExtendedEntity extended;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isOwnProfile;
  final Map<String, dynamic> raw;

  factory MobileUserProfileBundle.fromJson(Map<String, dynamic> json) {
    final userMap =
        json['user'] is Map ? asJsonMap(json['user']) : <String, dynamic>{};
    final statsMap =
        json['stats'] is Map ? asJsonMap(json['stats']) : <String, dynamic>{};
    final rel = json['relationship'] is Map
        ? asJsonMap(json['relationship'])
        : <String, dynamic>{};

    return MobileUserProfileBundle(
      user: UserEntity(
        id: userMap['id']?.toString() ?? '',
        username: userMap['username']?.toString() ??
            userMap['name']?.toString() ??
            '',
        displayName: userMap['name']?.toString(),
        avatarUrl: _str(userMap, ['profileImageUrl', 'image', 'avatarUrl']),
        bio: userMap['bio']?.toString(),
        followersCount: _int(statsMap['followerCount']) ?? 0,
        followingCount: _int(statsMap['followingCount']) ?? 0,
        isFollowing: rel['isFollowing'] == true,
        isVerified: userMap['role']?.toString() == 'admin',
        coinBalance: _int(userMap['jetons']) ?? 0,
      ),
      stats: ProfileStatsEntity(
        followers: _int(statsMap['followerCount']) ?? 0,
        following: _int(statsMap['followingCount']) ?? 0,
        likes: _int(statsMap['postCount']) ?? 0,
        giftsReceivedCount: _int(statsMap['totalGiftsReceived']) ?? 0,
        giftsReceivedCoins: _int(statsMap['totalGiftsSent']) ?? 0,
      ),
      extended: ProfileExtendedEntity.fromJson({
        ...userMap,
        'isOnline': userMap['isOnline'],
      }),
      isFollowing: rel['isFollowing'] == true,
      isFollowedBy: rel['isFollowedBy'] == true,
      isOwnProfile: json['isOwnProfile'] == true,
      raw: json,
    );
  }
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) map) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => map(asJsonMap(e)))
      .toList(growable: false);
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String? _str(Map<String, dynamic> m, List<String> keys) {
  final v = pick(m, keys);
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

LiveStreamEntity _mapLiveStream(Map<String, dynamic> m) {
  return LiveStreamEntity(
    id: m['id']?.toString() ?? '',
    title: m['title']?.toString() ?? 'Canlı Yayın',
    streamerName: m['hostName']?.toString(),
    thumbnailUrl: _str(m, ['thumbnailUrl', 'hostAvatar', 'imageUrl']),
    viewerCount: _int(m['listenerCount'] ?? m['viewerCount']) ?? 0,
    isLive: m['isLive'] != false,
    hostUserId: m['hostId']?.toString(),
  );
}

VoiceRoomEntity _mapVoiceRoom(Map<String, dynamic> m) {
  return VoiceRoomEntity(
    id: m['id']?.toString() ?? '',
    slug: m['slug']?.toString() ?? '',
    nameTr: m['name']?.toString() ?? m['title']?.toString() ?? 'Oda',
    descTr: m['description']?.toString(),
    icon: m['icon']?.toString(),
    category: m['category']?.toString(),
    onlineCount: _int(m['listenerCount'] ?? m['viewerCount']) ?? 0,
    userCount: _int(m['listenerCount'] ?? m['viewerCount']) ?? 0,
    backgroundImageUrl: _str(m, ['imageUrl', 'backgroundImage']),
    ownerName: m['hostName']?.toString(),
    ownerId: m['hostId']?.toString(),
    roomType: 'voice',
    seatCount: _int(m['seatCount']),
    maxUsers: _int(m['maxUsers']),
  );
}

HomeFortuneCardEntity _mapFortuneCard(Map<String, dynamic> m) {
  final slug = _str(m, ['slug', 'fortuneType', 'fortuneSlug']) ?? '';
  return HomeFortuneCardEntity(
    id: _str(m, ['id']) ?? slug,
    title: _str(m, ['title', 'name']) ?? '',
    slug: slug,
    icon: _str(m, ['icon', 'emoji']) ?? '🔮',
    imageUrl: _str(m, ['iconUrl', 'imageUrl', 'thumbnail']),
  );
}

HomeBannerEntity _mapAnnouncement(Map<String, dynamic> m) {
  return HomeBannerEntity(
    id: m['id']?.toString() ?? '',
    title: m['message']?.toString() ?? '',
    subtitle: m['userName']?.toString(),
  );
}

OnlineAdvisorEntity _mapLiveTeller(Map<String, dynamic> m) {
  final user = m['user'] is Map ? asJsonMap(m['user']) : m;
  final specs = m['specialties'];
  final specialties = specs is List
      ? specs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
      : const <String>[];
  return OnlineAdvisorEntity(
    id: m['id']?.toString() ?? user['id']?.toString() ?? '',
    name: user['name']?.toString() ?? '',
    category: specialties.isNotEmpty ? specialties.first : null,
    avatarUrl: _str(user, ['profileImageUrl', 'image']),
    isOnline: m['isActive'] != false,
    rating: (m['rating'] as num?)?.toDouble() ?? 0,
    viewerCount: 0,
    specialties: specialties,
  );
}

FortuneTypeEntity _mapFortuneType(Map<String, dynamic> m) {
  return FortuneTypeEntity(
    id: m['id']?.toString() ?? m['slug']?.toString() ?? '',
    slug: m['slug']?.toString() ?? '',
    title: m['nameTr']?.toString() ?? m['nameEn']?.toString() ?? '',
    description: m['descriptionTr']?.toString() ??
        m['descriptionEn']?.toString() ??
        '',
    emoji: '🔮',
    accent: const Color(0xFFB832FF),
    kind: FortuneSessionKind.generic,
    ctaLabel: 'Falını Aç',
  );
}
