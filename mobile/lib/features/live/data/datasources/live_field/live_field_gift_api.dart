import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/util/json_util.dart';
import '../../../../gifts/data/gift_idempotency.dart';
import '../../../../gifts/data/lucky_gift_remote_datasource.dart';
import '../../../../gifts/domain/lucky_gift_entities.dart';
import 'live_field_api_util.dart';

/// Saha 5 — Hediye sistemi (`GET gift-types`, `POST gift/send`).
class LiveFieldGiftApi {
  LiveFieldGiftApi(this._dio);

  final Dio _dio;

  Future<List<LiveFieldGiftType>> fetchGiftTypes() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.liveGiftTypes);
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) return const [];
    return LiveFieldApiUtil.listFromData(map, listKey: 'giftTypes')
        .map(LiveFieldGiftType.fromJson)
        .toList(growable: false);
  }

  Future<LiveFieldGiftSendResult> sendGift({
    required String roomId,
    required String roomType,
    required String giftTypeId,
    String? recipientId,
    int quantity = 1,
    bool isLucky = false,
  }) async {
    if (isLucky) {
      final luckyDs = LuckyGiftRemoteDataSource(_dio);
      final lucky = await luckyDs.sendLuckyGift(
        giftTypeId: giftTypeId,
        quantity: quantity,
        context: roomType == 'voice' ? 'voice_room' : 'live_stream',
        contextId: roomId,
      );
      return LiveFieldGiftSendResult(
        senderBalance: lucky.newBalance,
        message: lucky.tierName,
        luckyResult: lucky,
      );
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveGiftSend,
      data: {
        'roomId': roomId,
        'roomType': roomType,
        'giftTypeId': giftTypeId,
        'quantity': quantity,
        'idempotencyKey': newGiftIdempotencyKey(),
        if (recipientId != null && recipientId.isNotEmpty)
          'recipientId': recipientId,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      throw const FormatException('Hediye yanıtı geçersiz');
    }
    return LiveFieldGiftSendResult.fromJson(map);
  }
}

class LiveFieldGiftType {
  const LiveFieldGiftType({
    required this.id,
    required this.name,
    this.nameEn,
    this.icon,
    this.price = 0,
    this.animation,
    this.thumbnailUrl,
    this.assetUrl,
    this.assetType,
    this.sortOrder = 0,
    this.isLucky = false,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String? icon;
  final int price;
  final String? animation;
  final String? thumbnailUrl;
  final String? assetUrl;
  final String? assetType;
  final int sortOrder;
  final bool isLucky;

  factory LiveFieldGiftType.fromJson(Map<String, dynamic> json) {
    return LiveFieldGiftType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      icon: json['icon']?.toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      animation: json['animation']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      assetUrl: json['assetUrl']?.toString(),
      assetType: json['assetType']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isLucky: json['isLucky'] == true,
    );
  }
}

class LiveFieldGiftSendResult {
  const LiveFieldGiftSendResult({
    this.senderBalance,
    this.message,
    this.giftId,
    this.luckyResult,
  });

  final int? senderBalance;
  final String? message;
  final String? giftId;
  final LuckyGiftSpinResult? luckyResult;

  factory LiveFieldGiftSendResult.fromJson(Map<String, dynamic> json) {
    final gift = asJsonMap(json['gift']);
    return LiveFieldGiftSendResult(
      senderBalance: asInt(
        pick(json, ['newBalance', 'senderBalance', 'balance']),
      ),
      message: json['message']?.toString(),
      giftId: gift['id']?.toString(),
    );
  }
}
