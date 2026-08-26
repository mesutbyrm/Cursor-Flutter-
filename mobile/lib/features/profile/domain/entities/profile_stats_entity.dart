import '../../../../core/util/json_util.dart';

class ProfileStatsEntity {
  const ProfileStatsEntity({
    this.liveStreams = 0,
    this.likes = 0,
    this.followers = 0,
    this.following = 0,
    this.giftsReceivedCount = 0,
    this.giftsReceivedCoins = 0,
    this.earningsJeton = 0,
    this.approvedTopUpTotal = 0,
    this.profileViews = 0,
  });

  factory ProfileStatsEntity.fromJson(Map<String, dynamic> json) {
    final m = json['data'] is Map ? asJsonMap(json['data']) : json;
    return ProfileStatsEntity(
      liveStreams: asInt(pick(m, ['liveStreams', 'live_streams'])),
      likes: asInt(pick(m, ['likes', 'likesCount'])),
      followers: asInt(pick(m, ['followers', 'followersCount'])),
      following: asInt(pick(m, ['following', 'followingCount'])),
      giftsReceivedCount: asInt(pick(m, ['giftsReceivedCount'])),
      giftsReceivedCoins: asInt(pick(m, ['giftsReceivedCoins', 'earningsJeton'])),
      earningsJeton: asInt(pick(m, ['earningsJeton', 'giftsReceivedCoins'])),
      approvedTopUpTotal: asInt(pick(m, ['approvedTopUpTotal'])),
      profileViews: asInt(pick(m, ['profileViews', 'profile_views', 'viewCount'])),
    );
  }

  final int liveStreams;
  final int likes;
  final int followers;
  final int following;
  final int giftsReceivedCount;
  final int giftsReceivedCoins;
  final int earningsJeton;
  final int approvedTopUpTotal;
  final int profileViews;
}

class GiftReceivedSummaryEntity {
  const GiftReceivedSummaryEntity({
    required this.name,
    required this.icon,
    required this.count,
    this.coins = 0,
  });

  factory GiftReceivedSummaryEntity.fromJson(Map<String, dynamic> json) {
    return GiftReceivedSummaryEntity(
      name: pick(json, ['name', 'giftName'])?.toString() ?? 'Hediye',
      icon: pick(json, ['icon', 'iconUrl'])?.toString() ?? '🎁',
      count: asInt(pick(json, ['count', 'quantity'])),
      coins: asInt(pick(json, ['coins', 'coinCost'])),
    );
  }

  /// `GET /api/user/received-gifts` gövdesi. Liste yoksa `null` (yedek path dene).
  static List<GiftReceivedSummaryEntity>? tryParseList(dynamic body) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final raw = data['summary'] ?? data['gifts'] ?? data['items'] ?? data;
    if (raw is! List) return null;
    return raw
        .map((e) => GiftReceivedSummaryEntity.fromJson(asJsonMap(e)))
        .toList();
  }

  final String name;
  final String icon;
  final int count;
  final int coins;
}

class BroadcastHistoryItemEntity {
  const BroadcastHistoryItemEntity({
    required this.id,
    required this.title,
    this.startedAt,
    this.giftCount = 0,
    this.coinsEarned = 0,
  });

  factory BroadcastHistoryItemEntity.fromJson(Map<String, dynamic> json) {
    return BroadcastHistoryItemEntity(
      id: pick(json, ['id', 'streamId', 'roomId'])?.toString() ?? '',
      title: pick(json, ['title'])?.toString() ?? 'Canlı yayın',
      startedAt: pick(json, ['startedAt', 'createdAt'])?.toString(),
      giftCount: asInt(pick(json, ['giftCount', 'commentCount'])),
      coinsEarned: asInt(pick(json, ['coinsEarned', 'coins', 'likeCount'])),
    );
  }

  final String id;
  final String title;
  final String? startedAt;
  final int giftCount;
  final int coinsEarned;
}

class ProfileActivityItemEntity {
  const ProfileActivityItemEntity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.status = '',
    this.amount = 0,
    this.createdAt,
    this.targetPath,
    this.targetId,
  });

  factory ProfileActivityItemEntity.fromJson(Map<String, dynamic> json) {
    final read = json['read'] == true || json['isRead'] == true;
    final meta = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null;
    String? pickField(String key) {
      final v = json[key] ?? meta?[key];
      final s = v?.toString().trim();
      return s != null && s.isNotEmpty ? s : null;
    }

    return ProfileActivityItemEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['subject']?.toString() ??
          'Bildirim',
      subtitle: json['subtitle']?.toString() ??
          json['body']?.toString() ??
          json['message']?.toString(),
      status: read
          ? 'read'
          : (json['status']?.toString() ??
              (json['read'] == false ? 'unread' : '')),
      amount: asInt(json['amount']),
      createdAt: json['createdAt']?.toString(),
      targetPath: pickField('targetPath') ??
          pickField('actionUrl') ??
          pickField('link') ??
          pickField('href'),
      targetId: pickField('targetId') ??
          pickField('entityId') ??
          pickField('sessionId') ??
          pickField('session_id') ??
          pickField('roomId') ??
          pickField('room_id'),
    );
  }

  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final String status;
  final int amount;
  final String? createdAt;
  final String? targetPath;
  final String? targetId;
}
