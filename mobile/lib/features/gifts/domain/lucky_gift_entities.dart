import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/util/json_util.dart';

/// Şanslı hediye ödül kademesi — `GET /api/gifts/lucky/config`.
class LuckyGiftTier extends Equatable {
  const LuckyGiftTier({
    required this.id,
    required this.name,
    this.nameEn,
    required this.multiplier,
    this.isJackpot = false,
    this.color,
    this.icon,
    this.oddsPercent = 0,
  });

  factory LuckyGiftTier.fromJson(Map<String, dynamic> json) {
    return LuckyGiftTier(
      id: (pick(json, ['id']) ?? '').toString(),
      name: (pick(json, ['name', 'nameTr']) ?? '').toString(),
      nameEn: pick(json, ['nameEn'])?.toString(),
      multiplier: (pick(json, ['multiplier']) as num?)?.toDouble() ?? 0,
      isJackpot: json['isJackpot'] == true,
      color: pick(json, ['color'])?.toString(),
      icon: pick(json, ['icon'])?.toString(),
      oddsPercent: (pick(json, ['oddsPercent']) as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String name;
  final String? nameEn;
  final double multiplier;
  final bool isJackpot;
  final String? color;
  final String? icon;
  final double oddsPercent;

  Color resolveColor({Color fallback = const Color(0xFF22C55E)}) {
    return parseHexColor(color, fallback: fallback);
  }

  @override
  List<Object?> get props =>
      [id, name, nameEn, multiplier, isJackpot, color, icon, oddsPercent];
}

/// Şanslı hediye yapılandırması.
class LuckyGiftConfig extends Equatable {
  const LuckyGiftConfig({
    this.enabled = false,
    this.tiers = const [],
    this.luckyGifts = const [],
    this.rtp,
    this.version = 0,
    this.authed = false,
  });

  factory LuckyGiftConfig.fromJson(Map<String, dynamic> json) {
    final tiersRaw = pick(json, ['tiers']);
    final giftsRaw = pick(json, ['luckyGifts']);
    return LuckyGiftConfig(
      enabled: json['enabled'] == true,
      tiers: tiersRaw is List
          ? tiersRaw
              .whereType<Map>()
              .map((e) => LuckyGiftTier.fromJson(asJsonMap(e)))
              .toList()
          : const [],
      luckyGifts: giftsRaw is List
          ? giftsRaw
              .whereType<Map>()
              .map((e) => LuckyGiftSummary.fromJson(asJsonMap(e)))
              .toList()
          : const [],
      rtp: (pick(json, ['rtp']) as num?)?.toDouble(),
      version: asInt(pick(json, ['version'])),
      authed: json['authed'] == true,
    );
  }

  final bool enabled;
  final List<LuckyGiftTier> tiers;
  final List<LuckyGiftSummary> luckyGifts;
  final double? rtp;
  final int version;
  final bool authed;

  @override
  List<Object?> get props =>
      [enabled, tiers, luckyGifts, rtp, version, authed];
}

class LuckyGiftSummary extends Equatable {
  const LuckyGiftSummary({
    required this.id,
    required this.name,
    this.nameEn,
    this.icon,
    this.price = 0,
  });

  factory LuckyGiftSummary.fromJson(Map<String, dynamic> json) {
    return LuckyGiftSummary(
      id: (pick(json, ['id', 'giftTypeId']) ?? '').toString(),
      name: (pick(json, ['name', 'nameTr']) ?? '').toString(),
      nameEn: pick(json, ['nameEn'])?.toString(),
      icon: pick(json, ['icon'])?.toString(),
      price: asInt(pick(json, ['price'])),
    );
  }

  final String id;
  final String name;
  final String? nameEn;
  final String? icon;
  final int price;

  @override
  List<Object?> get props => [id, name, nameEn, icon, price];
}

/// `POST /api/gifts/lucky/send` sonucu.
class LuckyGiftSpinResult extends Equatable {
  const LuckyGiftSpinResult({
    this.rewardId,
    required this.tierName,
    required this.multiplier,
    required this.betJetons,
    required this.wonJetons,
    required this.netJetons,
    this.isJackpot = false,
    this.color,
    this.icon,
    this.isWin = false,
    this.newBalance,
  });

  factory LuckyGiftSpinResult.fromJson(Map<String, dynamic> json) {
    final result = asJsonMap(json['result'] ?? json);
    return LuckyGiftSpinResult(
      rewardId: pick(json, ['rewardId'])?.toString(),
      tierName: (pick(result, ['tierName', 'name']) ?? '').toString(),
      multiplier: (pick(result, ['multiplier']) as num?)?.toDouble() ?? 0,
      betJetons: asInt(pick(result, ['betJetons'])),
      wonJetons: asInt(pick(result, ['wonJetons'])),
      netJetons: asInt(pick(result, ['netJetons'])),
      isJackpot: result['isJackpot'] == true,
      color: pick(result, ['color'])?.toString(),
      icon: pick(result, ['icon'])?.toString(),
      isWin: result['isWin'] == true,
      newBalance: asInt(pick(json, ['newBalance'])),
    );
  }

  final String? rewardId;
  final String tierName;
  final double multiplier;
  final int betJetons;
  final int wonJetons;
  final int netJetons;
  final bool isJackpot;
  final String? color;
  final String? icon;
  final bool isWin;
  final int? newBalance;

  Color resolveColor() => parseHexColor(color);

  @override
  List<Object?> get props => [
        rewardId,
        tierName,
        multiplier,
        betJetons,
        wonJetons,
        netJetons,
        isJackpot,
        color,
        icon,
        isWin,
        newBalance,
      ];
}

class LuckyGiftHistorySummary extends Equatable {
  const LuckyGiftHistorySummary({
    this.totalPlays = 0,
    this.totalBet = 0,
    this.totalWon = 0,
    this.netJetons = 0,
    this.bestMultiplier = 0,
  });

  factory LuckyGiftHistorySummary.fromJson(Map<String, dynamic> json) {
    return LuckyGiftHistorySummary(
      totalPlays: asInt(pick(json, ['totalPlays'])),
      totalBet: asInt(pick(json, ['totalBet'])),
      totalWon: asInt(pick(json, ['totalWon'])),
      netJetons: asInt(pick(json, ['netJetons'])),
      bestMultiplier: asInt(pick(json, ['bestMultiplier'])),
    );
  }

  final int totalPlays;
  final int totalBet;
  final int totalWon;
  final int netJetons;
  final int bestMultiplier;

  @override
  List<Object?> get props =>
      [totalPlays, totalBet, totalWon, netJetons, bestMultiplier];
}

class LuckyGiftHistoryEntry extends Equatable {
  const LuckyGiftHistoryEntry({
    required this.id,
    this.giftName,
    this.betJetons = 0,
    this.multiplier = 0,
    this.wonJetons = 0,
    this.netJetons = 0,
    this.isJackpot = false,
    this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory LuckyGiftHistoryEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? asJsonMap(user) : <String, dynamic>{};
    return LuckyGiftHistoryEntry(
      id: (pick(json, ['id']) ?? '').toString(),
      giftName: pick(json, ['giftName'])?.toString(),
      betJetons: asInt(pick(json, ['betJetons'])),
      multiplier: asInt(pick(json, ['multiplier'])),
      wonJetons: asInt(pick(json, ['wonJetons'])),
      netJetons: asInt(pick(json, ['netJetons'])),
      isJackpot: json['isJackpot'] == true,
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt'])?.toString() ?? '',
      ),
      userName: pick(userMap, ['name', 'displayName', 'username'])?.toString(),
      userAvatar: pick(userMap, ['avatar', 'avatarUrl', 'image'])?.toString(),
    );
  }

  final String id;
  final String? giftName;
  final int betJetons;
  final int multiplier;
  final int wonJetons;
  final int netJetons;
  final bool isJackpot;
  final DateTime? createdAt;
  final String? userName;
  final String? userAvatar;

  @override
  List<Object?> get props => [
        id,
        giftName,
        betJetons,
        multiplier,
        wonJetons,
        netJetons,
        isJackpot,
        createdAt,
        userName,
        userAvatar,
      ];
}

class GiftCatalogVersionInfo extends Equatable {
  const GiftCatalogVersionInfo({
    this.giftVersion = 0,
    this.themeVersion = 0,
    this.giftCount = 0,
    this.themeCount = 0,
    this.timestamp,
  });

  factory GiftCatalogVersionInfo.fromJson(Map<String, dynamic> json) {
    return GiftCatalogVersionInfo(
      giftVersion: asInt(pick(json, ['giftVersion'])),
      themeVersion: asInt(pick(json, ['themeVersion'])),
      giftCount: asInt(pick(json, ['giftCount'])),
      themeCount: asInt(pick(json, ['themeCount'])),
      timestamp: DateTime.tryParse(
        pick(json, ['timestamp'])?.toString() ?? '',
      ),
    );
  }

  final int giftVersion;
  final int themeVersion;
  final int giftCount;
  final int themeCount;
  final DateTime? timestamp;

  @override
  List<Object?> get props =>
      [giftVersion, themeVersion, giftCount, themeCount, timestamp];
}

class GiftCatalogSyncResult extends Equatable {
  const GiftCatalogSyncResult({
    this.gifts = const [],
    this.currentVersion = 0,
    this.totalGifts = 0,
  });

  final List<Map<String, dynamic>> gifts;
  final int currentVersion;
  final int totalGifts;

  @override
  List<Object?> get props => [gifts, currentVersion, totalGifts];
}

Color parseHexColor(String? raw, {Color fallback = const Color(0xFF22C55E)}) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return fallback;
  var hex = value.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
