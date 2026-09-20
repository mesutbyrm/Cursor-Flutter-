import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Admin activity log — who did what and when.
final adminActivityLogProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/activity-log',
      query: {'limit': '100'},
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

/// Activity types.
enum AdminActivityType {
  userWarned,       // User warned
  userBanned,       // User banned
  userUnbanned,     // User unbanned
  reportApproved,   // Report approved
  reportRejected,   // Report rejected
  paymentApproved,  // Payment approved
  paymentRejected,  // Payment rejected
  tokenAdded,       // Token added
  tokenRemoved,     // Token removed
  giftCreated,      // Gift created
  giftEdited,       // Gift edited
  giftDeleted,      // Gift deleted
  other,
}

AdminActivityType parseAdminActivityType(String? type) {
  switch (type?.toLowerCase()) {
    case 'user_warned':
      return AdminActivityType.userWarned;
    case 'user_banned':
      return AdminActivityType.userBanned;
    case 'user_unbanned':
      return AdminActivityType.userUnbanned;
    case 'report_approved':
      return AdminActivityType.reportApproved;
    case 'report_rejected':
      return AdminActivityType.reportRejected;
    case 'payment_approved':
      return AdminActivityType.paymentApproved;
    case 'payment_rejected':
      return AdminActivityType.paymentRejected;
    case 'token_added':
      return AdminActivityType.tokenAdded;
    case 'token_removed':
      return AdminActivityType.tokenRemoved;
    case 'gift_created':
      return AdminActivityType.giftCreated;
    case 'gift_edited':
      return AdminActivityType.giftEdited;
    case 'gift_deleted':
      return AdminActivityType.giftDeleted;
    default:
      return AdminActivityType.other;
  }
}

String adminActivityTypeLabel(AdminActivityType type) {
  switch (type) {
    case AdminActivityType.userWarned:
      return 'Kullanıcı Uyarıldı';
    case AdminActivityType.userBanned:
      return 'Kullanıcı Yasaklandı';
    case AdminActivityType.userUnbanned:
      return 'Kullanıcı Yasak Kaldırıldı';
    case AdminActivityType.reportApproved:
      return 'Rapor Onaylandı';
    case AdminActivityType.reportRejected:
      return 'Rapor Reddedildi';
    case AdminActivityType.paymentApproved:
      return 'Ödeme Onaylandı';
    case AdminActivityType.paymentRejected:
      return 'Ödeme Reddedildi';
    case AdminActivityType.tokenAdded:
      return 'Jeton Eklendi';
    case AdminActivityType.tokenRemoved:
      return 'Jeton Kaldırıldı';
    case AdminActivityType.giftCreated:
      return 'Hediye Oluşturuldu';
    case AdminActivityType.giftEdited:
      return 'Hediye Düzenlendi';
    case AdminActivityType.giftDeleted:
      return 'Hediye Silindi';
    case AdminActivityType.other:
      return 'Diğer';
  }
}
