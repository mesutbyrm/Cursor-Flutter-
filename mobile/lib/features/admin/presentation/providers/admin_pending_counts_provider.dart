import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/admin_pending_counts.dart';
import 'staff_access_provider.dart';

final adminPendingCountsProvider =
    FutureProvider.autoDispose<AdminPendingCounts>((ref) async {
  if (!ref.watch(staffAccessProvider).canAccessAdminHome) {
    return const AdminPendingCounts();
  }
  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<dynamic>(
    ApiEndpoints.adminPendingCounts,
    forceRefresh: true,
  );
  final body = res.data;
  if (body is Map) {
    return AdminPendingCounts.fromJson(Map<String, dynamic>.from(body));
  }
  return const AdminPendingCounts();
});
