import '../../../../core/util/json_util.dart';

class ProfileStatsEntity {
  const ProfileStatsEntity({
    this.liveStreams = 0,
    this.likes = 0,
    this.followers = 0,
    this.following = 0,
    this.giftsReceivedCount = 0,
    this.giftsReceivedCoins = 0,
    this.giftsSentCount = 0,
    this.giftsSentCoins = 0,
    this.earningsJeton = 0,
    this.approvedTopUpTotal = 0,
    this.profileViews = 0,
  });

  factory ProfileStatsEntity.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map ? asJsonMap(json['data']) : json;
    final nested = root['stats'] is Map ? asJsonMap(root['stats']) : root;
    final user = root['user'] is Map ? asJsonMap(root['user']) : const {};
    final m = <String, dynamic>{...root, ...nested, ...user};

    return ProfileStatsEntity(
      liveStreams: asInt(pick(m, [
        'liveStreams',
        'live_streams',
        'broadcastCount',
        'streamsCount',
      ])),
      likes: asInt(pick(m, [
        'likes',
        'likesCount',
        'likeCount',
        'totalLikes',
      ])),
      followers: asInt(pick(m, [
        'followers',
        'followersCount',
        'followerCount',
        'totalFollowers',
      ])),
      following: asInt(pick(m, [
        'following',
        'followingCount',
        'totalFollowing',
      ])),
      giftsReceivedCount: asInt(pick(m, [
        'giftsReceivedCount',
        'receivedGiftsCount',
        'gifts_received_count',
        'receivedGiftCount',
      ])),
      giftsReceivedCoins: asInt(pick(m, [
        'giftsReceivedCoins',
        'receivedGiftsCoins',
        'giftsReceivedJeton',
        'giftEarnings',
        'earningsJeton',
      ])),
      giftsSentCount: asInt(pick(m, [
        'giftsSentCount',
        'sentGiftsCount',
        'gifts_sent_count',
      ])),
      giftsSentCoins: asInt(pick(m, [
        'giftsSentCoins',
        'sentGiftsCoins',
        'giftsSentJeton',
      ])),
      earningsJeton: asInt(pick(m, [
        'earningsJeton',
        'giftsReceivedCoins',
        'netEarnings',
        'totalEarnings',
      ])),
      approvedTopUpTotal: asInt(pick(m, ['approvedTopUpTotal'])),
      profileViews: asInt(pick(m, [
        'profileViews',
        'profile_views',
        'viewCount',
        'visitorCount',
      ])),
    );
  }

  /// Aynı istatistik, yalnız beğeni sayısı değiştirilmiş.
  ProfileStatsEntity withLikes(int value) => ProfileStatsEntity(
        liveStreams: liveStreams,
        likes: value,
        followers: followers,
        following: following,
        giftsReceivedCount: giftsReceivedCount,
        giftsReceivedCoins: giftsReceivedCoins,
        giftsSentCount: giftsSentCount,
        giftsSentCoins: giftsSentCoins,
        earningsJeton: earningsJeton,
        approvedTopUpTotal: approvedTopUpTotal,
        profileViews: profileViews,
      );

  final int liveStreams;
  final int likes;
  final int followers;
  final int following;
  final int giftsReceivedCount;
  final int giftsReceivedCoins;
  final int giftsSentCount;
  final int giftsSentCoins;
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
    final gift = json['gift'] is Map ? asJsonMap(json['gift']) : null;
    return GiftReceivedSummaryEntity(
      name: pick(json, ['name', 'giftName'])?.toString() ??
          pick(gift ?? {}, ['name', 'giftName'])?.toString() ??
          'Hediye',
      icon: pick(json, ['icon', 'iconUrl', 'image', 'giftIcon'])?.toString() ??
          pick(gift ?? {}, ['icon', 'iconUrl', 'image'])?.toString() ??
          '🎁',
      count: asInt(pick(json, ['count', 'quantity', 'total', 'times'])),
      coins: asInt(pick(json, [
        'coins',
        'coinCost',
        'jeton',
        'totalCoins',
        'amount',
      ])),
    );
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
