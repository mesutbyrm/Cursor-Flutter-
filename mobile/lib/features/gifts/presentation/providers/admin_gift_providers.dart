import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/staff_roles.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/admin_gift_remote_datasource.dart';
import '../../domain/admin_gift_stats.dart';
import '../../domain/admin_gift_type.dart';

final adminGiftRemoteProvider = Provider<AdminGiftRemoteDataSource>((ref) {
  final access = ref.watch(staffAccessProvider);
  final role = _resolveAdminGiftStaffRole(access);
  return AdminGiftRemoteDataSource(
    ref.watch(dioProvider),
    staffRole: role,
  );
});

String? _resolveAdminGiftStaffRole(StaffAccess access) {
  final username = access.username?.toLowerCase().trim() ?? '';
  if (StaffRoles.managerUsernames.contains(username)) return username;
  final siteRole = access.siteRole?.trim();
  if (siteRole != null && siteRole.isNotEmpty) return siteRole;
  if (access.isSiteAdmin) return 'admin';
  return access.username;
}

/// Admin hediye API erişimi — istemci yetkisi + ilk katalog yanıtı.
final adminGiftApiAccessProvider = Provider<bool>((ref) {
  final access = ref.watch(staffAccessProvider);
  if (!access.canManageGifts) return false;
  final list = ref.watch(adminGiftListProvider);
  return list.when(
    data: (_) => true,
    loading: () => true,
    error: (e, _) {
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
        return false;
      }
      return true;
    },
  );
});

/// Admin katalog (pasifler dahil).
final adminGiftListProvider = FutureProvider<List<AdminGiftType>>((ref) {
  return ref.read(adminGiftRemoteProvider).listGifts();
});

/// İstatistikler; anahtar = dönem (all | daily | weekly | monthly | yearly).
final adminGiftStatsProvider =
    FutureProvider.autoDispose.family<AdminGiftStats, String>((ref, period) {
  return ref.read(adminGiftRemoteProvider).statistics(period: period);
});

/// Gelir paylaşım kuralları.
final adminRevenueRulesProvider =
    FutureProvider.autoDispose<List<AdminRevenueRule>>((ref) {
  return ref.read(adminGiftRemoteProvider).revenueRules();
});
