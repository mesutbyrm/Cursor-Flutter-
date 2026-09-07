import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';
import 'referral_economy_snapshot.dart';

/// `GET /api/agency/invite-earnings` özeti.
class AgencyInviteEarningsSnapshot extends Equatable {
  const AgencyInviteEarningsSnapshot({
    this.agencyId,
    this.agencyName,
    this.totalEarnings = 0,
    this.monthEarnings = 0,
    this.memberCount = 0,
    this.items = const [],
    this.totalItems = 0,
  });

  factory AgencyInviteEarningsSnapshot.fromJson(Map<String, dynamic> json) {
    final agencyRaw = pick(json, ['agency']);
    final agency = agencyRaw is Map ? asJsonMap(agencyRaw) : <String, dynamic>{};
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => ReferralCommissionItem.fromJson(asJsonMap(e)))
            .toList()
        : const <ReferralCommissionItem>[];

    return AgencyInviteEarningsSnapshot(
      agencyId: pick(agency, ['id'])?.toString(),
      agencyName: pick(agency, ['name'])?.toString(),
      totalEarnings: asInt(
        pick(json, ['totalEarnings', 'total']) ??
            pick(agency, ['totalEarnings']),
      ),
      monthEarnings: asInt(pick(json, ['monthEarnings', 'thisMonth'])),
      memberCount: asInt(pick(json, ['memberCount'])),
      items: items,
      totalItems: asInt(pick(json, ['total'])),
    );
  }

  final String? agencyId;
  final String? agencyName;
  final int totalEarnings;
  final int monthEarnings;
  final int memberCount;
  final List<ReferralCommissionItem> items;
  final int totalItems;

  @override
  List<Object?> get props => [
        agencyId,
        agencyName,
        totalEarnings,
        monthEarnings,
        memberCount,
        items,
        totalItems,
      ];
}
