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
    return AppUser(
      id: json['id'] as String? ?? 'user-local',
      username: json['username'] as String? ?? 'canlifal',
      displayName: json['displayName'] as String? ?? 'Canlifal Üyesi',
      avatarUrl: json['avatarUrl'] as String? ?? CanlifalSeed.avatar(0),
      coverUrl: json['coverUrl'] as String? ?? CanlifalSeed.cover(0),
      bio: json['bio'] as String? ?? 'Canlifal topluluğunda aktif.',
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      coins: json['coins'] as int? ?? 250,
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
}

class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.host,
    required this.thumbnailUrl,
    required this.viewers,
    required this.status,
    required this.tags,
    this.isMultiGuest = false,
  });

  final String id;
  final String title;
  final AppUser host;
  final String thumbnailUrl;
  final int viewers;
  final StreamStatus status;
  final List<String> tags;
  final bool isMultiGuest;
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

class CanlifalSeed {
  static String avatar(int index) =>
      'https://images.unsplash.com/photo-${_avatars[index % _avatars.length]}?auto=format&fit=crop&w=400&q=80';

  static String cover(int index) =>
      'https://images.unsplash.com/photo-${_covers[index % _covers.length]}?auto=format&fit=crop&w=1200&q=80';

  static const List<String> _avatars = <String>[
    '1494790108377-be9c29b29330',
    '1500648767791-00dcc994a43e',
    '1534528741775-53994a69daeb',
    '1507003211169-0a1dd7228f2d',
    '1517841905240-472988babdf9',
    '1527980965255-d3b416303d12',
  ];

  static const List<String> _covers = <String>[
    '1519608487953-e999c86e7455',
    '1500530855697-b586d89ba3ee',
    '1492684223066-81342ee5ff30',
    '1519681393784-d120267933ba',
    '1500534314209-a25ddb2bd429',
  ];

  static final List<AppUser> users = <AppUser>[
    AppUser(
      id: 'u1',
      username: 'mysticmelis',
      displayName: 'Melis Yıldız',
      avatarUrl: avatar(0),
      coverUrl: cover(0),
      bio: 'Kahve falı, ilişki enerjisi ve canlı danışmanlık.',
      followers: 128400,
      following: 146,
      level: 42,
      coins: 4200,
      tier: MembershipTier.vip,
      badges: const <BadgeKind>[BadgeKind.verified, BadgeKind.oracle],
    ),
    AppUser(
      id: 'u2',
      username: 'tarotkaan',
      displayName: 'Kaan Tarot',
      avatarUrl: avatar(1),
      coverUrl: cover(1),
      bio: 'Gece canlıları, tarot açılımları ve kolektif enerji.',
      followers: 89200,
      following: 214,
      level: 35,
      coins: 3100,
      tier: MembershipTier.premium,
      badges: const <BadgeKind>[BadgeKind.verified, BadgeKind.topCreator],
      isFollowing: true,
    ),
    AppUser(
      id: 'u3',
      username: 'astroasya',
      displayName: 'Asya Astroloji',
      avatarUrl: avatar(2),
      coverUrl: cover(2),
      bio: 'Doğum haritası, transitler ve haftalık astroloji.',
      followers: 154000,
      following: 98,
      level: 48,
      coins: 8700,
      tier: MembershipTier.vip,
      badges: const <BadgeKind>[BadgeKind.verified, BadgeKind.founder],
    ),
  ];

  static final AppUser currentUser = AppUser(
    id: 'me',
    username: 'canlifal_user',
    displayName: 'Canlifal Kullanıcısı',
    avatarUrl: avatar(4),
    coverUrl: cover(4),
    bio: 'Fal, canlı yayın ve sosyal keşif dünyasında.',
    followers: 1240,
    following: 389,
    level: 12,
    coins: 1250,
    tier: MembershipTier.premium,
    badges: const <BadgeKind>[BadgeKind.verified],
  );

  static final List<StoryItem> stories = <StoryItem>[
    for (int i = 0; i < users.length; i++)
      StoryItem(
        id: 'story-$i',
        title: users[i].displayName,
        imageUrl: users[i].avatarUrl,
        owner: users[i],
        isLive: i != 1,
      ),
  ];

  static List<ContentPost> feedPage(int page) {
    return List<ContentPost>.generate(6, (int index) {
      final int seed = page * 6 + index;
      final AppUser author = users[seed % users.length];
      return ContentPost(
        id: 'post-$seed',
        author: author,
        caption: <String>[
          'Bugünün enerjisi yüksek. Canlı yayında kahve fincanlarını yorumluyoruz.',
          'Yeni tarot serisi yayında. Aşk, kariyer ve para için üç kart açılımı.',
          'FanClub üyeleri için özel yayın ve coin hediyeleri başladı.',
        ][seed % 3],
        mediaUrl: cover(seed),
        hashtags: <String>['#canlifal', '#tarot', '#keşfet', '#canlı'],
        likes: 1240 + seed * 37,
        comments: 86 + seed * 5,
        saves: 340 + seed * 11,
        createdLabel: '${seed + 2} dk',
        isVideo: seed.isEven,
        isSaved: seed % 4 == 0,
      );
    });
  }

  static final List<LiveStream> liveStreams = <LiveStream>[
    LiveStream(
      id: 'live-1',
      title: 'Kahve Falı Gecesi',
      host: users[0],
      thumbnailUrl: cover(0),
      viewers: 18400,
      status: StreamStatus.live,
      tags: const <String>['Kahve', 'Canlı Fal', 'Hediye'],
      isMultiGuest: true,
    ),
    LiveStream(
      id: 'live-2',
      title: 'Tarot ile Aşk Açılımı',
      host: users[1],
      thumbnailUrl: cover(1),
      viewers: 12600,
      status: StreamStatus.live,
      tags: const <String>['Tarot', 'Aşk', 'Soru-Cevap'],
    ),
    LiveStream(
      id: 'live-3',
      title: 'Astroloji Harita Okuması',
      host: users[2],
      thumbnailUrl: cover(2),
      viewers: 24100,
      status: StreamStatus.live,
      tags: const <String>['Astroloji', 'Premium', 'FanClub'],
      isMultiGuest: true,
    ),
  ];

  static final List<ChatRoom> rooms = <ChatRoom>[
    ChatRoom(
      id: 'room-1',
      name: 'Gece Fal Sohbeti',
      topic: 'Kahve falı bekleyenler ve canlı yorumlar',
      avatarUrl: cover(3),
      onlineCount: 864,
      unreadCount: 12,
      isVoice: false,
      moderators: <AppUser>[users[0]],
    ),
    ChatRoom(
      id: 'room-2',
      name: 'Sesli Tarot Odası',
      topic: 'Discord hissinde sesli topluluk odası',
      avatarUrl: cover(1),
      onlineCount: 342,
      unreadCount: 4,
      isVoice: true,
      moderators: <AppUser>[users[1], users[2]],
    ),
  ];

  static final List<ChatMessage> messages = <ChatMessage>[
    ChatMessage(
      id: 'm1',
      sender: users[0],
      body: 'Yayına hoş geldiniz!',
      sentAt: '23:12',
    ),
    ChatMessage(
      id: 'm2',
      sender: users[1],
      body: 'Coin hediyeleri açıldı.',
      sentAt: '23:13',
      isGift: true,
    ),
    ChatMessage(
      id: 'm3',
      sender: currentUser,
      body: 'Tarot sırası alabilir miyim?',
      sentAt: '23:14',
    ),
  ];

  static final List<FortuneService> fortunes = <FortuneService>[
    FortuneService(
      id: 'fortune-1',
      category: FortuneCategory.coffee,
      title: 'Canlı Kahve Falı',
      advisor: users[0],
      rating: 4.9,
      priceCoins: 220,
      queueCount: 8,
      isLive: true,
    ),
    FortuneService(
      id: 'fortune-2',
      category: FortuneCategory.tarot,
      title: 'Üç Kart Tarot',
      advisor: users[1],
      rating: 4.8,
      priceCoins: 180,
      queueCount: 5,
      isLive: true,
    ),
    FortuneService(
      id: 'fortune-3',
      category: FortuneCategory.astrology,
      title: 'Doğum Haritası',
      advisor: users[2],
      rating: 5,
      priceCoins: 450,
      queueCount: 13,
      isLive: false,
    ),
  ];

  static const List<GiftItem> gifts = <GiftItem>[
    GiftItem(id: 'gift-rose', name: 'Gül', emoji: '🌹', priceCoins: 25),
    GiftItem(id: 'gift-star', name: 'Yıldız', emoji: '✨', priceCoins: 75),
    GiftItem(id: 'gift-crown', name: 'Taç', emoji: '👑', priceCoins: 250),
    GiftItem(id: 'gift-galaxy', name: 'Galaksi', emoji: '🌌', priceCoins: 900),
  ];

  static const List<NotificationItem> notifications = <NotificationItem>[
    NotificationItem(
      id: 'n1',
      title: 'Canlı yayın başladı',
      body: 'Melis Yıldız kahve falı yayınına geçti.',
      icon: '🔴',
      createdLabel: 'Şimdi',
    ),
    NotificationItem(
      id: 'n2',
      title: 'Yeni FanClub içeriği',
      body: 'Premium üyeler için özel tarot açılımı yayınlandı.',
      icon: '💜',
      createdLabel: '8 dk',
    ),
  ];

  static const List<AdminMetric> adminMetrics = <AdminMetric>[
    AdminMetric(title: 'Aktif kullanıcı', value: '42.8K', delta: '+12%'),
    AdminMetric(title: 'Canlı yayın', value: '128', delta: '+8%'),
    AdminMetric(title: 'Coin hacmi', value: '3.4M', delta: '+19%'),
    AdminMetric(title: 'Şikayet kuyruğu', value: '24', delta: '-6%'),
  ];
}
