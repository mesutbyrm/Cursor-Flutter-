import '../domain/entities/jeton_package_entity.dart';

/// canlifal.com `POST /api/payment/requests` — jeton talebi gövdesi.
/// Eski site API'si yalnızca `amount` okuyorsa uyum için `amount` = `coins`.
Map<String, dynamic> buildJetonPaymentRequest({
  required JetonPackageEntity package,
  required String method,
  String? notes,
  String? senderLabel,
}) {
  final coins = package.coins > 0 ? package.coins : 1;
  return {
    'requestType': 'jeton',
    'type': 'jeton',
    'method': method,
    'packageId': package.id,
    'packageTitle': package.title,
    'coins': coins,
    'amount': coins,
    if (package.priceTry != null) 'priceTry': package.priceTry,
    if (senderLabel != null && senderLabel.trim().isNotEmpty)
      'senderInfo': senderLabel.trim(),
    'notes': notes ?? 'Jeton yükleme · $method',
  };
}

/// Gold üyelik uzatma — site `POST /api/payment/requests` (jeton talebi).
Map<String, dynamic> buildMembershipPaymentRequest({
  required JetonPackageEntity package,
  required String method,
  String? notes,
}) {
  final coins = package.coins > 0 ? package.coins : 1;
  return {
    'requestType': 'jeton',
    'type': 'jeton',
    'method': method,
    'packageId': package.id,
    'packageTitle': package.title,
    'coins': coins,
    'amount': coins,
    if (package.priceTry != null) 'priceTry': package.priceTry,
    'notes': notes ?? 'Gold üyelik uzatma · $method',
  };
}
