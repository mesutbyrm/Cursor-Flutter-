import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/domain/gift_animation_kind.dart';
import '../../../gifts/domain/gift_entity.dart';
import '../../../gifts/domain/gift_platform.dart';
import '../../../gifts/domain/gift_rarity.dart';
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

  Future<List<LiveVideoGiftType>> fetchGiftTypes({
    GiftPlatform platform = GiftPlatform.mobile,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGiftsCatalog,
      query: {'platform': platform.queryValue},
    );
    final data = _unwrap(res.data);
    if (data is! List) return const [];
    return data
        .map((e) => LiveVideoGiftType.fromGift(GiftEntity.fromJson(
              asJsonMap(e),
              siteOrigin: Env.siteOrigin,
            )))
        .where((g) => g.id.isNotEmpty)
        .toList();
  }

  Future<List<LiveGiftEvent>> fetchStreamGiftEvents({
    required String streamId,
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGifts(streamId),
    );
    final data = _unwrap(res.data);
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
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamGifts(streamId),
      data: {
        'giftTypeId': giftTypeId,
        'quantity': quantity,
        'platform': GiftPlatform.mobile.queryValue,
      },
    );
    final raw = _unwrap(res.data);
    final b = raw is Map ? asJsonMap(raw) : <String, dynamic>{};
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
    final giftId = _resolveGiftId(json);
    if (giftId == null || giftId.isEmpty) return null;

    final ts = DateTime.tryParse(
          pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ??
              '',
        ) ??
        DateTime.now();

    var id = pick(json, ['id', '_id', 'giftEventId'])?.toString();
    if (id == null || id.isEmpty) {
      id = '$streamId-${ts.millisecondsSinceEpoch}-$giftId';
    }

    final sender = _resolvePersonName(
      json,
      flatKeys: const [
        'senderName',
        'userName',
        'username',
        'fromUserName',
      ],
      objectKeys: const ['sender', 'user', 'fromUser', 'from'],
    );

    final receiver = _resolvePersonName(
      json,
      flatKeys: const [
        'receiverName',
        'streamerName',
        'hostName',
        'toUserName',
      ],
      objectKeys: const ['receiver', 'streamer', 'host', 'toUser', 'to'],
      fallback: 'Yayıncı',
    );

    final giftName = _resolveGiftName(json, giftId);
    if (!_isValidLabel(giftName)) return null;

    final qtyRaw = asInt(pick(json, ['quantity', 'count', 'amount']));
    final qty = qtyRaw > 0 ? qtyRaw : 1;
    final price = asInt(pick(json, ['price', 'coinCost', 'totalCost']));
    final comboRaw = asInt(pick(json, ['combo', 'comboCount']));

    final icon = pick(json, ['icon', 'iconUrl'])?.toString();
    final iconUrl = icon == null || icon.isEmpty
        ? null
        : icon.startsWith('http')
            ? icon
            : '${Env.siteOrigin}${icon.startsWith('/') ? icon : '/$icon'}';

    final animKey = pick(json, ['animation', 'animationKey'])?.toString();
    final animType = GiftAnimationKind.parse(
      pick(json, ['animationType', 'animationKind'])?.toString(),
    );

    return LiveGiftEvent(
      id: id,
      senderId: _resolvePersonId(json),
      senderName: sender,
      receiverName: receiver,
      giftId: giftId,
      giftName: giftName,
      quantity: qty,
      coinCost: price,
      combo: comboRaw > 0 ? comboRaw : 1,
      timestamp: ts,
      iconUrl: iconUrl,
      animationKey: animKey,
      rarity: GiftRarity.parse(pick(json, ['rarity'])?.toString()),
      animationKind: animType,
      soundKey: pick(json, ['sound'])?.toString(),
    );
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    return data;
  }

  String? _resolveGiftId(Map<String, dynamic> json) {
    final nested = pick(json, ['giftType', 'gift']);
    if (nested is Map) {
      final m = asJsonMap(nested);
      final id = pick(m, ['id', 'slug', 'giftTypeId'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return pick(json, ['giftTypeId', 'giftId', 'type'])?.toString();
  }

  String _resolveGiftName(Map<String, dynamic> json, String giftId) {
    final nested = pick(json, ['giftType', 'gift']);
    if (nested is Map) {
      final fromType = jsonDisplayLabel(
        nested,
        keys: const ['nameTr', 'name', 'nameEn', 'label'],
      );
      if (fromType != null) return fromType;
    }
    final flat = jsonDisplayLabel(
      pick(json, ['giftName', 'giftTypeName']),
    );
    if (flat != null) return flat;
    return LiveGiftCatalog.displayNameOverrides[giftId] ?? giftId;
  }

  String _resolvePersonName(
    Map<String, dynamic> json, {
    required List<String> flatKeys,
    required List<String> objectKeys,
    String fallback = 'Kullanıcı',
  }) {
    for (final k in flatKeys) {
      final label = jsonDisplayLabel(json[k]);
      if (label != null) return label;
    }
    for (final k in objectKeys) {
      final label = jsonDisplayLabel(json[k]);
      if (label != null) return label;
    }
    return fallback;
  }

  String? _resolvePersonId(Map<String, dynamic> json) {
    final flat = pick(json, ['senderId', 'userId', 'fromUserId'])?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    for (final k in ['sender', 'user', 'fromUser']) {
      final o = json[k];
      if (o is Map) {
        final id = pick(asJsonMap(o), ['id', 'userId'])?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  bool _isValidLabel(String s) {
    if (s.isEmpty) return false;
    if (s.startsWith('{')) return false;
    if (s.contains('image:') || s.contains('https://')) return false;
    return s.length <= 64;
  }
}
