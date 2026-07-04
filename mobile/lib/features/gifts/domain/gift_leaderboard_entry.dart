import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';

class GiftLeaderboardEntry extends Equatable {
  const GiftLeaderboardEntry({
    required this.rank,
    required this.displayName,
    this.userId,
    this.totalCoins = 0,
    this.giftCount = 0,
    this.avatarUrl,
    this.city,
    this.country,
    this.level,
    this.badge,
  });

  factory GiftLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GiftLeaderboardEntry(
      rank: asInt(pick(json, ['rank'])),
      userId: pick(json, ['userId', 'id'])?.toString(),
      displayName:
          (pick(json, ['displayName', 'senderName', 'username', 'name']) ?? '—')
              .toString(),
      totalCoins: asInt(pick(json, ['totalCoins', 'coins', 'coinCost'])),
      giftCount: asInt(pick(json, ['giftCount', 'quantity', 'count'])),
      avatarUrl: pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      city: pick(json, ['city'])?.toString(),
      country: pick(json, ['country'])?.toString(),
      level: () {
        final v = pick(json, ['level']);
        return v == null ? null : asInt(v);
      }(),
      badge: pick(json, ['badge', 'supporterBadge', 'tier'])?.toString(),
    );
  }

  final int rank;
  final String? userId;
  final String displayName;
  final int totalCoins;
  final int giftCount;
  final String? avatarUrl;
  final String? city;
  final String? country;
  final int? level;
  final String? badge;

  @override
  List<Object?> get props => [
        rank,
        userId,
        displayName,
        totalCoins,
        giftCount,
        avatarUrl,
        city,
        country,
        level,
        badge,
      ];
}
