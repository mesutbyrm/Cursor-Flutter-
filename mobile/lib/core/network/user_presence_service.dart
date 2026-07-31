import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';

/// Site geneli çevrimiçi durumu — kılavuz §9.2 `POST /api/presence`.
class UserPresenceService {
  UserPresenceService(this._dio);

  final Dio _dio;

  Future<void> heartbeat({String section = 'app'}) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.userPresence,
        data: {
          'action': 'join',
          'section': section,
          'platform': 'mobile',
        },
      );
    } catch (_) {}
  }

  Future<void> leave() async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.userPresence,
        data: {
          'action': 'leave',
          'platform': 'mobile',
        },
      );
    } catch (_) {}
  }
}
