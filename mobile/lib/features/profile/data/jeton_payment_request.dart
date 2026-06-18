import '../domain/entities/jeton_package_entity.dart';

/// canlifal.com `POST /api/payment/requests` — jeton talebi gövdesi.
/// Eski site API'si yalnızca `amount` okuyorsa uyum için `amount` = `coins`.
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
    if (receipt != null && receipt.isNotEmpty) 'receiptReference': receipt,
    'notes': receipt != null && receipt.isNotEmpty
        ? '$baseNotes\nDekont: $receipt'
        : baseNotes,
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': 'mobile_jeton_checkout',
  };
}

/// Gold üyelik — site `POST /api/payment/requests` (admin onayı sonrası üyelik).
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
    if (receipt != null && receipt.isNotEmpty) 'receiptReference': receipt,
    'notes': receipt != null && receipt.isNotEmpty
        ? '$baseNotes\nDekont: $receipt'
        : baseNotes,
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': 'mobile_membership_checkout',
  };
}
