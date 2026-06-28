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

/// Bekleyen jeton/CFC ödeme talepleri — birden fazla admin uç noktası birleştirilir.
final adminPaymentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const [];
  }

  final dio = ref.watch(dioProvider);
  final merged = <String, Map<String, dynamic>>{};
  ApiException? last403;

  Future<void> ingest(String path, Map<String, String> query) async {
    try {
      final res = await dio.safeGet<dynamic>(path, query: query);
      for (final row in _parsePaymentRequests(res.data)) {
        final id = row['id']?.toString().trim();
        if (id == null || id.isEmpty) continue;
        merged[id] = row;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        last403 = e;
        return;
      }
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  await Future.wait([
    ingest(ApiEndpoints.adminCfcPaymentRequests, {
      'status': 'pending',
      'limit': '50',
    }),
    ingest(ApiEndpoints.adminCfcPaymentRequests, {
      'status': 'all',
      'limit': '50',
    }),
    ingest(ApiEndpoints.adminPaymentNotifications, {
      'status': 'pending',
      'limit': '50',
    }),
    ingest(ApiEndpoints.adminPaymentNotifications, {
      'status': 'all',
      'limit': '50',
    }),
    ingest(ApiEndpoints.adminPaymentRequests, {
      'status': 'pending',
      'limit': '50',
    }),
    ingest(ApiEndpoints.adminPaymentRequests, {
      'status': 'all',
      'limit': '50',
    }),
  ]);

  if (merged.isEmpty && last403 != null) {
    throw ApiException(
      'Admin ödeme listesine erişilemedi. Hesabınızın sitede admin/yönetici '
      'rolü olduğundan emin olun.',
      statusCode: 403,
    );
  }

  final pending = merged.values
      .where((r) => _paymentRequestStatus(r) == 'pending')
      .toList()
    ..sort((a, b) {
      final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

  return pending;
});

/// Admin hesabına düşen ödeme bildirimleri (site + ödeme talep kayıtları).
final adminPaymentNotificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const [];
  }

  final dio = ref.watch(dioProvider);
  final merged = <String, Map<String, dynamic>>{};

  void addNotif(Map<String, dynamic> n) {
    final id = (n['id'] ?? n['targetId'] ?? n['paymentRequestId'])?.toString();
    if (id == null || id.isEmpty) return;
    merged[id] = n;
  }

  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminNotifications,
      query: {'payment': '1', 'limit': '100'},
    );
    for (final n in _filterPaymentNotifications(_parseNotificationItems(res.data))) {
      addNotif(n);
    }
  } on ApiException catch (e) {
    if (e.statusCode != 403 && e.statusCode != 404) rethrow;
  }

  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminPaymentNotifications,
      query: {'status': 'all', 'limit': '50'},
    );
    for (final row in _parsePaymentRequests(res.data)) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;
      addNotif({
        'id': id,
        'title': row['requestType'] == 'jeton'
            ? 'Jeton ödeme talebi'
            : 'CFC ödeme talebi',
        'body': paymentRequestSummary(row),
        'type': row['requestType'] == 'jeton'
            ? 'jeton_payment_request'
            : 'cfc_payment_request',
        'targetId': id,
        'targetPath': '/admin',
        'read': row['status'] != 'pending',
        'createdAt': row['createdAt'],
        'data': {'paymentRequestId': id},
      });
    }
  } on ApiException catch (e) {
    if (e.statusCode != 403 && e.statusCode != 404) rethrow;
  }

  final list = merged.values.toList()
    ..sort((a, b) {
      final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

  return list;
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

String _paymentRequestStatus(Map<String, dynamic> r) =>
    (r['status'] ?? 'pending').toString().toLowerCase().trim();

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
  if (data is Map) {
    for (final key in ['items', 'paymentNotifications']) {
      final list = data[key];
      if (list is List) return list.map((e) => asJsonMap(e)).toList();
    }
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
    final price = r['priceTry'];
    final priceStr = price != null ? ' · ₺$price' : '';
    return '$coins jeton$priceStr · ${_methodTr(method)}';
  }
  return '${r['amount']} CFC · ${_methodTr(method)}';
}

String paymentRequestDetailLine(Map<String, dynamic> r) {
  final type = (r['requestType'] ?? 'cfc').toString();
  if (type == 'jeton') {
    final coins = r['coins'] ?? r['amount'] ?? '—';
    final price = r['priceTry'] ?? '—';
    final method = _methodTr((r['method'] ?? '').toString());
    return 'Tutar: ₺$price · Jeton: $coins · $method';
  }
  return paymentRequestSummary(r);
}

String paymentNotificationSummary(Map<String, dynamic> n) {
  final body = n['body']?.toString();
  if (body != null && body.isNotEmpty) return body;
  return n['title']?.toString() ?? 'Ödeme bildirimi';
}

String? paymentReceiptUrl(Map<String, dynamic> r) {
  final direct = r['receiptUrl']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;
  final notes = r['notes']?.toString() ?? '';
  final match = RegExp(r'https?://\S+').firstMatch(notes);
  return match?.group(0);
}

String _methodTr(String m) => switch (m) {
      'whatsapp' => 'WhatsApp',
      'papara' => 'Papara',
      'bank_transfer' => 'Havale/EFT',
      _ => m,
    };
