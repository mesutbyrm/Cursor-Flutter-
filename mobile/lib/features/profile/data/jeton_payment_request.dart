import '../domain/entities/jeton_package_entity.dart';

/// Özel TL/jeton tutarıyla jeton talebi — site `POST /api/payments/requests`.
Map<String, dynamic> buildCustomJetonPaymentRequest({
  required int coins,
  required double priceTry,
  required String method,
  required String userId,
  String? username,
  String? packageId,
  String? receiptReference,
}) {
  final safeCoins = coins > 0 ? coins : 1;
  final pkgId = (packageId ?? 'p$safeCoins').trim();
  final receipt = receiptReference?.trim();
  final sender = username?.trim();
  final priceLabel = priceTry == priceTry.roundToDouble()
      ? priceTry.toInt().toString()
      : priceTry.toStringAsFixed(2);
  final notes = StringBuffer()
    ..writeln('Jeton yükleme · $method')
    ..writeln('$safeCoins jeton · ₺$priceLabel');
  if (sender != null && sender.isNotEmpty) {
    notes.writeln('Gönderen: $sender');
  }
  return {
    'requestType': 'jeton',
    'type': 'jeton',
    'method': method,
    'packageId': pkgId,
    'packageTitle': '$safeCoins Jeton',
    'coins': safeCoins,
    'amount': safeCoins,
    'priceTry': priceTry,
    if (sender != null && sender.isNotEmpty) 'senderInfo': sender,
    if (receipt != null && receipt.isNotEmpty) ...{
      'receiptReference': receipt,
      'receiptUrl': receipt,
    },
    'notes': notes.toString().trim(),
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': 'mobile_jeton_premium',
  };
}

/// canlifal.com `POST /api/payments/requests` — jeton talebi gövdesi.
/// Yalnızca `coins` gönderilir; `amount` üretimde çift krediye yol açabiliyor.
Map<String, dynamic> buildJetonPaymentRequest({
  required JetonPackageEntity package,
  required String method,
  String? notes,
  String? senderLabel,
  String? receiptReference,
}) {
  final coins = package.coins > 0 ? package.coins : 1;
  final receipt = receiptReference?.trim();
  final baseNotes = notes ?? 'Jeton yükleme · $method';
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
    if (receipt != null && receipt.isNotEmpty) ...{
      'receiptReference': receipt,
      'receiptUrl': receipt,
    },
    'notes': receipt != null && receipt.isNotEmpty
        ? '$baseNotes\nDekont: $receipt'
        : baseNotes,
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': 'mobile_jeton_checkout',
  };
}

/// Gold üyelik — site `POST /api/payments/requests` (admin onayı sonrası üyelik).
Map<String, dynamic> buildMembershipPaymentRequest({
  required JetonPackageEntity package,
  required String method,
  String? notes,
  String? senderLabel,
  String? receiptReference,
}) {
  final coins = package.coins > 0 ? package.coins : 1;
  final receipt = receiptReference?.trim();
  final tierId = package.id.startsWith('membership_')
      ? package.id.substring('membership_'.length)
      : package.id;
  final baseNotes = notes ?? 'Gold üyelik · $method';
  return {
    'requestType': 'jeton',
    'type': 'jeton',
    'method': method,
    'packageId': package.id,
    'packageTitle': package.title,
    'tierId': tierId,
    'membershipTier': tierId,
    'coins': coins,
    'amount': coins,
    if (package.priceTry != null) 'priceTry': package.priceTry,
    if (senderLabel != null && senderLabel.trim().isNotEmpty)
      'senderInfo': senderLabel.trim(),
    if (receipt != null && receipt.isNotEmpty) ...{
      'receiptReference': receipt,
      'receiptUrl': receipt,
    },
    'notes': receipt != null && receipt.isNotEmpty
        ? '$baseNotes\nDekont: $receipt'
        : baseNotes,
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': 'mobile_membership_checkout',
  };
}
