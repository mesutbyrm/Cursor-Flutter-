import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
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
    String? senderName,
    String? receiverName,
    String? receiverId,
    String platform = 'flutter',
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomGifts(roomId),
      data: jsonEncode({
        'giftTypeId': giftTypeId,
        'quantity': quantity,
        if (senderName != null && senderName.isNotEmpty) 'senderName': senderName,
        if (receiverName != null && receiverName.isNotEmpty)
          'receiverName': receiverName,
        if (receiverId != null && receiverId.isNotEmpty) 'receiverId': receiverId,
        'platform': platform,
      }),
      options: Options(contentType: 'application/json'),
    );
  }

  Future<List<LiveGiftEvent>> fetchRoomGiftEvents({
    required String roomId,
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRoomGifts(roomId),
      query: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    dynamic data = res.data;
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) return const [];
    final out = <LiveGiftEvent>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final e = _liveGifts.parseGiftEvent(
        Map<String, dynamic>.from(raw),
        streamId: roomId,
      );
      if (e != null) out.add(e);
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }
}
