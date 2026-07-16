import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Hediye API — kılavuz §9.9 `GiftRepository`.
class GiftService {
  GiftService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/gifts/types`
  Future<List<Map<String, dynamic>>> getGiftTypes() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsTypes);
      return ServiceUtils.extractList(
        res.data,
        keys: const ['types', 'gifts', 'items', 'data'],
      );
    } catch (_) {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsCatalog);
      return ServiceUtils.extractList(res.data);
    }
  }

  /// `POST /api/gifts/send`
  Future<Map<String, dynamic>> sendGift({
    required String recipientId,
    required String giftId,
    int quantity = 1,
    String? roomType,
    String? roomId,
    String? context,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.giftsSend,
      data: {
        'giftId': giftId,
        'giftTypeId': giftId,
        'receiverUserId': recipientId,
        'receiverId': recipientId,
        'quantity': quantity,
        'platform': 'mobile',
        if (roomType != null && roomType.isNotEmpty) 'roomType': roomType,
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (context != null && context.isNotEmpty) 'context': context,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/gifts/recent-big`
  Future<List<Map<String, dynamic>>> getRecentBigGifts() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsRecentBig);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['gifts', 'events', 'items', 'data'],
    );
  }
}
