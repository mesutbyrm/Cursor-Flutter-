import 'package:dio/dio.dart';

import '../api_response.dart';
import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import 'models/mobile_config.dart';

/// Mobil uygulama yapılandırması — `GET /api/mobile/config`.
class MobileConfigRemoteDataSource {
  MobileConfigRemoteDataSource({required Dio publicDio}) : _publicDio = publicDio;

  final Dio _publicDio;

  /// `GET /api/mobile/config?platform=ios&version=1.0.0`
  Future<ApiResponse<MobileConfig>> getConfig({
    required String platform,
    required String version,
  }) async {
    final res = await _publicDio.safeGet<dynamic>(
      ApiEndpoints.mobileConfig,
      query: {
        'platform': platform.trim().toLowerCase(),
        'version': version.trim(),
      },
    );
    return parseResponseBody<MobileConfig>(
      res.data,
      fromData: (data) {
        if (data is Map<String, dynamic>) {
          return MobileConfig.fromJson(data);
        }
        if (data is Map) {
          return MobileConfig.fromJson(Map<String, dynamic>.from(data));
        }
        return MobileConfig.parseRoot(res.data);
      },
    );
  }
}
