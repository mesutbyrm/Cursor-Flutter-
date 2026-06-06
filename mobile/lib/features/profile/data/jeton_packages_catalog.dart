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
