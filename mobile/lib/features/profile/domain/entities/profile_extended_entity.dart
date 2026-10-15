import '../../../../core/util/json_util.dart';
import '../../../../core/auth/bot_account_guard.dart';

/// Genişletilmiş profil — `GET /api/user/profile` + `GET /api/me`.
class ProfileExtendedEntity {
  const ProfileExtendedEntity({
    this.city,
    this.zodiacSign,
    this.birthDate,
    this.birthTime,
    this.joinedAt,
    this.phone,
    this.isOnline = false,
    this.dailyStreak = 0,
    this.vipLevel,
    this.favoriteTeam,
    this.teamRaw,
    this.coverImage,
    this.raw = const {},
  });

  factory ProfileExtendedEntity.fromJson(Map<String, dynamic> json) {
    final m = json['user'] is Map
        ? asJsonMap(json['user'])
        : json['data'] is Map
            ? asJsonMap(json['data'])
            : json;
    final merged = {...json, ...m};

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final streak = asInt(pick(merged, [
      'dailyStreak',
      'loginStreak',
      'currentStreak',
      'streak',
      'streakDays',
    ]));

    final vipRaw = pick(merged, [
      'vipLevel',
      'vipTier',
      'membership',
      'membershipTier',
    ])?.toString();

    Map<String, dynamic>? teamRaw;
    final teamNode = merged['team'];
    if (teamNode is Map) teamRaw = asJsonMap(teamNode);

    return ProfileExtendedEntity(
      city: pick(merged, ['city', 'location', 'country'])?.toString(),
      zodiacSign: pick(merged, ['zodiacSign', 'zodiac', 'burc'])?.toString(),
      favoriteTeam:
          pick(merged, ['favoriteTeam', 'favorite_team', 'teamName'])?.toString(),
      teamRaw: teamRaw,
      birthDate: parseDate(pick(merged, ['birthDate', 'birthday', 'dateOfBirth'])),
      birthTime: pick(merged, ['birthTime', 'birth_time'])?.toString(),
      joinedAt: parseDate(
        pick(merged, ['createdAt', 'joinedAt', 'memberSince', 'registeredAt']),
      ),
      phone: pick(merged, ['phone', 'phoneNumber'])?.toString(),
      isOnline: merged['isOnline'] == true ||
          merged['online'] == true ||
          merged['presence'] == 'online',
      dailyStreak: streak,
      vipLevel: vipRaw?.trim().isNotEmpty == true ? vipRaw!.trim() : null,
      coverImage: pick(merged, [
        'coverImage',
        'coverUrl',
        'cover',
        'bannerUrl',
      ])?.toString(),
      raw: merged,
    );
  }

  final String? city;
  final String? zodiacSign;
  final DateTime? birthDate;
  final String? birthTime;
  final DateTime? joinedAt;
  final String? phone;
  final bool isOnline;
  final int dailyStreak;
  final String? vipLevel;
  final String? favoriteTeam;
  final Map<String, dynamic>? teamRaw;
  final String? coverImage;
  final Map<String, dynamic> raw;

  bool get isBot => BotAccountGuard.fromJsonMap(raw);
}

/// Kullanıcı istatistikleri — `GET /api/user/statistics`.
class ProfileUserStatisticsEntity {
  const ProfileUserStatisticsEntity({
    this.fortunesReceived = 0,
    this.fortuneComments = 0,
    this.liveWatchMinutes = 0,
    this.likedPosts = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likesReceived = 0,
    this.profileViews = 0,
    this.streamsHosted = 0,
  });

  factory ProfileUserStatisticsEntity.fromJson(Map<String, dynamic> json) {
    final m = json['data'] is Map ? asJsonMap(json['data']) : json;
    // `/api/user/statistics` iç içe döner: fortune.total, social.*, streams.*
    // (önceden düz anahtar arandığı için tüm satırlar hep 0 görünüyordu).
    Map<String, dynamic> sub(String k) =>
        m[k] is Map ? asJsonMap(m[k]) : const <String, dynamic>{};
    final fortune = sub('fortune');
    final social = sub('social');
    final streams = sub('streams');
    final watchRaw = pick(m, [
      'liveWatchMinutes',
      'liveWatchHours',
      'watchTimeMinutes',
      'streamWatchMinutes',
      'totalWatchMinutes',
    ]);
    var watchMinutes = asInt(watchRaw);
    if (watchRaw != null && m.containsKey('liveWatchHours')) {
      watchMinutes = asInt(m['liveWatchHours']) * 60;
    }

    return ProfileUserStatisticsEntity(
      fortunesReceived: asInt(pick(m, [
            'fortunesReceived',
            'fortuneCount',
            'fortunesCount',
            'readingsCount',
          ]) ??
          fortune['total']),
      fortuneComments: asInt(pick(m, [
        'fortuneComments',
        'fortuneCommentsCount',
        'readingsComments',
      ])),
      liveWatchMinutes: watchMinutes,
      likedPosts: asInt(pick(m, [
        'likedPosts',
        'likedPostsCount',
        'postsLiked',
      ])),
      commentsCount: asInt(pick(m, [
            'commentsCount',
            'comments',
            'totalComments',
          ]) ??
          social['commentsReceived']),
      sharesCount: asInt(pick(m, [
            'sharesCount',
            'postsShared',
            'shareCount',
          ]) ??
          social['totalPosts']),
      likesReceived: asInt(social['likesReceived']),
      profileViews: asInt(social['profileViews']),
      streamsHosted: asInt(streams['totalHosted']),
    );
  }

  final int fortunesReceived;
  final int fortuneComments;
  final int liveWatchMinutes;
  final int likedPosts;
  final int commentsCount;
  final int sharesCount;
  final int likesReceived;
  final int profileViews;
  final int streamsHosted;

  String get liveWatchLabel {
    if (liveWatchMinutes <= 0) return '0 dk';
    if (liveWatchMinutes < 60) return '$liveWatchMinutes dk';
    final hours = liveWatchMinutes ~/ 60;
    final mins = liveWatchMinutes % 60;
    if (mins == 0) return '$hours saat';
    return '$hours saat $mins dk';
  }
}
