import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_type.dart';

/// Sesli oda hediyeleri — katalog canlı yayınla aynı, gönderim oda uç noktasına.
class ChatRoomGiftsRemoteDataSource {
  ChatRoomGiftsRemoteDataSource(this._dio, this._liveGifts);

  final Dio _dio;
  final LiveGiftsRemoteDataSource _liveGifts;

  Future<List<LiveVideoGiftType>> fetchGiftTypes() => _liveGifts.fetchGiftTypes();

  Future<void> sendGift({
    required String roomId,
    required String giftTypeId,
    int quantity = 1,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomGifts(roomId),
      data: jsonEncode({'giftTypeId': giftTypeId, 'quantity': quantity}),
      options: Options(contentType: 'application/json'),
    );
  }
}
