import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/admin_gift_remote_datasource.dart';
import '../../domain/admin_gift_stats.dart';
import '../../domain/admin_gift_type.dart';

final adminGiftRemoteProvider = Provider<AdminGiftRemoteDataSource>((ref) {
  return AdminGiftRemoteDataSource(ref.watch(dioProvider));
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
