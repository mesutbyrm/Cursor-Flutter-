import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

final adminUserOverviewProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminUserOverview(userId));
    final body = res.data;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['data'] is Map) return asJsonMap(map['data']);
      return map;
    }
  } catch (_) {}
  return null;
});

final adminUserActivityTimelineProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      ApiEndpoints.adminUserActivity(userId),
    );
    final body = asJsonMap(res.data);
    final data = body['data'] is Map ? asJsonMap(body['data']) : body;
    final items = data['recent_activities'] ?? data['items'];
    if (items is List) {
      return items.whereType<Map>().map((e) => asJsonMap(e)).toList();
    }
  } catch (_) {}
  return const [];
});
