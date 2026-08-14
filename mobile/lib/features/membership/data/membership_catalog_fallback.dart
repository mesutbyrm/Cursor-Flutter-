import '../domain/membership_package_entity.dart';

/// `/api/memberships/packages` boş dönerse — Basic/Gold/Premium/Diamond (TL fiyatları).
///
/// Aylık: Basic ₺500 / Gold ₺1000 / Premium ₺1500 / Diamond ₺2500
/// Aylık jeton: 250 / 1500 / 3500 / 7500 — jeton alımında indirim yok.
List<MembershipPackageEntity> fallbackMembershipPackages({
  String currentMembership = 'basic',
  int? catalogDaysRemaining,
}) {
  final current = currentMembership.toLowerCase();
  final days = catalogDaysRemaining ?? 0;

  /// `priceJeton`: cüzdan jetonu ile satın alma (₺ / 0.50 varsayılan kur).
  MembershipPackageEntity tier({
    required String id,
    required String title,
    required int priceTry,
    required int monthlyTokens,
  }) {
    final active = current == id && days > 0;
    final priceJeton = priceTry * 2; // 1 jeton = ₺0,50
    return MembershipPackageEntity(
      id: id,
      planId: id,
      title: title,
      durationDays: 30,
      priceJeton: priceJeton,
      bonusJeton: monthlyTokens,
      falDiscountPercent: 0,
      isActive: active,
      daysRemaining: active ? days : null,
    );
  }

  return [
    tier(id: 'basic', title: 'Basic', priceTry: 500, monthlyTokens: 250),
    tier(id: 'gold', title: 'Gold', priceTry: 1000, monthlyTokens: 1500),
    tier(id: 'premium', title: 'Premium', priceTry: 1500, monthlyTokens: 3500),
    tier(id: 'diamond', title: 'Diamond', priceTry: 2500, monthlyTokens: 7500),
    tier(id: 'svip', title: 'SVIP', priceTry: 3500, monthlyTokens: 10000),
  ];
}
