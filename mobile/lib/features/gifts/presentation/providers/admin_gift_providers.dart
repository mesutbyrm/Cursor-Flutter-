import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/admin_gift_remote_datasource.dart';
import '../../domain/admin_gift_stats.dart';
import '../../domain/admin_gift_type.dart';

final adminGiftRemoteProvider = Provider<AdminGiftRemoteDataSource>((ref) {
  return AdminGiftRemoteDataSource(ref.watch(dioProvider));
});

/// Site admin hediye API erişimi — sunucudan doğrulanır.
final adminGiftApiAccessProvider = FutureProvider<bool>((ref) async {
  final access = ref.watch(staffAccessProvider);
  if (!access.isSiteAdmin) return false;
  try {
    await ref.read(adminGiftRemoteProvider).listGifts();
    return true;
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) return false;
    rethrow;
  }
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
