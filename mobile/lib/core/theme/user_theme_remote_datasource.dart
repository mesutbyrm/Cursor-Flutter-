import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../util/json_util.dart';

/// `GET/POST /api/user/theme` — web ile tema senkronu.
class UserThemeRemoteDataSource {
  UserThemeRemoteDataSource(this._dio);

  final Dio _dio;

  /// Sunucudan tema anahtarı: `dark`, `amoled`, `light` vb.
  Future<String?> fetchTheme() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userTheme);
      final body = res.data;
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      final theme = pick(map, ['theme', 'mode', 'name'])?.toString().trim();
      if (theme != null && theme.isNotEmpty) return theme.toLowerCase();
      final data = map['data'];
      if (data is Map) {
        return pick(Map<String, dynamic>.from(data), ['theme', 'mode'])
            ?.toString()
            .trim()
            .toLowerCase();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateTheme(String theme) async {
    final value = theme.trim().toLowerCase();
    if (value.isEmpty) return;
    await _dio.safePost<dynamic>(
      ApiEndpoints.userTheme,
      data: {'theme': value},
    );
  }
}
