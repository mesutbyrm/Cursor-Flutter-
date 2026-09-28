import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

final agencyPresenceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.agencyLivePresence);
    final body = res.data;
    if (body is Map) {
      final root = asJsonMap(body);
      final map = root['data'] is Map ? asJsonMap(root['data']) : root;
      final list = map['members'] ?? map['items'];
      if (list is List) {
        return list.whereType<Map>().map((e) => asJsonMap(e)).toList();
      }
    }
  } catch (_) {}
  return const [];
});
