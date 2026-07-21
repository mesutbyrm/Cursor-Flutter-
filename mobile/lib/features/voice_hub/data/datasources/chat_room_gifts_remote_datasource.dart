import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/gift_reciprocal_guard.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../domain/entities/voice_gift_revenue.dart';

/// Sesli oda hediyeleri — katalog canlı yayınla aynı, gönderim oda uç noktasına.
class ChatRoomGiftsRemoteDataSource {
  ChatRoomGiftsRemoteDataSource(this._dio, this._liveGifts);

  final Dio _dio;
  final LiveGiftsRemoteDataSource _liveGifts;

  Future<List<LiveVideoGiftType>> fetchGiftTypes() async {
    try {
      final liveTypes =
          await LiveFieldApiRemoteDataSource(_dio).gifts.fetchGiftTypes();
      if (liveTypes.isNotEmpty) {
        return liveTypes
            .map(
              (g) => LiveVideoGiftType(
                id: g.id,
                name: g.name,
                price: g.price,
                iconPath: g.thumbnailUrl ?? g.assetUrl,
                animationRef: g.assetUrl,
              ),
            )
            .toList();
      }
    } catch (_) {}
    try {
      return await _liveGifts.fetchGiftTypes();
    } catch (_) {
      return _liveGifts.fetchGiftTypesFromGiftsApi();
    }
  }

  Future<VoiceGiftSendResult> sendGift({
    required String roomId,
    required String giftTypeId,
    int quantity = 1,
    String? senderName,
    String? receiverName,
    String? receiverId,
    String platform = 'mobile',
    String? battleId,
  }) async {
    if (receiverId != null && receiverId.isNotEmpty) {
      await assertReciprocalGiftAllowed(_dio, receiverId);
    }
    try {
      await LiveFieldApiRemoteDataSource(_dio).gifts.sendGift(
        roomId: roomId,
        roomType: 'voice',
        giftTypeId: giftTypeId,
        recipientId: receiverId,
        quantity: quantity,
      );
      return const VoiceGiftSendResult();
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomGifts(roomId),
      data: {
        'giftTypeId': giftTypeId,
        'giftId': giftTypeId,
        'quantity': quantity,
        if (senderName != null && senderName.isNotEmpty) 'senderName': senderName,
        if (receiverName != null && receiverName.isNotEmpty)
          'receiverName': receiverName,
        if (receiverId != null && receiverId.isNotEmpty) ...{
          'receiverId': receiverId,
          'receiverUserId': receiverId,
        },
        if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
        'platform': platform,
      },
    );
    final body = res.data;
    Map<String, dynamic>? revenueMap;
    if (body is Map) {
      final rev = body['revenue'];
      if (rev is Map) revenueMap = Map<String, dynamic>.from(rev);
    }
    return VoiceGiftSendResult(
      revenue: VoiceGiftRevenueBreakdown.fromJson(revenueMap),
    );
  }

  /// Oda hediye lider tablosu — `GET /api/chat/rooms/{roomId}/gifts`.
  Future<List<GiftLeaderboardEntry>> fetchRoomGiftLeaderboard({
    required String roomId,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomGifts(roomId));
      return _parseLeaderboard(res.data);
    } catch (_) {
      return const [];
    }
  }

  List<GiftLeaderboardEntry> _parseLeaderboard(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      list = pick(data, [
        'leaderboard',
        'leaders',
        'topGifters',
        'topSpenders',
        'rankings',
        'items',
        'entries',
      ]);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => GiftLeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.displayName.isNotEmpty && e.displayName != '—')
        .toList();
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
