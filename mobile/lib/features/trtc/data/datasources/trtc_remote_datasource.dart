import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/trtc_credentials.dart';

class TrtcRemoteDataSource {
  TrtcRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TrtcCredentials> fetchToken({
    required String roomId,
    String role = 'audience',
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('trtc.token.request', {'roomId': roomId, 'role': role});
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.trtcToken,
        data: {'roomId': roomId, 'role': role},
      );
      final map = _unwrapTrtcBody(res.data);
      if (map == null) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: 'Geçersiz TRTC token yanıtı',
        );
      }
      final cred = _validate(TrtcCredentials.fromJson(map, requestedRoomId: roomId));
      LiveDebugLog.log('trtc.token.ok', {
        'roomId': cred.roomId,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      });
      return cred;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ApiException('TRTC token uç noktası bulunamadı', statusCode: 404);
      }
      rethrow;
    }
  }

  Future<TrtcCredentials> fetchUserSig({
    required String userId,
    required String roomId,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('usersig.request', {
      'roomId': roomId,
      'userId': userId,
    });
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.trtcUserSig,
        data: {'userId': userId, 'roomId': roomId},
      );
      final body = res.data;
      final map = _unwrapTrtcBody(body);
      if (map == null) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: 'Geçersiz TRTC yanıtı',
        );
      }
      var cred = _validate(TrtcCredentials.fromJson(map, requestedRoomId: roomId));
      if (cred.userId.isEmpty && userId.isNotEmpty) {
        cred = cred.copyWith(userId: userId);
      }
      LiveDebugLog.log('usersig.ok', {
        'roomId': cred.roomId,
        'sdkAppId': cred.sdkAppId,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      });
      return cred;
    } on ApiException catch (e) {
      LiveDebugLog.log('usersig.fail', {
        'roomId': roomId,
        'status': e.statusCode,
        'message': e.message,
      });
      rethrow;
    }
  }

  TrtcCredentials _validate(TrtcCredentials cred) {
    if (!cred.isValid) {
      throw ApiException(
        'TRTC yapılandırması eksik (sdkAppId veya userSig). '
        'Uygulamayı güncelleyin veya destek ile iletişime geçin.',
      );
    }
    return cred;
  }

  static Map<String, dynamic>? _unwrapTrtcBody(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] is Map) {
        return asJsonMap(body['data']);
      }
      return body;
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      if (m['success'] == true && m['data'] is Map) {
        return asJsonMap(m['data']);
      }
      return m;
    }
    return null;
  }
}
