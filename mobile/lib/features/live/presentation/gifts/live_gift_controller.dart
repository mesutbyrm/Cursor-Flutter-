import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../gifts/data/gift_sound_service.dart';
import '../../../gifts/domain/gift_revenue_display.dart';
import '../../../gifts/domain/lucky_gift_entities.dart';
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

  Future<LuckyGiftSpinResult?> send({
    required LiveVideoGiftType gift,
    required String senderName,
    String? senderId,
    int quantity = 1,
    String? toUserId,
    String? pkMatchId,
  }) async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty || sending) return null;
    panelOpen = false;
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
        isLucky: gift.isLucky,
      );
      if (result.luckyResult != null) {
        if (result.newBalance != null) coinBalance = result.newBalance;
        return result.luckyResult;
      }
      if (result.newBalance != null) coinBalance = result.newBalance;

      await _sound?.playFor(gift.toEntity());
      return null;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void _onIncoming(LiveGiftEvent event) {
    if (!_isDisplayable(event)) return;
    final gross = event.jetonAmount;
    streamerEarnings =
        (streamerEarnings ?? 0) + GiftRevenueDisplay.liveBroadcasterNet(gross);
    if (event.remainingBalance != null && event.remainingBalance! > 0) {
      coinBalance = event.remainingBalance;
    }
    notifyListeners();
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
