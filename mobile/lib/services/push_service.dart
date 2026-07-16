import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';

/// Push token API — kılavuz §9.13 (`POST /api/devices/fcm`).
class PushService {
  PushService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `POST /api/devices/fcm`
  Future<void> registerToken({
    required String token,
    required String platform,
    String provider = 'fcm',
  }) async {
    final payload = {
      'token': token,
      'fcmToken': token,
      'deviceToken': token,
      'platform': platform,
      'provider': provider,
    };
    for (final path in [
      ApiEndpoints.registerFcmDevice,
      ApiEndpoints.registerUserDeviceToken,
      ApiEndpoints.authMobileDeviceToken,
    ]) {
      try {
        await _dio.safePost<dynamic>(path, data: payload);
        return;
      } catch (_) {}
    }
  }

  /// `DELETE /api/devices/fcm`
  Future<void> removeToken(String token) async {
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.registerFcmDevice,
      data: {'token': token, 'fcmToken': token},
    );
  }
}
