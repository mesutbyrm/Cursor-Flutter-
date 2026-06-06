import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import 'staff_access_provider.dart';

const paymentNotificationTypes = {
  'cfc_payment_request',
  'jeton_payment_request',
  'cfc_payment_approved',
  'cfc_payment_rejected',
  'jeton_payment_approved',
  'jeton_payment_rejected',
};

/// Bekleyen jeton/CFC ödeme talepleri — canlifal.com admin API.
final adminPaymentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const [];
  }

  final dio = ref.watch(dioProvider);

  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminCfcPaymentRequests,
      query: {'status': 'pending', 'limit': 50},
    );
    final parsed = _parsePaymentRequests(res.data);
    if (parsed.isNotEmpty) return parsed;
  } on ApiException catch (e) {
    if (e.statusCode != 403 && e.statusCode != 404) rethrow;
  }

  try {
    final legacy = await dio.safeGet<dynamic>(
      ApiEndpoints.adminPaymentRequests,
      query: {'status': 'pending', 'limit': 50},
    );
    return _parsePaymentRequests(legacy.data);
  } on ApiException catch (e) {
    if (e.statusCode == 403 || e.statusCode == 404) return const [];
    rethrow;
  }
});

/// Admin hesabına düşen ödeme bildirimleri (site).
final adminPaymentNotificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const [];
  }

  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminNotifications,
      query: {'payment': '1'},
    );
    return _filterPaymentNotifications(_parseNotificationItems(res.data));
  } on ApiException catch (e) {
    if (e.statusCode == 403) return const [];
    rethrow;
  }
});

/// Site ödeme ayarları özeti (admin).
final adminSitePaymentSettingsProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const {};
  }

  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminCfcSettings);
    final map = _unwrapMap(res.data);
    return {
      'WhatsApp': _str(map, [
        'cfc_whatsapp_number',
        'cfcWhatsappNumber',
        'whatsappNumber',
      ]),
      'Papara': _str(map, ['cfc_papara_address', 'cfcPaparaAddress', 'paparaAddress']),
      'IBAN': _str(map, ['cfc_bank_iban', 'cfcBankIban', 'bankIban']),
      'Alıcı': _str(map, [
        'cfc_bank_account_holder',
        'cfcBankAccountHolder',
        'bankAccountHolder',
      ]),
    };
  } catch (_) {
    return const {};
  }
});

/// Profil / admin giriş rozeti.
final adminPendingPaymentsCountProvider = Provider<int>((ref) {
  if (!ref.watch(staffAccessProvider).canManagePayments) return 0;
  final requests = ref.watch(adminPaymentRequestsProvider);
  return requests.maybeWhen(data: (rows) => rows.length, orElse: () => 0);
});

/// Geriye dönük alias.
final adminCfcPaymentRequestsProvider = adminPaymentRequestsProvider;

List<Map<String, dynamic>> _parsePaymentRequests(dynamic data) {
  if (data is String &&
      (data.contains('<!DOCTYPE') || data.contains('<html'))) {
    return const [];
  }
  if (data is Map && data['requests'] is List) {
    return (data['requests'] as List).map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data['success'] == true && data['data'] is Map) {
    final inner = data['data'] as Map;
    final list = inner['requests'];
    if (list is List) return list.map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data['data'] is List) {
    return (data['data'] as List).map((e) => asJsonMap(e)).toList();
  }
  if (data is List) {
    return data.map((e) => asJsonMap(e)).toList();
  }
  return const [];
}

List<Map<String, dynamic>> _parseNotificationItems(dynamic data) {
  if (data is String &&
      (data.contains('<!DOCTYPE') || data.contains('<html'))) {
    return const [];
  }
  dynamic list;
  if (data is Map) {
    list = data['items'] ?? data['notifications'] ?? data['data'];
    if (list is Map) {
      list = list['items'] ?? list['notifications'];
    }
  } else if (data is List) {
    list = data;
  }
  if (list is! List) return const [];
  return list.map((e) => asJsonMap(e)).toList();
}

List<Map<String, dynamic>> _filterPaymentNotifications(
  List<Map<String, dynamic>> all,
) {
  return all
      .where((n) => paymentNotificationTypes.contains(
            (n['type'] ?? '').toString().toLowerCase(),
          ))
      .toList();
}

Map<String, dynamic> _unwrapMap(dynamic data) {
  if (data is Map && data['success'] == true && data['data'] is Map) {
    return asJsonMap(data['data']);
  }
  if (data is Map) return asJsonMap(data);
  return {};
}

String _str(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return '—';
}

bool isPaymentNotificationType(String? type) {
  if (type == null) return false;
  return paymentNotificationTypes.contains(type.toLowerCase());
}

String paymentRequestSummary(Map<String, dynamic> r) {
  final type = (r['requestType'] ?? 'cfc').toString();
  final method = (r['method'] ?? '').toString();
  if (type == 'jeton') {
    final coins = r['coins'] ?? r['amount'];
    final title = r['packageTitle']?.toString();
    return '${title ?? '$coins Jeton'} · ${_methodTr(method)}';
  }
  return '${r['amount']} CFC · ${_methodTr(method)}';
}

String paymentNotificationSummary(Map<String, dynamic> n) {
  final body = n['body']?.toString();
  if (body != null && body.isNotEmpty) return body;
  return n['title']?.toString() ?? 'Ödeme bildirimi';
}

String _methodTr(String m) => switch (m) {
      'whatsapp' => 'WhatsApp',
      'papara' => 'Papara',
      'bank_transfer' => 'Havale/EFT',
      _ => m,
    };
