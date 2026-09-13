import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// Abacus `gift-box` + BÖLÜM 22 — yanıtlar şema doğrulanmadı; ham JSON döner.
class GiftBoxRemoteDataSource {
  GiftBoxRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listActive({
    String? roomId,
    String? streamId,
  }) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.giftBox,
      queryParameters: {
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (streamId != null && streamId.isNotEmpty) 'streamId': streamId,
      },
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> getBox(String boxId) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.giftBoxById(boxId),
    );
    return asJsonMap(res.data);
  }

  /// BÖLÜM 22 — `action: create` | `cancel` ve oluşturma alanları.
  Future<Map<String, dynamic>> postAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.giftBox,
      data: body,
      queryParameters: {
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (streamId != null && streamId.isNotEmpty) 'streamId': streamId,
      },
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> joinBox(String boxId) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.giftBoxJoin(boxId),
      data: const <String, dynamic>{},
    );
    return asJsonMap(res.data);
  }

  /// BÖLÜM 22 — `{ scope, targetId, channel }`.
  Future<Map<String, dynamic>> recordShare(Map<String, dynamic> body) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.giftBoxShare,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchRoomSync(String roomId) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.chatRoomSync(roomId),
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchStreamSync(String streamId) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.videoStreamSync(streamId),
    );
    return asJsonMap(res.data);
  }
}
