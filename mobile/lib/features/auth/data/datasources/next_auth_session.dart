import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// NextAuth oturumundan kullanıcı haritası çözümleme (session → site profili).
class NextAuthSessionResolver {
  NextAuthSessionResolver(this._dio);

  final Dio _dio;

  static Map<String, dynamic>? userFromSession(Map<String, dynamic> session) {
    if (session.isEmpty) return null;
    final u = session['user'];
    if (u is Map<String, dynamic>) return u;
    if (u is Map) return Map<String, dynamic>.from(u);
    return null;
  }

  static bool isValidUserMap(Map<String, dynamic>? u) {
    if (u == null || u.isEmpty) return false;
    final id = pick(u, ['id', 'sub', 'userId', '_id']);
    if (id != null && id.toString().trim().isNotEmpty) return true;
    final email = pick(u, ['email']);
    return email is String && email.contains('@');
  }

  static bool isCredentialsFailure(dynamic data) {
    if (data is! Map) return false;
    final url = data['url']?.toString() ?? '';
    return url.contains('/api/auth/signin') ||
        url.contains('csrf=true') ||
        url.contains('/api/auth/error') ||
        url.contains('error=');
  }

  Future<Map<String, dynamic>> resolveUser() async {
    final sessionRes = await _dio.safeGet<dynamic>(ApiEndpoints.authSession);
    final session = _parseMap(sessionRes.data);
    final fromSession = userFromSession(session);
    if (isValidUserMap(fromSession)) return fromSession!;

    final profileRes = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.userSiteProfile,
    );
    final body = profileRes.data ?? {};
    final err = body['error'] ?? body['message'];
    if (err != null && err.toString().trim().isNotEmpty) {
      throw ApiException(err.toString());
    }
    final nested = pick(body, ['user', 'profile', 'data']);
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    if (isValidUserMap(body)) return body;

    throw const ApiException(
      'Oturum oluşturulamadı. Çerezler kaydedilemedi — tekrar deneyin.',
    );
  }

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
