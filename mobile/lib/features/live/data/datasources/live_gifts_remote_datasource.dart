import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_gift_type.dart';

class LiveGiftSendResult {
  const LiveGiftSendResult({
    this.newBalance,
    this.streamerBalance,
    this.event,
  });

  final int? newBalance;
  final int? streamerBalance;
  final LiveGiftEvent? event;
}

class LiveGiftsRemoteDataSource {
  LiveGiftsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LiveVideoGiftType>> fetchGiftTypes() async {
    final res =
        await _dio.safeGet<dynamic>(ApiEndpoints.videoStreamGiftsCatalog);
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => LiveVideoGiftType.fromJson(asJsonMap(e)))
        .where((g) => g.id.isNotEmpty)
        .toList();
  }

  /// Yayına düşen hediye kayıtları (izleyiciler için poll).
  Future<List<LiveGiftEvent>> fetchStreamGiftEvents({
    required String streamId,
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGifts(streamId),
    );
    final data = res.data;
    if (data is! List) return const [];
    final events = <LiveGiftEvent>[];
    for (final raw in data) {
      final e = parseGiftEvent(asJsonMap(raw), streamId: streamId);
      if (e == null) continue;
      if (since != null && e.timestamp.isBefore(since)) continue;
      events.add(e);
    }
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  /// Site ile aynı gövde: `{ giftTypeId, quantity: 1 }`.
  Future<LiveGiftSendResult> sendGift({
    required String streamId,
    required String giftTypeId,
    required String senderName,
    required String receiverName,
    required String giftName,
    required int unitPrice,
    int quantity = 1,
    String? senderId,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.videoStreamGifts(streamId),
      data: {'giftTypeId': giftTypeId, 'quantity': quantity},
    );
    final b = res.data ?? {};
    final event = parseGiftEvent(b, streamId: streamId) ??
        LiveGiftEvent(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          senderId: senderId,
          senderName: senderName,
          receiverName: receiverName,
          giftId: giftTypeId,
          giftName: giftName,
          quantity: quantity,
          coinCost: unitPrice * quantity,
          timestamp: DateTime.now(),
          animationKey: giftTypeId,
        );
    return LiveGiftSendResult(
      newBalance: asInt(
        pick(b, ['newBalance', 'balance', 'credits', 'coinBalance']),
      ),
      streamerBalance: asInt(
        pick(b, [
          'streamerBalance',
          'hostBalance',
          'broadcasterBalance',
          'earnings',
        ]),
      ),
      event: event,
    );
  }

  LiveGiftEvent? parseGiftEvent(
    Map<String, dynamic> json, {
    required String streamId,
  }) {
    final id = pick(json, ['id', '_id', 'giftEventId'])?.toString();
    if (id == null || id.isEmpty) return null;

    final giftId = pick(json, [
      'giftTypeId',
      'giftId',
      'giftType',
      'type',
    ])?.toString();
    if (giftId == null || giftId.isEmpty) return null;

    final sender = pick(json, [
          'senderName',
          'userName',
          'username',
          'fromUserName',
          'sender',
        ])?.toString() ??
        'Kullanıcı';
    final receiver = pick(json, [
          'receiverName',
          'streamerName',
          'hostName',
          'toUserName',
        ])?.toString() ??
        'Yayıncı';

    final qtyRaw = asInt(pick(json, ['quantity', 'count', 'amount']));
    final qty = qtyRaw > 0 ? qtyRaw : 1;
    final price = asInt(pick(json, ['price', 'coinCost', 'totalCost']));
    final ts = DateTime.tryParse(
          pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ??
              '',
        ) ??
        DateTime.now();

    final giftName = pick(json, ['giftName', 'name'])?.toString() ??
        LiveGiftCatalog.displayNameOverrides[giftId] ??
        giftId;
    final comboRaw = asInt(pick(json, ['combo', 'comboCount']));

    final icon = pick(json, ['icon', 'iconUrl'])?.toString();
    final iconUrl = icon == null || icon.isEmpty
        ? null
        : icon.startsWith('http')
            ? icon
            : '${Env.siteOrigin}${icon.startsWith('/') ? icon : '/$icon'}';

    return LiveGiftEvent(
      id: id,
      senderId: pick(json, ['senderId', 'userId', 'fromUserId'])?.toString(),
      senderName: sender,
      receiverName: receiver,
      giftId: giftId,
      giftName: giftName,
      quantity: qty,
      coinCost: price,
      combo: comboRaw > 0 ? comboRaw : 1,
      timestamp: ts,
      iconUrl: iconUrl,
      animationKey: pick(json, ['animation', 'animationKey'])?.toString(),
    );
  }
}
