import '../../../core/util/json_util.dart';

class MembershipPackageEntity {
  const MembershipPackageEntity({
    required this.id,
    required this.planId,
    required this.title,
    required this.durationDays,
    required this.priceJeton,
    required this.bonusJeton,
    required this.falDiscountPercent,
    this.isActive = false,
    this.daysRemaining,
    this.priceTry,
  });

  factory MembershipPackageEntity.fromJson(Map<String, dynamic> json) {
    final tier = json['tier']?.toString().trim();
    // `id` görsel/mantık için tier ("gold" vb.), `planId` ise satın alma için
    // sunucudaki gerçek plan kimliği (cuid). Sunucu id yoksa tier'a düşülür.
    final rawId = json['id']?.toString().trim();
    return MembershipPackageEntity(
      id: (tier != null && tier.isNotEmpty ? tier : rawId) ?? '',
      planId: (rawId != null && rawId.isNotEmpty ? rawId : tier) ?? '',
      title: (json['title'] ?? json['name'] ?? json['nameEn'])?.toString() ??
          '',
      durationDays: asInt(json['durationDays'] ?? json['duration_days'] ?? 30),
      priceJeton: asInt(
        json['priceJeton'] ?? json['price'] ?? json['price_jeton'],
      ),
      bonusJeton: asInt(
        json['bonusJeton'] ?? json['bonusJetons'] ?? json['bonus_jeton'],
      ),
      falDiscountPercent: asInt(
        json['falDiscountPercent'] ??
            json['discountPercent'] ??
            json['fal_discount_percent'],
      ),
      isActive: json['isActive'] == true || json['is_active'] == true,
      daysRemaining: json['daysRemaining'] != null
          ? asInt(json['daysRemaining'])
          : json['days_remaining'] != null
              ? asInt(json['days_remaining'])
              : null,
      priceTry: asInt(
        pick(json, ['priceTry', 'price_try', 'priceTl', 'price_tl', 'price']),
      ),
    );
  }

  final String id;
  final String planId;
  final String title;
  final int durationDays;
  final int priceJeton;
  final int bonusJeton;
  final int falDiscountPercent;
  final bool isActive;
  final int? daysRemaining;
  final int? priceTry;

  /// TL fiyat — API `priceTry` veya jeton × kur.
  int resolvedPriceTry(double jetonTlRate) {
    if (priceTry != null && priceTry! > 0) return priceTry!;
    if (priceJeton > 0 && jetonTlRate > 0) {
      return (priceJeton * jetonTlRate).round();
    }
    return 0;
  }

  /// Satın alma için jeton — API öncelikli.
  int resolvedPriceJeton({required int fallbackFromTry, double jetonTlRate = 0.5}) {
    if (priceJeton > 0) return priceJeton;
    if (fallbackFromTry > 0 && jetonTlRate > 0) {
      return (fallbackFromTry / jetonTlRate).round();
    }
    return 0;
  }

  bool get isGold => id == 'gold';
  bool get isDiamond => id == 'diamond';
  bool get isSvip => id == 'svip' || id == 'super_vip';
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
    final list = json['packages'] ?? json['plans'];
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

  MembershipCatalogEntity copyWith({
    List<MembershipPackageEntity>? packages,
    String? currentMembership,
    int? jetonBalance,
    int? cfcBalance,
    int? daysRemaining,
  }) {
    return MembershipCatalogEntity(
      packages: packages ?? this.packages,
      currentMembership: currentMembership ?? this.currentMembership,
      jetonBalance: jetonBalance ?? this.jetonBalance,
      cfcBalance: cfcBalance ?? this.cfcBalance,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }
}
