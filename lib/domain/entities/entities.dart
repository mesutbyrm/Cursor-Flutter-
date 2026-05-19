enum MembershipTier { free, fan, premium, vip }

enum BadgeKind { verified, topCreator, oracle, moderator, founder }

enum StreamStatus { scheduled, live, ended }

enum FortuneCategory { coffee, tarot, astrology, dream, numerology }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.coverUrl,
    required this.bio,
    required this.followers,
    required this.following,
    required this.level,
    required this.coins,
    required this.tier,
    required this.badges,
    this.isFollowing = false,
    this.isOnline = true,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final int followers;
  final int following;
  final int level;
  final int coins;
  final MembershipTier tier;
  final List<BadgeKind> badges;
  final bool isFollowing;
  final bool isOnline;

  AppUser copyWith({
    int? followers,
    int? following,
    int? level,
    int? coins,
    MembershipTier? tier,
    List<BadgeKind>? badges,
    bool? isFollowing,
    bool? isOnline,
  }) {
    return AppUser(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      tier: tier ?? this.tier,
      badges: badges ?? this.badges,
      isFollowing: isFollowing ?? this.isFollowing,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final String id = _string(json, <String>['id', 'userId']) ?? 'user';
    final String displayName =
        _string(json, <String>['displayName', 'name', 'channelName']) ??
        'Canlifal';
    final String username =
        _string(json, <String>['username', 'slug']) ??
        displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final String avatar =
        _string(json, <String>['avatarUrl', 'avatar', 'image']) ??
        CanlifalAssets.avatarPlaceholder;
    return AppUser(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatar,
      coverUrl:
          _string(json, <String>['coverUrl', 'cover', 'backgroundImage']) ??
          avatar,
      bio: json['bio'] as String? ?? '',
      followers: _int(json, <String>['followers', 'followerCount']) ?? 0,
      following: _int(json, <String>['following', 'followingCount']) ?? 0,
      level: _int(json, <String>['level', 'levelPoints']) ?? 1,
      coins: _int(json, <String>['coins', 'credits', 'balance']) ?? 0,
      tier: MembershipTier.values.firstWhere(
        (MembershipTier tier) => tier.name == json['tier'],
        orElse: () => MembershipTier.free,
      ),
      badges: const <BadgeKind>[BadgeKind.verified],
      isFollowing: json['isFollowing'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }
}

class StoryItem {
  const StoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.owner,
    this.isLive = false,
  });

  final String id;
  final String title;
  final String imageUrl;
  final AppUser owner;
  final bool isLive;
}

class ContentPost {
  const ContentPost({
    required this.id,
    required this.author,
    required this.caption,
    required this.mediaUrl,
    required this.hashtags,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.createdLabel,
    this.isVideo = false,
    this.isSaved = false,
  });

  final String id;
  final AppUser author;
  final String caption;
  final String mediaUrl;
  final List<String> hashtags;
  final int likes;
  final int comments;
  final int saves;
  final String createdLabel;
  final bool isVideo;
  final bool isSaved;

  factory ContentPost.fromTrendVideoJson(Map<String, dynamic> json) {
    final Map<String, dynamic> category =
        json['category'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final String title = json['title'] as String? ?? 'Canlifal video';
    final String channel = json['channelName'] as String? ?? 'Canlifal';
    final String id =
        json['id'] as String? ?? json['youtubeId'] as String? ?? title;
    return ContentPost(
      id: id,
      author: AppUser.fromJson(<String, dynamic>{
        'id': channel,
        'displayName': channel,
        'username': channel,
      }),
      caption: title,
      mediaUrl:
          json['thumbnailUrl'] as String? ?? CanlifalAssets.coverPlaceholder,
      hashtags: <String>[
        '#video',
        if (category['title'] is String) '#${category['title']}',
      ],
      likes: _int(json, <String>['viewCount']) ?? 0,
      comments: 0,
      saves: 0,
      createdLabel: json['duration'] as String? ?? '',
      isVideo: true,
    );
  }

  factory ContentPost.fromCelebrityPostJson(Map<String, dynamic> json) {
    final Map<String, dynamic> celebrity =
        json['celebrity'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final String id = json['id'] as String? ?? 'post';
    return ContentPost(
      id: id,
      author: AppUser.fromJson(celebrity),
      caption: json['content'] as String? ?? '',
      mediaUrl:
          json['imageUrl'] as String? ??
          json['mediaUrl'] as String? ??
          celebrity['image'] as String? ??
          CanlifalAssets.coverPlaceholder,
      hashtags: <String>[
        if (json['platform'] is String) '#${json['platform']}',
        if (json['postType'] is String) '#${json['postType']}',
      ],
      likes: _int(json, <String>['likeCount', 'likes']) ?? 0,
      comments: _int(json, <String>['commentCount', 'comments']) ?? 0,
      saves: _int(json, <String>['saveCount', 'saves']) ?? 0,
      createdLabel: _dateLabel(json['createdAt'] as String?),
      isVideo: json['postType'] == 'video',
    );
  }
}

class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.host,
    required this.thumbnailUrl,
    required this.watchUrl,
    required this.viewers,
    required this.status,
    required this.tags,
    this.playbackUrl,
    this.liveKitToken,
    this.chatRoomId,
    this.isMultiGuest = false,
  });

  final String id;
  final String title;
  final String description;
  final AppUser host;
  final String thumbnailUrl;
  final String watchUrl;
  final int viewers;
  final StreamStatus status;
  final List<String> tags;
  final String? playbackUrl;
  final String? liveKitToken;
  final String? chatRoomId;
  final bool isMultiGuest;

  bool get hasNativePlayback =>
      playbackUrl != null && playbackUrl!.trim().isNotEmpty;

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] as String? ?? 'live',
      title: json['title'] as String? ?? 'Canlı Yayın',
      description:
          json['description'] as String? ?? 'Canlifal canlı yayın odası.',
      host: AppUser.fromJson(
        json['host'] as Map<String, dynamic>? ??
            json['broadcaster'] as Map<String, dynamic>? ??
            json['user'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
      thumbnailUrl:
          json['thumbnailUrl'] as String? ??
          json['thumbnail'] as String? ??
          CanlifalAssets.coverPlaceholder,
      watchUrl:
          json['watchUrl'] as String? ?? 'https://canlifal.com/canli-yayinlar',
      viewers:
          _int(json, <String>['viewers', 'viewerCount', 'totalViewers']) ?? 0,
      status: StreamStatus.values.firstWhere(
        (StreamStatus status) => status.name == json['status'],
        orElse: () => StreamStatus.live,
      ),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      playbackUrl:
          json['playbackUrl'] as String? ??
          json['hlsUrl'] as String? ??
          json['streamUrl'] as String?,
      liveKitToken: json['liveKitToken'] as String? ?? json['token'] as String?,
      chatRoomId: json['chatRoomId'] as String? ?? json['roomId'] as String?,
      isMultiGuest: json['isMultiGuest'] as bool? ?? false,
    );
  }
}

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.topic,
    required this.avatarUrl,
    required this.onlineCount,
    required this.unreadCount,
    required this.isVoice,
    required this.moderators,
  });

  final String id;
  final String name;
  final String topic;
  final String avatarUrl;
  final int onlineCount;
  final int unreadCount;
  final bool isVoice;
  final List<AppUser> moderators;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> owner =
        json['owner'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ChatRoom(
      id: json['id'] as String? ?? json['slug'] as String? ?? 'room',
      name:
          json['nameTr'] as String? ??
          json['name'] as String? ??
          json['nameEn'] as String? ??
          'Sohbet',
      topic:
          json['descTr'] as String? ??
          json['topic'] as String? ??
          json['descEn'] as String? ??
          '',
      avatarUrl:
          json['backgroundImage'] as String? ??
          owner['image'] as String? ??
          CanlifalAssets.coverPlaceholder,
      onlineCount: _int(json, <String>['onlineCount']) ?? 0,
      unreadCount: _int(json, <String>['unreadCount', 'messageCount']) ?? 0,
      isVoice: json['isVoice'] as bool? ?? json['activeDjId'] != null,
      moderators: <AppUser>[if (owner.isNotEmpty) AppUser.fromJson(owner)],
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.sentAt,
    this.isGift = false,
  });

  final String id;
  final AppUser sender;
  final String body;
  final String sentAt;
  final bool isGift;
}

class FortuneService {
  const FortuneService({
    required this.id,
    required this.category,
    required this.title,
    required this.advisor,
    required this.rating,
    required this.priceCoins,
    required this.queueCount,
    required this.isLive,
  });

  final String id;
  final FortuneCategory category;
  final String title;
  final AppUser advisor;
  final double rating;
  final int priceCoins;
  final int queueCount;
  final bool isLive;

  factory FortuneService.fromTellerJson(Map<String, dynamic> json) {
    final List<String> specialties =
        (json['specialties'] as List<dynamic>?)?.whereType<String>().toList() ??
        const <String>[];
    return FortuneService(
      id: json['id'] as String? ?? 'fortune-teller',
      category: _categoryFromSpecialty(
        specialties.isEmpty ? null : specialties.first,
      ),
      title: json['displayName'] as String? ?? 'Canlı Falcı',
      advisor: AppUser.fromJson(json),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      priceCoins: _int(json, <String>['pricePerSession']) ?? 0,
      queueCount: _int(json, <String>['pendingSessions', 'queueCount']) ?? 0,
      isLive: json['isOnline'] as bool? ?? false,
    );
  }

  factory FortuneService.fromCardJson(Map<String, dynamic> json) {
    return FortuneService(
      id: json['id'] as String? ?? json['href'] as String? ?? 'fortune-card',
      category: _categoryFromSpecialty(
        json['href'] as String? ?? json['name'] as String?,
      ),
      title: json['name'] as String? ?? 'Fal',
      advisor: AppUser.fromJson(<String, dynamic>{
        'displayName': 'Canlifal',
        'image': json['image'],
      }),
      rating: 0,
      priceCoins: 0,
      queueCount: 0,
      isLive: false,
    );
  }
}

class GiftItem {
  const GiftItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.priceCoins,
  });

  final String id;
  final String name;
  final String emoji;
  final int priceCoins;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.createdLabel,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String icon;
  final String createdLabel;
  final bool isRead;
}

class AdminMetric {
  const AdminMetric({
    required this.title,
    required this.value,
    required this.delta,
  });

  final String title;
  final String value;
  final String delta;
}

class CanlifalAssets {
  static const String avatarPlaceholder = 'https://canlifal.com/favicon.ico';
  static const String coverPlaceholder =
      'https://canlifal.com/apple-touch-icon.png';

  static const List<GiftItem> gifts = <GiftItem>[
    GiftItem(id: 'gift-rose', name: 'Gül', emoji: '🌹', priceCoins: 25),
    GiftItem(id: 'gift-star', name: 'Yıldız', emoji: '✨', priceCoins: 75),
    GiftItem(id: 'gift-crown', name: 'Taç', emoji: '👑', priceCoins: 250),
    GiftItem(id: 'gift-galaxy', name: 'Galaksi', emoji: '🌌', priceCoins: 900),
  ];
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
  }
  return null;
}

String _dateLabel(String? iso) {
  if (iso == null) {
    return '';
  }
  final DateTime? date = DateTime.tryParse(iso);
  if (date == null) {
    return '';
  }
  final Duration diff = DateTime.now().difference(date);
  if (diff.inDays > 0) {
    return '${diff.inDays} gün';
  }
  if (diff.inHours > 0) {
    return '${diff.inHours} sa';
  }
  return '${diff.inMinutes.clamp(0, 59)} dk';
}

FortuneCategory _categoryFromSpecialty(String? value) {
  final String normalized = (value ?? '').toLowerCase();
  if (normalized.contains('tarot')) {
    return FortuneCategory.tarot;
  }
  if (normalized.contains('astro') || normalized.contains('burc')) {
    return FortuneCategory.astrology;
  }
  if (normalized.contains('ruya') || normalized.contains('rüya')) {
    return FortuneCategory.dream;
  }
  if (normalized.contains('numeroloji')) {
    return FortuneCategory.numerology;
  }
  return FortuneCategory.coffee;
}
