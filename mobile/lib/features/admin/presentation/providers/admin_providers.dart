import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

const _paymentNotificationTypes = {
  'cfc_payment_request',
  'jeton_payment_request',
  'cfc_payment_approved',
  'cfc_payment_rejected',
  'jeton_payment_approved',
  'jeton_payment_rejected',
};

/// Bekleyen CFC / jeton ödeme talepleri.
final adminCfcPaymentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<dynamic>(
    ApiEndpoints.adminCfcPaymentRequests,
    query: {'status': 'pending', 'limit': 40},
  );
  return _parsePaymentRequests(res.data);
});

/// Staff hesabına düşen ödeme bildirimleri.
final adminPaymentNotificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminNotifications,
      query: {'payment': '1'},
    );
    final all = _parseNotificationItems(res.data);
    return all
        .where((n) =>
            _paymentNotificationTypes.contains(
              (n['type'] ?? '').toString().toLowerCase(),
            ))
        .toList();
  } catch (_) {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminNotifications);
    final all = _parseNotificationItems(res.data);
    return all
        .where((n) =>
            _paymentNotificationTypes.contains(
              (n['type'] ?? '').toString().toLowerCase(),
            ))
        .toList();
  }
});

/// Profil / admin giriş rozeti.
final adminPendingPaymentsCountProvider = Provider<int>((ref) {
  final requests = ref.watch(adminCfcPaymentRequestsProvider);
  return requests.maybeWhen(data: (rows) => rows.length, orElse: () => 0);
});

List<Map<String, dynamic>> _parsePaymentRequests(dynamic data) {
  if (data is Map && data['requests'] is List) {
    return (data['requests'] as List).map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data['success'] == true && data['data'] is Map) {
    final inner = data['data'] as Map;
    final list = inner['requests'];
    if (list is List) return list.map((e) => asJsonMap(e)).toList();
  }
  return const [];
}

List<Map<String, dynamic>> _parseNotificationItems(dynamic data) {
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

bool isPaymentNotificationType(String? type) {
  if (type == null) return false;
  return _paymentNotificationTypes.contains(type.toLowerCase());
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
