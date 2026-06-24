import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import 'staff_access_provider.dart';

final adminVoiceRoomSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  if (!ref.watch(staffAccessProvider).canManagePayments) {
    return const {};
  }
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.adminVoiceRoomSettings);
    return _unwrapMap(res.data);
  } on ApiException catch (e) {
    if (e.statusCode == 403 || e.statusCode == 404) return const {};
    rethrow;
  }
});

Map<String, dynamic> _unwrapMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return data;
  }
  return const {};
}

Future<void> saveAdminVoiceRoomSettings(
  WidgetRef ref,
  Map<String, dynamic> patch,
) async {
  final dio = ref.read(dioProvider);
  await dio.safePost<dynamic>(ApiEndpoints.adminVoiceRoomSettings, data: patch);
  ref.invalidate(adminVoiceRoomSettingsProvider);
}
