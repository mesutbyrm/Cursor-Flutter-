import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/co_broadcast_dto.dart';

abstract class CoBroadcastDataSource {
  Future<CoBroadcastDTO> getCoBroadcast(String broadcastId);
  Future<void> inviteGuest(String broadcastId, String guestId);
  Future<void> acceptInvite(String requestId);
  Future<void> declineInvite(String requestId);
  Future<List<CoBroadcastRequestDTO>> getPendingRequests(String userId);
  Future<void> setAudioMix(String broadcastId, bool enabled);
  Future<void> setGuestPermission(String broadcastId, String permission, bool enabled);
  Future<void> endCoBroadcast(String broadcastId);
}

class CoBroadcastDataSourceImpl implements CoBroadcastDataSource {
  final Dio _dio;
  CoBroadcastDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<CoBroadcastDTO> getCoBroadcast(String broadcastId) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.videoStreams}/$broadcastId');
    return CoBroadcastDTO.fromJson(asJsonMap(res.data));
  }

  @override
  Future<void> inviteGuest(String broadcastId, String guestId) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/$broadcastId/invite', data: {'guestId': guestId});
  }

  @override
  Future<void> acceptInvite(String requestId) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/request/$requestId/accept');
  }

  @override
  Future<void> declineInvite(String requestId) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/request/$requestId/decline');
  }

  @override
  Future<List<CoBroadcastRequestDTO>> getPendingRequests(String userId) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.videoStreams}/requests?userId=$userId');
    final data = asJsonMap(res.data);
    return (data['requests'] as List<dynamic>?)?.map((e) => CoBroadcastRequestDTO.fromJson(e is Map<String,dynamic> ? e : asJsonMap(e))).toList() ?? [];
  }

  @override
  Future<void> setAudioMix(String broadcastId, bool enabled) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/$broadcastId/audio-mix', data: {'enabled': enabled});
  }

  @override
  Future<void> setGuestPermission(String broadcastId, String permission, bool enabled) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/$broadcastId/permission', data: {'permission': permission, 'enabled': enabled});
  }

  @override
  Future<void> endCoBroadcast(String broadcastId) async {
    await _dio.safePost<dynamic>('${ApiEndpoints.videoStreams}/$broadcastId/end');
  }
}
