import '../domain/entities/jeton_package_entity.dart';

/// canlifal.com `/api/jeton` yanıt vermezse veya boş dönerse — mockup ile uyumlu varsayılan paketler.
const List<JetonPackageEntity> kFallbackJetonPackages = [
  JetonPackageEntity(
    id: 'p100',
    title: '100 Jeton',
    coins: 100,
    priceTry: 29.9,
    badge: 'Popüler',
  ),
  JetonPackageEntity(
    id: 'p500',
    title: '500 Jeton',
    coins: 500,
    priceTry: 129.9,
    badge: 'En iyi değer',
  ),
  JetonPackageEntity(
    id: 'p1000',
    title: '1000 Jeton',
    coins: 1000,
    priceTry: 500,
  ),
  JetonPackageEntity(
    id: 'p5000',
    title: '5000 Jeton',
    coins: 5000,
    priceTry: 999.9,
    badge: 'VIP',
  ),
];
