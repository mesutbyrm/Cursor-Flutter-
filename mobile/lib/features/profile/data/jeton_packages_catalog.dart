import '../domain/entities/jeton_package_entity.dart';

/// canlifal.com `/api/jeton` yanıt vermezse — mockup paketleri (1 Jeton = ₺0,50).
const double kDefaultJetonTlRate = 0.5;

const List<JetonPackageEntity> kFallbackJetonPackages = [
  JetonPackageEntity(
    id: 'p50',
    title: '50 Jeton',
    coins: 50,
    priceTry: 25,
  ),
  JetonPackageEntity(
    id: 'p100',
    title: '100 Jeton',
    coins: 100,
    priceTry: 50,
    badge: 'Popüler',
  ),
  JetonPackageEntity(
    id: 'p250',
    title: '250 Jeton',
    coins: 250,
    priceTry: 125,
  ),
  JetonPackageEntity(
    id: 'p500',
    title: '500 Jeton',
    coins: 500,
    priceTry: 250,
    badge: 'Popüler',
  ),
  JetonPackageEntity(
    id: 'p1000',
    title: '1000 Jeton',
    coins: 1000,
    priceTry: 500,
  ),
];

/// API paketleri ile varsayılan 50–1000 jeton seçeneklerini birleştirir.
List<JetonPackageEntity> mergeJetonPackagesWithPresets(
  List<JetonPackageEntity> remote,
) {
  final byCoins = <int, JetonPackageEntity>{
    for (final p in kFallbackJetonPackages) p.coins: p,
  };
  for (final p in remote) {
    if (p.coins > 0) {
      byCoins[p.coins] = p;
    }
  }
  return byCoins.values.toList()..sort((a, b) => a.coins.compareTo(b.coins));
}

/// Özel tutar → site/API ile uyumlu paket kimliği.
JetonPackageEntity resolveJetonPackageForPurchase({
  required int coins,
  required double priceTry,
  List<JetonPackageEntity> remote = const [],
}) {
  final merged = mergeJetonPackagesWithPresets(remote);
  JetonPackageEntity? byCoins;
  JetonPackageEntity? byPrice;
  for (final p in merged) {
    if (p.coins == coins) byCoins = p;
    final pt = p.priceTry;
    if (pt != null && (pt - priceTry).abs() < 0.02) byPrice = p;
  }
  final match = byCoins ?? byPrice;
  if (match != null) {
    return JetonPackageEntity(
      id: match.id,
      title: match.title,
      coins: coins,
      priceTry: priceTry,
      priceLabel: match.priceLabel,
      badge: match.badge,
    );
  }
  return JetonPackageEntity(
    id: 'p$coins',
    title: '$coins Jeton',
    coins: coins,
    priceTry: priceTry,
  );
}
