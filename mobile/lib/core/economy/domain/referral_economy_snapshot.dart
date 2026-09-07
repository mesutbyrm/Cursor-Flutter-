import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';

/// `GET /api/user/referral-earnings` özeti.
class ReferralEconomySnapshot extends Equatable {
  const ReferralEconomySnapshot({
    this.totalCommission = 0,
    this.monthCommission = 0,
    this.referralCreditsEarned = 0,
    this.referralCode,
    this.cfcBalance = 0,
    this.jetonBalance = 0,
    this.items = const [],
    this.totalItems = 0,
  });

  factory ReferralEconomySnapshot.fromJson(Map<String, dynamic> json) {
    final summaryRaw = pick(json, ['summary']);
    final summary =
        summaryRaw is Map ? asJsonMap(summaryRaw) : <String, dynamic>{};
    final balancesRaw = pick(json, ['balances']);
    final balances =
        balancesRaw is Map ? asJsonMap(balancesRaw) : <String, dynamic>{};
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => ReferralCommissionItem.fromJson(asJsonMap(e)))
            .toList()
        : const <ReferralCommissionItem>[];

    return ReferralEconomySnapshot(
      totalCommission: asInt(
        pick(summary, ['totalCommission', 'total', 'totalEarnings']),
      ),
      monthCommission: asInt(
        pick(summary, ['monthCommission', 'thisMonth', 'monthEarnings']),
      ),
      referralCreditsEarned: asInt(
        pick(balances, ['referralCreditsEarned', 'credits']),
      ),
      referralCode: pick(json, ['referralCode'])?.toString(),
      cfcBalance: asInt(pick(balances, ['cfc', 'credits'])),
      jetonBalance: asInt(pick(balances, ['jeton', 'jetonBalance'])),
      items: items,
      totalItems: asInt(pick(json, ['total'])),
    );
  }

  final int totalCommission;
  final int monthCommission;
  final int referralCreditsEarned;
  final String? referralCode;
  final int cfcBalance;
  final int jetonBalance;
  final List<ReferralCommissionItem> items;
  final int totalItems;

  @override
  List<Object?> get props => [
        totalCommission,
        monthCommission,
        referralCreditsEarned,
        referralCode,
        cfcBalance,
        jetonBalance,
        items,
        totalItems,
      ];
}

class ReferralCommissionItem extends Equatable {
  const ReferralCommissionItem({
    required this.id,
    required this.commissionType,
    required this.amount,
    required this.currency,
    this.topupAmount = 0,
    this.rate = 0,
    this.createdAt,
    this.sourceUserName,
  });

  factory ReferralCommissionItem.fromJson(Map<String, dynamic> json) {
    final sourceUser = pick(json, ['sourceUser']);
    final sourceMap =
        sourceUser is Map ? asJsonMap(sourceUser) : <String, dynamic>{};
    return ReferralCommissionItem(
      id: pick(json, ['id'])?.toString() ?? '',
      commissionType:
          pick(json, ['commissionType', 'type'])?.toString() ?? '',
      amount: asInt(pick(json, ['amount'])),
      currency: pick(json, ['currency'])?.toString() ?? 'cfc',
      topupAmount: asInt(pick(json, ['topupAmount'])),
      rate: (pick(json, ['rate']) as num?)?.toDouble() ?? 0,
      createdAt: pick(json, ['createdAt'])?.toString(),
      sourceUserName: pick(sourceMap, ['name', 'username'])?.toString(),
    );
  }

  final String id;
  final String commissionType;
  final int amount;
  final String currency;
  final int topupAmount;
  final double rate;
  final String? createdAt;
  final String? sourceUserName;

  @override
  List<Object?> get props => [
        id,
        commissionType,
        amount,
        currency,
        topupAmount,
        rate,
        createdAt,
        sourceUserName,
      ];
}
