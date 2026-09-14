import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

/// Ödeme talebi kimliği — API alan adları farklı olabilir.
String resolvePaymentRequestId(Map<String, dynamic> row) {
  for (final key in ['id', 'requestId', '_id', 'paymentRequestId', 'targetId']) {
    final v = row[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  final nested = row['data'];
  if (nested is Map) {
    return resolvePaymentRequestId(Map<String, dynamic>.from(nested));
  }
  return '';
}

bool _isJetonPackageId(String packageId) {
  final id = packageId.trim().toLowerCase();
  if (id.isEmpty) return false;
  return RegExp(r'^p\d+$').hasMatch(id);
}

/// İki admin listesi yanıtını birleştir — eksik `requestType` / `coins` kaybolmasın.
Map<String, dynamic> mergeAdminPaymentRequestRow(
  Map<String, dynamic>? existing,
  Map<String, dynamic> incoming,
) {
  if (existing == null || existing.isEmpty) {
    return Map<String, dynamic>.from(incoming);
  }
  final out = Map<String, dynamic>.from(existing);
  for (final entry in incoming.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value == null) continue;
    final prev = out[key];
    if (prev == null || (prev is String && prev.trim().isEmpty)) {
      out[key] = value;
    }
  }
  final existingRt = out['requestType']?.toString().toLowerCase().trim();
  final incomingRt = incoming['requestType']?.toString().toLowerCase().trim();
  if (existingRt != 'jeton' &&
      existingRt != 'cfc' &&
      (incomingRt == 'jeton' || incomingRt == 'cfc')) {
    out['requestType'] = incoming['requestType'];
  }
  if (out['coins'] == null && incoming['coins'] != null) {
    out['coins'] = incoming['coins'];
  }
  if ((out['packageId']?.toString().trim().isEmpty ?? true) &&
      incoming['packageId'] != null) {
    out['packageId'] = incoming['packageId'];
  }
  if ((out['source']?.toString().trim().isEmpty ?? true) &&
      incoming['source'] != null) {
    out['source'] = incoming['source'];
  }
  return out;
}

/// Jeton mu CFC mi — `requestType` yoksa alanlardan çıkar.
String resolvePaymentRequestType(Map<String, dynamic> row) {
  final reqType = row['requestType']?.toString().toLowerCase().trim();
  if (reqType == 'jeton') return 'jeton';
  if (reqType == 'cfc') return 'cfc';

  final notifType = row['type']?.toString().toLowerCase().trim();
  if (notifType == 'jeton_payment_request') return 'jeton';
  if (notifType == 'cfc_payment_request') return 'cfc';

  final raw = row['type']?.toString().toLowerCase() ?? '';
  if (raw == 'jeton' || raw.contains('jeton')) return 'jeton';
  if (raw == 'cfc' || raw.contains('cfc')) return 'cfc';

  final source = row['source']?.toString().toLowerCase() ?? '';
  if (source.contains('mobile_jeton') || source.contains('jeton_checkout')) {
    return 'jeton';
  }
  if (source.contains('mobile_cfc') || source.contains('cfc_checkout')) {
    return 'cfc';
  }
  if (source.contains('membership_cfc')) return 'cfc';
  if (source.contains('membership_checkout') && !source.contains('cfc')) {
    return 'jeton';
  }

  final packageId = row['packageId']?.toString().trim().toLowerCase() ?? '';
  if (_isJetonPackageId(packageId)) return 'jeton';
  if (packageId.startsWith('membership_') && source.contains('cfc')) {
    return 'cfc';
  }

  final title = (row['packageTitle'] ?? row['title'] ?? '').toString().toLowerCase();
  if (title.contains('jeton')) return 'jeton';
  if (title.contains('cfc')) return 'cfc';

  final notes = row['notes']?.toString().toLowerCase() ?? '';
  if (notes.contains('jeton') && !notes.contains('cfc')) return 'jeton';
  if (notes.contains('cfc') && !notes.contains('jeton')) return 'cfc';

  final hasCoins = row['coins'] != null &&
      int.tryParse(row['coins'].toString()) != null &&
      int.parse(row['coins'].toString()) > 0;
  if (hasCoins || row['jeton'] != null) return 'jeton';

  final amount = int.tryParse('${row['amount']}');
  final priceTry = num.tryParse('${row['priceTry']}');
  final hasPriceTry = priceTry != null && priceTry > 0;
  if (hasPriceTry && amount != null && amount > 0) {
    if (!notes.contains('cfc') &&
        !source.contains('cfc') &&
        !title.contains('cfc')) {
      return 'jeton';
    }
  }

  if (amount != null && amount > 0 && !hasCoins && _isJetonPackageId(packageId)) {
    return 'jeton';
  }

  if (amount != null && amount > 0 && !hasCoins) return 'cfc';

  return 'cfc';
}

/// Onay/red için tür — sunucu kaydı öncelikli.
String resolvePaymentRequestTypeForReview({
  String? uiRequestType,
  Map<String, dynamic>? requestRow,
}) {
  if (requestRow != null) {
    final rowType = requestRow['requestType']?.toString().toLowerCase().trim();
    if (rowType == 'jeton') return 'jeton';
    if (rowType == 'cfc') return 'cfc';
  }
  final ui = uiRequestType?.trim().toLowerCase();
  if (ui == 'jeton') return 'jeton';
  if (ui == 'cfc') return 'cfc';
  if (requestRow != null) return resolvePaymentRequestType(requestRow);
  return '';
}

/// Admin ödeme onay/red — jeton ve CFC uçlarını sırayla dener.
Future<void> reviewAdminPaymentRequest(
  Dio dio, {
  required String requestId,
  required String action,
  String? requestType,
  String? reviewNote,
  Map<String, dynamic>? requestRow,
}) async {
  final id = requestId.trim();
  if (id.isEmpty) {
    throw const ApiException('Ödeme talebi kimliği bulunamadı.');
  }

  final resolvedType = resolvePaymentRequestTypeForReview(
    uiRequestType: requestType,
    requestRow: requestRow,
  );
  if (resolvedType.isEmpty) {
    throw const ApiException(
      'Ödeme türü belirlenemedi. Listeyi yenileyip tekrar deneyin.',
    );
  }
  final isJeton = resolvedType == 'jeton';
  // Üretim PATCH yalnızca `/api/admin/cfc-payment-requests` (jeton + CFC).
  final paths = <String>[
    ApiEndpoints.adminCfcPaymentPatch,
    ApiEndpoints.adminPaymentRequests,
  ];

  final body = <String, dynamic>{
    'requestId': id,
    'action': action,
    'requestType': isJeton ? 'jeton' : 'cfc',
    'type': isJeton ? 'jeton' : 'cfc',
    'creditType': isJeton ? 'jeton' : 'cfc',
    if (action == 'approve') 'reviewNote': reviewNote?.trim().isNotEmpty == true
        ? reviewNote!.trim()
        : 'Onaylandı',
    if (action == 'reject' && (reviewNote?.trim().isNotEmpty ?? false))
      'reviewNote': reviewNote!.trim(),
  };
  if (isJeton && requestRow != null) {
    final coins = requestRow['coins'] ?? requestRow['amount'];
    if (coins != null) body['coins'] = coins;
    final packageId = requestRow['packageId']?.toString().trim();
    if (packageId != null && packageId.isNotEmpty) {
      body['packageId'] = packageId;
    }
  }

  ApiException? last;
  for (final path in paths) {
    try {
      await dio.safePatch<dynamic>(path, data: body);
      return;
    } on ApiException catch (e) {
      last = e;
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 400) {
        continue;
      }
      rethrow;
    }
  }
  throw last ?? const ApiException('Ödeme talebi işlenemedi.');
}
