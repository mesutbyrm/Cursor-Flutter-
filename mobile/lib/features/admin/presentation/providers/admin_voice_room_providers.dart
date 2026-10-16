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
    // Gelir paylaşımını belirleyen `vr_*` ayarları platform ayarlarındadır
    // (`lib/voice-room-revenue.ts`); web panelindeki ayarlarla aynı kaynak.
    final res = await dio
        .safeGet<dynamic>(ApiEndpoints.adminPlatformSettings, forceRefresh: true)
        .timeout(const Duration(seconds: 8), onTimeout: () => throw ApiException('timeout', statusCode: 408));
    return _unwrapMap(res.data);
  } on ApiException catch (e) {
    if (e.statusCode == 403 || e.statusCode == 404 || e.statusCode == 408) return const {};
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

/// Her `vr_*` anahtarı `POST /api/admin/settings {key, value}` ile yazılır.
/// Önceden `/api/admin/voice-room-settings`'e camelCase alanlar gönderiliyor,
/// sunucu hiçbirini okumuyor ama «kaydedildi» görünüyordu.
Future<void> saveAdminVoiceRoomSettings(
  WidgetRef ref,
  Map<String, dynamic> patch,
) async {
  final dio = ref.read(dioProvider);
  for (final e in patch.entries) {
    await dio.safePost<dynamic>(
      ApiEndpoints.adminPlatformSettings,
      data: {'key': e.key, 'value': '${e.value}'},
    );
  }
  ref.invalidate(adminVoiceRoomSettingsProvider);
}
