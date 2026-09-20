import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Admin moderation — user reports (spam, abuse, harassment, vb.).
final adminUserReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.reports,
      query: {'type': 'user', 'status': 'pending', 'limit': '50'},
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

/// Bekleyen user report sayısı.
final adminPendingReportsCountProvider = Provider<int>((ref) {
  final reports = ref.watch(adminUserReportsProvider).valueOrNull ?? [];
  return reports.where((r) => r['status'] == 'pending').length;
});

/// Content reports (post, comment, vb.).
final adminContentReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.reports,
      query: {'type': 'content', 'status': 'pending', 'limit': '50'},
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

/// Bekleyen content report sayısı.
final adminPendingContentReportsCountProvider = Provider<int>((ref) {
  final reports = ref.watch(adminContentReportsProvider).valueOrNull ?? [];
  return reports.where((r) => r['status'] == 'pending').length;
});

/// Toplam moderation işleri (reports + activity).
final adminModerationQueueCountProvider = Provider<int>((ref) {
  final userReports = ref.watch(adminPendingReportsCountProvider);
  final contentReports = ref.watch(adminPendingContentReportsCountProvider);
  return userReports + contentReports;
});
