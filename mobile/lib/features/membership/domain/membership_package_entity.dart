import '../../../core/util/json_util.dart';

class MembershipPackageEntity {
  const MembershipPackageEntity({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.priceJeton,
    required this.bonusJeton,
    required this.falDiscountPercent,
    this.isActive = false,
    this.daysRemaining,
  });

  factory MembershipPackageEntity.fromJson(Map<String, dynamic> json) {
    return MembershipPackageEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      durationDays: asInt(json['durationDays'] ?? json['duration_days'] ?? 30),
      priceJeton: asInt(json['priceJeton'] ?? json['price_jeton'] ?? 0),
      bonusJeton: asInt(json['bonusJeton'] ?? json['bonus_jeton'] ?? 0),
      falDiscountPercent:
          asInt(json['falDiscountPercent'] ?? json['fal_discount_percent']),
      isActive: json['isActive'] == true || json['is_active'] == true,
      daysRemaining: json['daysRemaining'] != null
          ? asInt(json['daysRemaining'])
          : json['days_remaining'] != null
              ? asInt(json['days_remaining'])
              : null,
    );
  }

  final String id;
  final String title;
  final int durationDays;
  final int priceJeton;
  final int bonusJeton;
  final int falDiscountPercent;
  final bool isActive;
  final int? daysRemaining;

  bool get isGold => id == 'gold';
  bool get isDiamond => id == 'diamond';
}

class MembershipCatalogEntity {
  const MembershipCatalogEntity({
    required this.packages,
    required this.currentMembership,
    required this.jetonBalance,
    required this.cfcBalance,
    this.daysRemaining,
  });

  factory MembershipCatalogEntity.fromJson(Map<String, dynamic> json) {
    final list = json['packages'];
    return MembershipCatalogEntity(
      packages: list is List
          ? list
              .map((e) => MembershipPackageEntity.fromJson(asJsonMap(e)))
              .toList()
          : const [],
      currentMembership:
          (json['currentMembership'] ?? json['current_membership'] ?? 'basic')
              .toString(),
      jetonBalance: asInt(json['jetonBalance'] ?? json['jeton_balance']),
      cfcBalance: asInt(json['cfcBalance'] ?? json['cfc_balance']),
      daysRemaining: json['daysRemaining'] != null
          ? asInt(json['daysRemaining'])
          : null,
    );
  }

  final List<MembershipPackageEntity> packages;
  final String currentMembership;
  final int jetonBalance;
  final int cfcBalance;
  final int? daysRemaining;

  MembershipPackageEntity? get activePackage {
    for (final p in packages) {
      if (p.isActive) return p;
    }
    return null;
  }
}
