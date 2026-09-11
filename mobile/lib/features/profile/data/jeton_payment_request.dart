import '../domain/entities/jeton_package_entity.dart';
import '../domain/entities/payment_method_entity.dart';
import '../presentation/premium_2026/profile_membership_helpers.dart';

/// Sunucu `POST /api/payments/requests` — jeton/CFC ayrımı (yerel mirror ile uyumlu).
Map<String, dynamic> normalizePaymentRequestBody(Map<String, dynamic> raw) {
  final reqType =
      (raw['requestType'] ?? raw['type'] ?? '').toString().toLowerCase().trim();
  final explicitCfc = reqType == 'cfc';
  final explicitJeton = reqType == 'jeton' || reqType.contains('jeton');
  final packageIdRaw = raw['packageId']?.toString().trim();
  final hasPackageId = packageIdRaw != null && packageIdRaw.isNotEmpty;
  final coinsParsed = int.tryParse('${raw['coins']}');
  final hasCoins = coinsParsed != null && coinsParsed > 0;

  final isJeton = explicitCfc
      ? false
      : (explicitJeton || (hasPackageId && !explicitCfc) || (hasCoins && !explicitCfc));

  final method = PaymentMethodEntity.normalizeCheckoutMethodId(
    (raw['method'] ?? 'whatsapp').toString(),
  );

  if (isJeton) {
    final coins = hasCoins
        ? coinsParsed!
        : (int.tryParse('${raw['amount']}') ?? 0);
    final safeCoins = coins > 0 ? coins : 1;
    final packageId = (packageIdRaw != null && packageIdRaw.isNotEmpty)
        ? packageIdRaw
        : 'p$safeCoins';
    final title = raw['packageTitle']?.toString().trim();
    final out = <String, dynamic>{
      'requestType': 'jeton',
      'type': 'jeton',
      'method': method,
      'packageId': packageId,
      'packageTitle':
          (title != null && title.isNotEmpty) ? title : '$safeCoins Jeton',
      'coins': safeCoins,
      'amount': safeCoins,
    };
    final priceTry = raw['priceTry'];
    if (priceTry is num && priceTry > 0) out['priceTry'] = priceTry;
    for (final key in const [
      'senderInfo',
      'notes',
      'receiptReference',
      'receiptUrl',
      'notifyAdmins',
      'notifyStaff',
      'source',
      'tierId',
      'membershipTier',
    ]) {
      if (raw.containsKey(key) && raw[key] != null) out[key] = raw[key];
    }
    return out;
  }

  final amount = int.tryParse('${raw['amount']}') ?? 0;
  final safeAmount = amount > 0 ? amount : 1;
  final out = <String, dynamic>{
    'requestType': 'cfc',
    'type': 'cfc',
    'method': method,
    'amount': safeAmount,
  };
  for (final key in const [
    'senderInfo',
    'notes',
    'receiptReference',
    'receiptUrl',
    'notifyAdmins',
    'notifyStaff',
    'source',
    'priceTry',
    'tierId',
    'membershipTier',
    'packageId',
    'packageTitle',
  ]) {
    if (!raw.containsKey(key) || raw[key] == null) continue;
    if (key == 'packageId' || key == 'packageTitle') {
      if (reqType == 'cfc' && raw[key] != null) out[key] = raw[key];
      continue;
    }
    out[key] = raw[key];
  }
  return out;
}

/// CFC yükleme — `coins` gönderilmez (jeton dalına düşmeyi önler).
Map<String, dynamic> buildCfcPaymentRequest({
  required int cfcAmount,
  required String method,
  String? senderInfo,
  String? notes,
  String? receiptReference,
  String source = 'mobile_cfc_checkout',
}) {
  final amount = cfcAmount > 0 ? cfcAmount : 1;
  final methodApi = PaymentMethodEntity.normalizeCheckoutMethodId(method);
  final receipt = receiptReference?.trim();
  return normalizePaymentRequestBody({
    'requestType': 'cfc',
    'type': 'cfc',
    'method': methodApi,
    'amount': amount,
    if (senderInfo != null && senderInfo.trim().isNotEmpty)
      'senderInfo': senderInfo.trim(),
    'notes': notes ?? 'CFC yükleme · $methodApi',
    if (receipt != null && receipt.isNotEmpty) ...{
      'receiptReference': receipt,
      'receiptUrl': receipt,
    },
    'notifyAdmins': true,
    'notifyStaff': true,
    'source': source,
  });
}

/// Özel TL/jeton tutarıyla jeton talebi — site `POST /api/payments/requests`.
Map<String, dynamic> buildCustomJetonPaymentRequest({
  required int coins,
  required double priceTry,
  required String method,
  required String userId,
  String? username,
  String? packageId,
  String? receiptReference,
  String jetonLabel = 'Jeton',
}) {
  final safeCoins = coins > 0 ? coins : 1;
  final pkgId = (packageId ?? 'p$safeCoins').trim();
  final receipt = receiptReference?.trim();
  final sender = username?.trim();
  final priceLabel = priceTry == priceTry.roundToDouble()
      ? priceTry.toInt().toString()
      : priceTry.toStringAsFixed(2);
  final notes = StringBuffer()
    ..writeln('$jetonLabel yükleme · $method')
    ..writeln('$safeCoins $jetonLabel · ₺$priceLabel');
  if (sender != null && sender.isNotEmpty) {
    notes.writeln('Gönderen: $sender');
  }
  return normalizePaymentRequestBody({
    'requestType': 'jeton',
    'type': 'jeton',
    'method': PaymentMethodEntity.normalizeCheckoutMethodId(method),
    'packageId': pkgId,
    'packageTitle': '$safeCoins $jetonLabel',
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
  });
}

/// canlifal.com `POST /api/payments/requests` — jeton talebi gövdesi.
/// `amount` = `coins` (API doğrulama); `requestType: jeton` CFC ile karışmaz.
Map<String, dynamic> buildJetonPaymentRequest({
  required JetonPackageEntity package,
  required String method,
  String? notes,
  String? senderLabel,
  String? receiptReference,
  String jetonLabel = 'Jeton',
}) {
  final coins = package.coins > 0 ? package.coins : 1;
  final receipt = receiptReference?.trim();
  final baseNotes = notes ?? '$jetonLabel yükleme · $method';
  return normalizePaymentRequestBody({
    'requestType': 'jeton',
    'type': 'jeton',
    'method': PaymentMethodEntity.normalizeCheckoutMethodId(method),
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
  });
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
  final baseNotes = notes ??
      buildMembershipPaymentRequestDefaultNotes(
        method: method,
        tierId: tierId,
      );
  return normalizePaymentRequestBody({
    'requestType': 'jeton',
    'type': 'jeton',
    'method': PaymentMethodEntity.normalizeCheckoutMethodId(method),
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
  });
}

/// Üyelik — CFC ödeme talebi (`POST /api/payments/requests`).
Map<String, dynamic> buildMembershipCfcPaymentRequest({
  required String tierId,
  required String tierTitle,
  required int cfcAmount,
  required double priceTry,
  required String method,
  int durationDays = 30,
  String? notes,
  String? senderLabel,
  String? receiptReference,
}) {
  final receipt = receiptReference?.trim();
  final durationLabel = durationDays > 0 ? '$durationDays gün' : '30 gün';
  final baseNotes = notes ??
      buildMembershipCfcPaymentRequestDefaultNotes(
        tierTitle: tierTitle,
        method: method,
      );
  return normalizePaymentRequestBody({
    'requestType': 'cfc',
    'type': 'cfc',
    'method': PaymentMethodEntity.normalizeCheckoutMethodId(method),
    'packageId': 'membership_$tierId',
    'packageTitle': '$tierTitle Üyelik · $durationLabel',
    'tierId': tierId,
    'membershipTier': tierId,
    'amount': cfcAmount,
    'priceTry': priceTry,
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
    'source': 'mobile_membership_cfc_checkout',
  });
}
