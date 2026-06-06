import '../domain/membership_package_entity.dart';

/// `/api/membership/packages` boş dönerse — mockup paketleri.
List<MembershipPackageEntity> fallbackMembershipPackages({
  String currentMembership = 'basic',
  int? catalogDaysRemaining,
}) {
  final current = currentMembership.toLowerCase();
  final days = catalogDaysRemaining ?? 0;

  MembershipPackageEntity tier({
    required String id,
    required String title,
    required int price,
    bool popular = true,
  }) {
    final active = current == id && days > 0;
    return MembershipPackageEntity(
      id: id,
      title: title,
      durationDays: 30,
      priceJeton: price,
      bonusJeton: price,
      falDiscountPercent: id == 'diamond' ? 25 : id == 'gold' ? 20 : 15,
      isActive: active,
      daysRemaining: active ? days : null,
    );
  }

  return [
    tier(id: 'basic', title: 'Basic', price: 100),
    tier(id: 'premium', title: 'Premium', price: 250),
    tier(id: 'gold', title: 'Gold', price: 500),
    tier(id: 'diamond', title: 'Diamond', price: 1000),
  ];
}
