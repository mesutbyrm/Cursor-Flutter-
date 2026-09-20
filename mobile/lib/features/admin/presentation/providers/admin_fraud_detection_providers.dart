import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Fraud detection — suspicious patterns & high-risk transactions.
final adminFraudDetectionProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/fraud-alerts',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Fraud alert count — pending review.
final adminFraudAlertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(adminFraudDetectionProvider).valueOrNull ?? [];
  return alerts.where((a) => a['status'] == 'pending').length;
});

/// High-risk transactions.
final adminHighRiskTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/high-risk-transactions',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// High-risk transaction count.
final adminHighRiskTransactionCountProvider = Provider<int>((ref) {
  final transactions = ref.watch(adminHighRiskTransactionsProvider).valueOrNull ?? [];
  return transactions.length;
});

/// Fraud detection types.
enum FraudAlertType {
  rapidWithdrawal,      // Hızlı para çekme
  unusualLocation,      // Anormal konum
  duplicateAccounts,    // Çift hesaplar
  voucherAbuse,         // Kupon suistimali
  velocityCheck,        // Hız kontrolü başarısız
  chargeback,           // Geri ödeme
  suspiciousPatterns,   // Şüpheli desenler
  other,
}

FraudAlertType parseFraudAlertType(String? type) {
  switch (type?.toLowerCase()) {
    case 'rapid_withdrawal':
      return FraudAlertType.rapidWithdrawal;
    case 'unusual_location':
      return FraudAlertType.unusualLocation;
    case 'duplicate_accounts':
      return FraudAlertType.duplicateAccounts;
    case 'voucher_abuse':
      return FraudAlertType.voucherAbuse;
    case 'velocity_check':
      return FraudAlertType.velocityCheck;
    case 'chargeback':
      return FraudAlertType.chargeback;
    case 'suspicious_patterns':
      return FraudAlertType.suspiciousPatterns;
    default:
      return FraudAlertType.other;
  }
}

String fraudAlertTypeLabel(FraudAlertType type) {
  switch (type) {
    case FraudAlertType.rapidWithdrawal:
      return 'Hızlı Para Çekme';
    case FraudAlertType.unusualLocation:
      return 'Anormal Konum';
    case FraudAlertType.duplicateAccounts:
      return 'Çift Hesaplar';
    case FraudAlertType.voucherAbuse:
      return 'Kupon Suistimali';
    case FraudAlertType.velocityCheck:
      return 'Hız Kontrol Başarısızlığı';
    case FraudAlertType.chargeback:
      return 'Geri Ödeme';
    case FraudAlertType.suspiciousPatterns:
      return 'Şüpheli Desenler';
    case FraudAlertType.other:
      return 'Diğer';
  }
}

/// Risk levels.
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

RiskLevel parseRiskLevel(String? level) {
  switch (level?.toLowerCase()) {
    case 'low':
      return RiskLevel.low;
    case 'medium':
      return RiskLevel.medium;
    case 'high':
      return RiskLevel.high;
    case 'critical':
      return RiskLevel.critical;
    default:
      return RiskLevel.medium;
  }
}

String riskLevelLabel(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return 'DÜŞÜK';
    case RiskLevel.medium:
      return 'ORTA';
    case RiskLevel.high:
      return 'YÜKSEK';
    case RiskLevel.critical:
      return 'KRİTİK';
  }
}
