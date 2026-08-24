import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_join_room_result.dart';

class LiveRoomRemoteDataSource {
  LiveRoomRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LiveJoinRoomResult> joinRoom({
    required String roomId,
    required String roomType,
    String? nickname,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('live.join_room.request', {
      'roomId': roomId,
      'roomType': roomType,
    });
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.liveJoinRoom,
        data: {
          'roomId': roomId,
          'roomType': roomType,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        },
      );
      final map = _unwrapData(res.data);
      if (map == null) {
        throw ApiException('Canlı oda yanıtı geçersiz');
      }
      final result = LiveJoinRoomResult.fromJson(map);
      if (!result.trtc.isValid) {
        throw ApiException('TRTC kimlik bilgileri eksik');
      }
      LiveDebugLog.log('live.join_room.ok', {
        'roomId': result.room.id,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      });
      return result;
    } on ApiException catch (e) {
      LiveDebugLog.log('live.join_room.fail', {
        'roomId': roomId,
        'message': e.message,
      });
      rethrow;
    }
  }

  Future<void> leaveRoom({
    required String roomId,
    required String roomType,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.liveLeaveRoom,
        data: {'roomId': roomId, 'roomType': roomType},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<LiveHeartbeatResult> heartbeat({
    required String roomId,
    required String roomType,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveHeartbeat,
      data: {'roomId': roomId, 'roomType': roomType},
    );
    final map = _unwrapData(res.data);
    if (map == null) {
      throw ApiException('Heartbeat yanıtı geçersiz');
    }
    return LiveHeartbeatResult.fromJson(map);
  }

  static Map<String, dynamic>? _unwrapData(dynamic body) {
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
