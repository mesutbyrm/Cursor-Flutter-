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

/// Jeton mu CFC mi — `requestType` yoksa alanlardan çıkar.
String resolvePaymentRequestType(Map<String, dynamic> row) {
  final raw = (row['requestType'] ?? row['type'] ?? '').toString().toLowerCase();
  if (raw.contains('jeton')) return 'jeton';
  if (raw.contains('cfc')) return 'cfc';
  if (row['coins'] != null || row['priceTry'] != null || row['jeton'] != null) {
    return 'jeton';
  }
  return 'cfc';
}

/// Admin ödeme onay/red — jeton ve CFC uçlarını sırayla dener.
Future<void> reviewAdminPaymentRequest(
  Dio dio, {
  required String requestId,
  required String action,
  String? requestType,
  String? reviewNote,
}) async {
  final id = requestId.trim();
  if (id.isEmpty) {
    throw const ApiException('Ödeme talebi kimliği bulunamadı.');
  }

  final isJeton = (requestType ?? '').toLowerCase() == 'jeton';
  final paths = isJeton
      ? [ApiEndpoints.adminPaymentRequests, ApiEndpoints.adminCfcPaymentPatch]
      : [ApiEndpoints.adminCfcPaymentPatch, ApiEndpoints.adminPaymentRequests];

  final body = <String, dynamic>{
    'requestId': id,
    'action': action,
    if (action == 'approve') 'reviewNote': reviewNote?.trim().isNotEmpty == true
        ? reviewNote!.trim()
        : 'Onaylandı',
    if (action == 'reject' && (reviewNote?.trim().isNotEmpty ?? false))
      'reviewNote': reviewNote!.trim(),
  };

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
