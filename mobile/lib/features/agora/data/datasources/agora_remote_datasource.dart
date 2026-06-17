import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/agora_credentials.dart';

class AgoraRemoteDataSource {
  AgoraRemoteDataSource(this._dio);

  final Dio _dio;

  /// [role] — `host` (yayıncı) veya `audience` (izleyici).
  Future<AgoraCredentials> fetchToken({
    required String channelName,
    required String role,
    int uid = 0,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('agora.token.request', {
      'channel': channelName,
      'role': role,
      'uid': uid,
    });
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.agoraToken,
        data: {
          'channelName': channelName,
          'role': role,
          'uid': uid,
        },
      );
      final map = _unwrapBody(res.data);
      if (map == null) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: 'Geçersiz Agora token yanıtı',
        );
      }
      final cred = AgoraCredentials.fromJson(
        map,
        requestedChannel: channelName,
      );
      if (cred.token.isEmpty || cred.channelName.isEmpty) {
        throw ApiException('Agora token alınamadı');
      }
      LiveDebugLog.log('agora.token.ok', {
        'channel': cred.channelName,
        'uid': cred.uid,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      });
      return cred;
    } on ApiException catch (e) {
      LiveDebugLog.log('agora.token.fail', {
        'channel': channelName,
        'status': e.statusCode,
        'message': e.message,
      });
      rethrow;
    }
  }

  static Map<String, dynamic>? _unwrapBody(dynamic body) {
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
