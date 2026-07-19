import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../gifts/data/gift_sound_service.dart';
import '../../../gifts/domain/gift_revenue_display.dart';
import '../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../data/datasources/live_gifts_remote_datasource.dart';
import '../../data/services/live_gift_realtime_service.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_gift_type.dart';

class LiveGiftController extends ChangeNotifier {
  LiveGiftController({
    required LiveGiftsRemoteDataSource remote,
    required LiveGiftRealtimeService realtime,
    GiftSoundService? sound,
  })  : _remote = remote,
        _realtime = realtime,
        _sound = sound {
    _sub = _realtime.events.listen(_onIncoming);
  }

  final LiveGiftsRemoteDataSource _remote;
  final LiveGiftRealtimeService _realtime;
  final GiftSoundService? _sound;
  StreamSubscription<LiveGiftEvent>? _sub;

  final List<LiveGiftEvent> notifications = [];
  LiveGiftEvent? activeFullscreen;
  final List<LiveGiftEvent> fullscreenQueue = [];
  int? coinBalance;
  int? streamerEarnings;

  String? _streamId;
  String? _receiverName;

  bool panelOpen = false;
  bool sending = false;

  void attach({
    required String streamId,
    required String receiverName,
    int? initialCoins,
  }) {
    _streamId = streamId;
    _receiverName = receiverName;
    coinBalance = initialCoins;
    _realtime.start(streamId);
    notifyListeners();
  }

  void detach() {
    _realtime.stop();
    _streamId = null;
    notifications.clear();
    activeFullscreen = null;
    fullscreenQueue.clear();
    panelOpen = false;
    notifyListeners();
  }

  void setPanelOpen(bool open) {
    panelOpen = open;
    notifyListeners();
  }

  Future<List<LiveVideoGiftType>> loadCatalog() =>
      _remote.fetchGiftTypes();

  Future<void> send({
    required LiveVideoGiftType gift,
    required String senderName,
    String? senderId,
    int quantity = 1,
    String? toUserId,
    String? pkMatchId,
  }) async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty || sending) return;
    sending = true;
    notifyListeners();

    final name = LiveGiftCatalog.displayName(gift);
    try {
      final result = await _remote.sendGift(
        streamId: streamId,
        giftTypeId: gift.id,
        senderName: senderName,
        receiverName: _receiverName ?? 'Yayıncı',
        giftName: name,
        unitPrice: gift.price,
        quantity: quantity,
        senderId: senderId,
        toUserId: toUserId,
        pkMatchId: pkMatchId,
      );
      if (result.newBalance != null) coinBalance = result.newBalance;

      final base = result.event!;
      final enriched = _withoutCombo(
        LiveGiftEvent(
          id: base.id,
          senderId: base.senderId ?? senderId,
          senderName: base.senderName,
          receiverName: base.receiverName,
          giftId: base.giftId,
          giftName: base.giftName,
          quantity: base.quantity,
          coinCost: base.coinCost > 0 ? base.coinCost : gift.price,
          giftPrice: base.giftPrice > 0 ? base.giftPrice : gift.price,
          totalCoin: base.totalCoin > 0
              ? base.totalCoin
              : (base.coinCost > 0
                  ? base.coinCost * base.quantity
                  : gift.price * quantity),
          totalDiamond: base.totalDiamond,
          combo: 1,
          timestamp: base.timestamp,
          iconUrl: base.iconUrl ?? base.giftImageUrl ?? gift.iconPath,
          giftImageUrl: base.giftImageUrl ?? base.iconUrl ?? gift.iconPath,
          animationKey: base.animationKey ?? gift.animationRef,
          rarity: gift.rarity,
          animationKind: gift.animationKind,
          soundKey: base.soundKey ?? gift.soundKey,
        ),
      );
      _realtime.publishLocal(enriched);
      await _sound?.playFor(gift.toEntity());
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  LiveGiftEvent _withoutCombo(LiveGiftEvent event) => event.copyWithCombo(1);

  void _onIncoming(LiveGiftEvent event) {
    if (!_isDisplayable(event)) return;
    final enriched = _withoutCombo(event);
    // Tek bildirim katmanı — chat üstü stack. Center toast ayrı render edilmez.
    notifications.insert(0, enriched);
    if (notifications.length > 5) {
      notifications.removeRange(5, notifications.length);
    }

    final showFs = PremiumGiftCatalog2026.triggersFullscreen(
      giftId: enriched.giftId,
      coinCost: enriched.jetonAmount,
    );
    if (showFs) {
      fullscreenQueue
        ..clear()
        ..add(enriched);
      activeFullscreen = enriched;
      final duration = enriched.rarity.fullscreenDuration;
      Future.delayed(duration, () {
        fullscreenQueue.removeWhere((e) => e.id == enriched.id);
        if (activeFullscreen?.id == enriched.id) {
          activeFullscreen =
              fullscreenQueue.isNotEmpty ? fullscreenQueue.first : null;
        }
        notifyListeners();
      });
    }

    final gross = enriched.jetonAmount;
    streamerEarnings =
        (streamerEarnings ?? 0) + GiftRevenueDisplay.liveBroadcasterNet(gross);
    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () {
      notifications.removeWhere((e) => e.id == enriched.id);
      notifyListeners();
    });
  }

  bool _isDisplayable(LiveGiftEvent e) {
    bool ok(String s) => s.trim().isNotEmpty && !s.startsWith('{');
    return ok(e.senderName) && ok(e.receiverName) && ok(e.giftName);
  }

  @override
  void dispose() {
    _sub?.cancel();
    detach();
    super.dispose();
  }
}

extension _LiveGiftEventCopy on LiveGiftEvent {
  LiveGiftEvent copyWithCombo(int c) {
    return LiveGiftEvent(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      receiverName: receiverName,
      giftId: giftId,
      giftName: giftName,
      quantity: quantity,
      coinCost: coinCost,
      giftPrice: giftPrice,
      totalCoin: totalCoin,
      totalDiamond: totalDiamond,
      combo: c,
      timestamp: timestamp,
      iconUrl: iconUrl,
      giftImageUrl: giftImageUrl,
      animationKey: animationKey,
      rarity: rarity,
      animationKind: animationKind,
      soundKey: soundKey,
    );
  }
}
