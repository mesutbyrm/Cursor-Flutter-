import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Bulk operation types.
enum BulkOperationType {
  warnUsers,        // Kullanıcıları uyar
  banUsers,         // Kullanıcıları yasakla
  addTokens,        // Jeton ekle
  removeTokens,     // Jeton kaldır
  sendNotification, // Bildirim gönder
  resetAccounts,    // Hesapları sıfırla
}

String bulkOperationTypeLabel(BulkOperationType type) {
  switch (type) {
    case BulkOperationType.warnUsers:
      return 'Kullanıcıları Uyar';
    case BulkOperationType.banUsers:
      return 'Kullanıcıları Yasakla';
    case BulkOperationType.addTokens:
      return 'Jeton Ekle';
    case BulkOperationType.removeTokens:
      return 'Jeton Kaldır';
    case BulkOperationType.sendNotification:
      return 'Bildirim Gönder';
    case BulkOperationType.resetAccounts:
      return 'Hesapları Sıfırla';
  }
}

/// Bulk operation history.
final adminBulkOperationHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/bulk-operations',
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

/// Pending bulk operations count.
final adminPendingBulkOperationsCountProvider = Provider<int>((ref) {
  final operations = ref.watch(adminBulkOperationHistoryProvider).valueOrNull ?? [];
  return operations.where((o) => o['status'] == 'pending').length;
});

/// Bulk operation status.
enum BulkOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
}

BulkOperationStatus parseBulkOperationStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return BulkOperationStatus.pending;
    case 'in_progress':
      return BulkOperationStatus.inProgress;
    case 'completed':
      return BulkOperationStatus.completed;
    case 'failed':
      return BulkOperationStatus.failed;
    default:
      return BulkOperationStatus.pending;
  }
}

String bulkOperationStatusLabel(BulkOperationStatus status) {
  switch (status) {
    case BulkOperationStatus.pending:
      return 'Beklemede';
    case BulkOperationStatus.inProgress:
      return 'İşlemde';
    case BulkOperationStatus.completed:
      return 'Tamamlandı';
    case BulkOperationStatus.failed:
      return 'Başarısız';
  }
}
