import '../../profile/data/jeton_packages_catalog.dart';
import 'membership_model.dart';
import 'membership_package_entity.dart';

/// API paket listesinden tier wire id ile eşleşen paketi bulur.
MembershipPackageEntity? findMembershipApiPackage(
  List<MembershipPackageEntity> packages,
  String wireId,
) {
  final key = wireId.toLowerCase();
  for (final p in packages) {
    final pid = p.id.toLowerCase();
    if (pid == key) return p;
    if (key == 'svip' && (pid == 'super_vip' || pid == 'svip')) return p;
  }
  return null;
}

/// Sabit katalog tier'ını API paket fiyat/jeton verisiyle birleştirir.
MembershipTierModel mergeMembershipTier(
  MembershipTierModel base,
  MembershipPackageEntity? api, {
  double jetonTlRate = kDefaultJetonTlRate,
}) {
  if (api == null) return base;
  final priceTry = api.resolvedPriceTry(jetonTlRate);
  final tokens = api.bonusJeton > 0 ? api.bonusJeton : base.monthlyTokens;
  final title = api.title.trim().isNotEmpty ? api.title.trim() : base.title;
  return MembershipTierModel(
    id: base.id,
    title: title,
    subtitle: base.subtitle,
    monthlyTokens: tokens,
    monthlyPriceTry: priceTry > 0 ? priceTry : base.monthlyPriceTry,
    accent: base.accent,
    badgeIcon: base.badgeIcon,
    glow: base.glow,
    popular: api.popular || base.popular,
    isActivePlan: api.isActive,
    durationDays: api.durationDays > 0 ? api.durationDays : base.durationDays,
    falDiscountPercent: api.falDiscountPercent > 0
        ? api.falDiscountPercent
        : base.falDiscountPercent,
    planId: api.planId.isNotEmpty ? api.planId : base.planId,
    featureHighlights:
        api.features.isNotEmpty ? api.features : base.featureHighlights,
  );
}

/// API paket listesinden önerilen tier kimliğini döner.
MembershipTierId? recommendedTierFromPackages(
  List<MembershipPackageEntity> packages,
) {
  for (final p in packages) {
    if (!p.popular) continue;
    final id = p.id.toLowerCase();
    return switch (id) {
      'gold' => MembershipTierId.gold,
      'premium' => MembershipTierId.premium,
      'diamond' => MembershipTierId.diamond,
      'svip' || 'super_vip' => MembershipTierId.svip,
      'basic' || 'free' => MembershipTierId.basic,
      _ => null,
    };
  }
  return null;
}

List<MembershipTokenPackageModel> buildTokenPackagesFromTiers(
  List<MembershipTierModel> tiers,
) {
  return [
    for (final t in tiers)
      MembershipTokenPackageModel(
        tierId: t.id,
        title: t.title,
        tokens: t.monthlyTokens,
        priceTry: t.monthlyPriceTry,
      ),
  ];
}
