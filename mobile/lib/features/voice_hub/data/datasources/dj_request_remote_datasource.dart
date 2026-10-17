import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/dj_request.dart';

/// `/api/chat/rooms/{roomId}/dj-request` istemcisi.
class DjRequestRemoteDataSource {
  DjRequestRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DjRequestsSnapshot> fetch(String roomId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRoomDjRequest(roomId),
      forceRefresh: true,
    );
    return DjRequestsSnapshot.fromJson(res.data);
  }

  Future<void> create(
    String roomId,
    String query, {
    String? message,
    String? giftToUserId,
    bool priority = false,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomDjRequest(roomId),
      data: {
        'query': query,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        if (giftToUserId != null && giftToUserId.isNotEmpty)
          'giftToUserId': giftToUserId,
        if (priority) 'priority': true,
      },
    );
  }

  /// [action]: play | reject | cancel | done | clap

  Future<void> act(String roomId, String requestId, String action) async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.chatRoomDjRequest(roomId),
      data: {'requestId': requestId, 'action': action},
    );
  }
}
