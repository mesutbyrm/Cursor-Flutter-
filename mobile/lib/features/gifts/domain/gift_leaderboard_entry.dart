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
  });

  factory GiftLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GiftLeaderboardEntry(
      rank: asInt(pick(json, ['rank'])),
      userId: pick(json, ['userId', 'id'])?.toString(),
      displayName:
          (pick(json, ['displayName', 'senderName', 'username']) ?? '—')
              .toString(),
      totalCoins: asInt(pick(json, ['totalCoins', 'coins', 'coinCost'])),
      giftCount: asInt(pick(json, ['giftCount', 'quantity'])),
      avatarUrl: pick(json, ['avatarUrl'])?.toString(),
    );
  }

  final int rank;
  final String? userId;
  final String displayName;
  final int totalCoins;
  final int giftCount;
  final String? avatarUrl;

  @override
  List<Object?> get props =>
      [rank, userId, displayName, totalCoins, giftCount, avatarUrl];
}
