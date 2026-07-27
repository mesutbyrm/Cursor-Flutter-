import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/gift_idempotency.dart';
import '../../../gifts/data/lucky_gift_remote_datasource.dart';
import '../../../gifts/domain/lucky_gift_entities.dart';
import '../../../gifts/data/gift_reciprocal_guard.dart';
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
    this.luckyResult,
  });

  final int? newBalance;
  final int? streamerBalance;
  final LiveGiftEvent? event;
  final LuckyGiftSpinResult? luckyResult;
}

class LiveGiftsRemoteDataSource {
  LiveGiftsRemoteDataSource(this._dio, {LuckyGiftRemoteDataSource? lucky})
      : _lucky = lucky ?? LuckyGiftRemoteDataSource(_dio);

  final Dio _dio;
  final LuckyGiftRemoteDataSource _lucky;

  Future<List<LiveVideoGiftType>> fetchGiftTypes({
    GiftPlatform platform = GiftPlatform.mobile,
    String? context,
  }) async {
    try {
      final cms = await _lucky.fetchCatalogCms(
        platform: platform,
        context: context,
      );
      if (cms.isNotEmpty) {
        return cms.map(LiveVideoGiftType.fromGift).toList();
      }
    } catch (_) {}
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGiftsCatalog,
      query: {'platform': platform.queryValue},
    );
    return _parseGiftTypeList(_unwrap(res.data));
  }

  Future<List<LiveVideoGiftType>> fetchGiftTypesFromGiftsApi({
    GiftPlatform platform = GiftPlatform.mobile,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsCatalog,
      query: {'platform': platform.queryValue},
    );
    return _parseGiftTypeList(_unwrap(res.data));
  }

  List<LiveVideoGiftType> _parseGiftTypeList(dynamic data) {
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
    String? toUserId,
    String? pkMatchId,
    bool isLucky = false,
  }) async {
    if (isLucky) {
      final lucky = await _lucky.sendLuckyGift(
        giftTypeId: giftTypeId,
        quantity: quantity,
        context: pkMatchId != null && pkMatchId.isNotEmpty ? 'pk' : 'live_stream',
        contextId: streamId,
      );
      return LiveGiftSendResult(
        newBalance: lucky.newBalance,
        luckyResult: lucky,
      );
    }
    if (toUserId != null && toUserId.isNotEmpty) {
      await assertReciprocalGiftAllowed(_dio, toUserId);
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamGifts(streamId),
      data: {
        // Kılavuz §9.4: giftId; üretimde giftTypeId de kabul edilir.
        'giftId': giftTypeId,
        'giftTypeId': giftTypeId,
        'quantity': quantity,
        'idempotencyKey': newGiftIdempotencyKey(),
        'platform': GiftPlatform.mobile.queryValue,
        if (senderName.trim().isNotEmpty) 'senderName': senderName.trim(),
        if (receiverName.trim().isNotEmpty) 'receiverName': receiverName.trim(),
        // PK Faz 2: belirli bir koltuk misafirine hediye → puan o koltuğa/takıma.
        if (toUserId != null && toUserId.isNotEmpty) 'toUserId': toUserId,
        if (pkMatchId != null && pkMatchId.isNotEmpty) 'pkMatchId': pkMatchId,
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
          coinCost: unitPrice,
          giftPrice: unitPrice,
          totalCoin: unitPrice * quantity,
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
    final catalogId = _resolveCatalogGiftId(json);
    if (catalogId == null || catalogId.isEmpty) return null;

    final tsMs = _normalizeTimestampMs(
      pick(json, ['timestamp', 'ts', 'eventTimestamp']),
      pick(json, ['createdAt', 'created_at'])?.toString(),
    );
    final ts = tsMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(tsMs)
        : DateTime.now();

    var id = pick(json, ['id', '_id', 'giftEventId'])?.toString();
    if (id == null || id.isEmpty) {
      id = pick(json, ['giftId'])?.toString();
    }
    if (id == null || id.isEmpty) {
      id = '$streamId-$tsMs-$catalogId';
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
        'recipientName',
        'streamerName',
        'hostName',
        'toUserName',
      ],
      objectKeys: const ['receiver', 'streamer', 'host', 'toUser', 'to'],
      fallback: 'Yayıncı',
    );

    // İsim geçersizse (ikon URL'i, JSON parçası, çok uzun metin) hediyeyi
    // DÜŞÜRME — güvenli varsayılan adla göster; animasyon yine çalışsın.
    var giftName = _resolveGiftName(json, catalogId);
    if (!_isValidLabel(giftName)) {
      giftName = LiveGiftCatalog.displayNameOverrides[catalogId] ?? 'Hediye';
    }

    final qtyRaw = asInt(pick(json, ['quantity', 'count', 'amount', 'giftCount']));
    final qty = qtyRaw > 0 ? qtyRaw : 1;
    final giftPrice = asInt(
      pick(json, ['giftPrice', 'unitPrice', 'pricePerUnit', 'coinPrice']),
    );
    // SSE dokümanı: giftType.price iç içe gelebilir.
    final nestedGiftPrice = () {
      final gt = json['giftType'] ?? json['gift'];
      if (gt is Map) {
        return asInt(pick(asJsonMap(gt), ['price', 'coinCost', 'jeton']));
      }
      return 0;
    }();
    final nestedTotalCoin = () {
      final gt = json['giftType'] ?? json['gift'];
      if (gt is Map) {
        return asInt(
          pick(asJsonMap(gt), [
            'totalPrice',
            'totalCoin',
            'totalCoins',
            'amount',
          ]),
        );
      }
      return 0;
    }();
    final totalCoin = asInt(
      pick(json, [
        'totalCoin',
        'totalCoins',
        'totalCost',
        'totalPrice',
        'amount',
        'coins',
        'jeton',
        'jetonAmount',
        'giftJeton',
        'coinAmount',
      ]),
    );
    final totalDiamond = asInt(
      pick(json, ['totalDiamond', 'totalDiamonds', 'diamonds']),
    );
    final legacyPrice = asInt(pick(json, ['price', 'coinCost']));
    final resolvedGiftPrice = giftPrice > 0 ? giftPrice : nestedGiftPrice;
    final unitPrice = resolvedGiftPrice > 0
        ? resolvedGiftPrice
        : (totalCoin > 0 && qty > 0
            ? totalCoin ~/ qty
            : (legacyPrice > 0 && qty > 1 && legacyPrice >= qty
                ? legacyPrice ~/ qty
                : legacyPrice));
    final resolvedTotal = totalCoin > 0
        ? totalCoin
        : (nestedTotalCoin > 0
            ? nestedTotalCoin
            : (unitPrice > 0 ? unitPrice * qty : legacyPrice));
    final comboRaw = asInt(pick(json, ['combo', 'comboCount']));

    final icon = pick(json, [
      'giftImage',
      'giftImageUrl',
      'image',
      'icon',
      'iconUrl',
      'giftIcon',
    ])?.toString();
    // SSE dokümanı: giftType.icon / gift.giftIcon iç içe gelebilir.
    String? nestedIcon;
    final giftType = json['giftType'] ?? json['gift'];
    if (giftType is Map) {
      final gt = asJsonMap(giftType);
      nestedIcon = pick(gt, ['icon', 'iconUrl', 'image', 'giftIcon'])
          ?.toString();
    }
    final iconUrl = _resolveImageUrl(icon ?? nestedIcon);

    final animKey = pick(json, ['animation', 'animationKey', 'assetUrl'])
        ?.toString();
    String? nestedAnimUrl;
    String? nestedAssetType;
    if (giftType is Map) {
      final gt = asJsonMap(giftType);
      nestedAnimUrl = pick(gt, ['assetUrl', 'animationUrl', 'animation'])
          ?.toString();
      nestedAssetType =
          pick(gt, ['assetType', 'animationType', 'animationKind'])?.toString();
    }
    final resolvedAnimKey = animKey ?? nestedAnimUrl;
    final animType = GiftAnimationKind.parse(
      pick(json, ['animationType', 'animationKind', 'assetType'])?.toString() ??
          nestedAssetType,
    );
    final resolvedAnimType = animType == GiftAnimationKind.lottie &&
            resolvedAnimKey != null
        ? GiftAnimationKind.fromUrl(resolvedAnimKey)
        : animType;
    final finalAnimType =
        resolvedAnimType != GiftAnimationKind.none ? resolvedAnimType : animType;

    final render = () {
      final r = json['giftRender'] ?? json['render'];
      if (r is Map) return asJsonMap(r);
      return json;
    }();

    return LiveGiftEvent(
      id: id,
      senderId: _resolvePersonId(json),
      receiverId: _resolveReceiverId(json),
      senderName: sender,
      receiverName: receiver,
      giftId: catalogId,
      giftName: giftName,
      quantity: qty,
      coinCost: unitPrice,
      giftPrice: unitPrice,
      totalCoin: resolvedTotal,
      totalDiamond: totalDiamond,
      combo: comboRaw > 0 ? comboRaw : 1,
      timestamp: ts,
      iconUrl: iconUrl,
      giftImageUrl: iconUrl,
      animationKey: resolvedAnimKey,
      rarity: GiftRarity.parse(pick(json, ['rarity'])?.toString()),
      animationKind: finalAnimType,
      soundKey: pick(json, ['sound'])?.toString(),
      remainingBalance: asInt(
        pick(json, [
          'remainingBalance',
          'balance',
          'newBalance',
          'coinBalance',
        ]),
      ),
      seatIndex: asInt(pick(json, ['seatIndex', 'seat_index'])),
      senderAvatar: _resolveImageUrl(
        pick(json, ['senderAvatar', 'senderImage', 'sender_avatar'])?.toString(),
      ),
      receiverAvatar: _resolveImageUrl(
        pick(json, [
          'receiverAvatar',
          'receiverImage',
          'receiver_avatar',
        ])?.toString(),
      ),
      giftType: pick(json, ['giftType', 'type', 'gift_type'])?.toString(),
      giftIcon: pick(render, ['giftIcon', 'icon', 'gift_icon'])?.toString() ??
          pick(json, ['giftIcon'])?.toString(),
      assetUrl: _resolveImageUrl(
        pick(render, ['assetUrl', 'animationUrl', 'animation'])?.toString() ??
            nestedAnimUrl ??
            resolvedAnimKey,
      ),
      assetType: pick(render, ['assetType', 'animationType'])?.toString() ??
          nestedAssetType,
      displayType:
          pick(render, ['displayType', 'display_type'])?.toString(),
      isFullscreen: pick(render, ['isFullscreen']) == true ||
          json['isFullscreen'] == true,
      visibleAsFullscreen: pick(render, ['visibleAsFullscreen']) == true,
      screenPosition:
          pick(render, ['screenPosition', 'screen_position'])?.toString(),
      displayDurationMs: asInt(
        pick(render, ['displayDurationMs', 'display_duration_ms']),
      ),
      tier: pick(render, ['tier'])?.toString(),
      assetFormat: pick(render, ['assetFormat', 'asset_format'])?.toString() ??
          pick(json, ['assetFormat', 'asset_format'])?.toString(),
      imageUrl: _resolveImageUrl(
        pick(render, ['imageUrl', 'image_url'])?.toString() ??
            pick(json, ['imageUrl', 'image_url'])?.toString(),
      ),
      videoUrl: _resolveImageUrl(
        pick(render, ['videoUrl', 'video_url'])?.toString() ??
            pick(json, ['videoUrl', 'video_url'])?.toString(),
      ),
      thumbnailUrl: _resolveImageUrl(
        pick(render, ['thumbnailUrl', 'thumbnail_url'])?.toString() ??
            pick(json, ['thumbnailUrl', 'thumbnail_url'])?.toString(),
      ),
      animationDurationMs: asInt(
        pick(render, ['animationDurationMs', 'animation_duration_ms']),
      ),
      startDelayMs: asInt(pick(render, ['startDelayMs', 'start_delay_ms'])),
      effectColor: pick(render, ['effectColor', 'effect_color'])?.toString(),
      musicUrl: _resolveImageUrl(
        pick(render, ['musicUrl', 'music_url', 'soundUrl'])?.toString(),
      ),
    );
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    return data;
  }

  int _normalizeTimestampMs(dynamic raw, String? iso) {
    var ms = asInt(raw);
    if (ms > 0 && ms < 10000000000) ms *= 1000;
    if (ms > 0) return ms;
    final parsed = DateTime.tryParse(iso ?? '');
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String? _resolveCatalogGiftId(Map<String, dynamic> json) {
    final nested = pick(json, ['giftType', 'gift']);
    if (nested is Map) {
      final m = asJsonMap(nested);
      final id = pick(m, ['id', 'slug', 'giftTypeId', 'giftId'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return pick(json, ['giftTypeId', 'giftId', 'type', 'slug'])?.toString();
  }

  String? _resolveGiftId(Map<String, dynamic> json) => _resolveCatalogGiftId(json);

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (_isBareAssetFilename(raw)) return null;
    return '${Env.siteOrigin}${raw.startsWith('/') ? raw : '/$raw'}';
  }

  bool _isBareAssetFilename(String s) {
    final l = s.trim().toLowerCase();
    if (l.startsWith('http')) return false;
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.webp') ||
        l.endsWith('.gif') ||
        l.endsWith('.svga') ||
        l.endsWith('.json') ||
        l.contains('assets/');
  }

  String _resolveGiftName(Map<String, dynamic> json, String giftId) {
    final nested = pick(json, ['giftType', 'gift']);
    if (nested is Map) {
      final fromType = jsonDisplayLabel(
        nested,
        keys: const ['nameTr', 'name', 'nameEn', 'label', 'giftName'],
      );
      if (fromType != null && !_isBareAssetFilename(fromType)) return fromType;
    }
    final flat = jsonDisplayLabel(
      pick(json, ['giftName', 'giftTypeName', 'name']),
    );
    if (flat != null && !_isBareAssetFilename(flat)) return flat;
    return LiveGiftCatalog.displayNameOverrides[giftId] ?? 'Hediye';
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

  String? _resolveReceiverId(Map<String, dynamic> json) {
    final flat = pick(json, [
      'receiverId',
      'receiverUserId',
      'toUserId',
      'recipientId',
      'streamerId',
      'hostId',
    ])?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    for (final k in ['receiver', 'streamer', 'host', 'toUser', 'to']) {
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
