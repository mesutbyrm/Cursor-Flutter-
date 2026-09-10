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

  final source = row['source']?.toString().toLowerCase() ?? '';
  if (source.contains('jeton') || source.contains('membership_checkout')) {
    return 'jeton';
  }
  if (source.contains('cfc')) return 'cfc';

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

  if (row['amount'] != null && !hasCoins) return 'cfc';
  if (row['priceTry'] != null && hasCoins) return 'jeton';

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

  final resolvedType =
      (requestType ?? '').trim().isEmpty ? 'cfc' : requestType!.toLowerCase();
  final isJeton = resolvedType == 'jeton';
  final paths = isJeton
      ? [ApiEndpoints.adminPaymentRequests]
      : [ApiEndpoints.adminCfcPaymentPatch];

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
