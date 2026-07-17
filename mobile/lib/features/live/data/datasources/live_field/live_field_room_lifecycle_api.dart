import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../trtc/domain/entities/live_join_room_result.dart';
import 'live_field_api_util.dart';

/// Saha 1 — Oda yaşam döngüsü (`/api/live/create-room`, join, leave, heartbeat).
class LiveFieldRoomLifecycleApi {
  LiveFieldRoomLifecycleApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createRoom({
    String? title,
    String? description,
    String? category,
    String? thumbnailUrl,
    String? coverUrl,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveCreateRoom,
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      throw const ApiException('Yayın oluşturma yanıtı geçersiz');
    }
    return map;
  }

  Future<LiveJoinRoomResult> joinRoom({
    required String roomId,
    required String roomType,
    String? nickname,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveJoinRoom,
      data: {
        'roomId': roomId,
        'roomType': roomType,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      throw const ApiException('Odaya katılım yanıtı geçersiz');
    }
    return LiveJoinRoomResult.fromJson(map);
  }

  Future<void> leaveRoom({
    required String roomId,
    required String roomType,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.liveLeaveRoom,
      data: {'roomId': roomId, 'roomType': roomType},
    );
  }

  Future<LiveHeartbeatResult> heartbeat({
    required String roomId,
    required String roomType,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveHeartbeat,
      data: {'roomId': roomId, 'roomType': roomType},
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      throw const ApiException('Heartbeat yanıtı geçersiz');
    }
    return LiveHeartbeatResult.fromJson(map);
  }
}
