import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/me_permissions.dart';
import 'auth_providers.dart';

/// Sunucu yetki listesi — admin menü/buton görünürlüğü (PR #40).
final mePermissionsProvider =
    FutureProvider.autoDispose<MePermissions>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const MePermissions();
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.mePermissions);
    final body = res.data;
    if (body is Map) {
      return MePermissions.fromJson(Map<String, dynamic>.from(body));
    }
  } catch (_) {}
  return const MePermissions();
});

/// Kısa erişim: `ref.watch(mePermissionsProvider).valueOrNull?.can('…')`
extension MePermissionsRef on WidgetRef {
  bool meCan(String permission) {
    final p = read(mePermissionsProvider).valueOrNull;
    if (p == null) return false;
    return p.can(permission);
  }
}
