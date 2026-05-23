import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../gifts/data/gift_sound_service.dart';
import '../../data/datasources/live_gifts_remote_datasource.dart';
import '../../data/services/live_gift_realtime_service.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_gift_type.dart';

/// Combo: aynı gönderen + hediye, 4 sn içinde tekrar.
class _ComboKey {
  _ComboKey(this.senderId, this.giftId);
  final String senderId;
  final String giftId;

  @override
  bool operator ==(Object other) =>
      other is _ComboKey && other.senderId == senderId && other.giftId == giftId;

  @override
  int get hashCode => Object.hash(senderId, giftId);
}

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
  int? coinBalance;
  int? streamerEarnings;

  String? _streamId;
  String? _receiverName;
  final _combo = <_ComboKey, _ComboState>{};

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
    _combo.clear();
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
      );
      if (result.newBalance != null) coinBalance = result.newBalance;
      if (result.streamerBalance != null) {
        streamerEarnings = result.streamerBalance;
      } else if (result.event != null) {
        streamerEarnings = (streamerEarnings ?? 0) + gift.price * quantity;
      }

      final base = result.event!;
      final enriched = _applyCombo(
        LiveGiftEvent(
          id: base.id,
          senderId: base.senderId ?? senderId,
          senderName: base.senderName,
          receiverName: base.receiverName,
          giftId: base.giftId,
          giftName: base.giftName,
          quantity: base.quantity,
          coinCost: base.coinCost,
          combo: base.combo,
          timestamp: base.timestamp,
          iconUrl: base.iconUrl ?? gift.iconPath,
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

  LiveGiftEvent _applyCombo(LiveGiftEvent event) {
    final key = _ComboKey(event.senderId ?? event.senderName, event.giftId);
    final now = DateTime.now();
    final state = _combo[key];
    if (state != null && now.difference(state.lastAt).inSeconds <= 4) {
      state.count += event.quantity;
      state.lastAt = now;
      return event.copyWithCombo(state.count);
    }
    _combo[key] = _ComboState(event.quantity, now);
    return event.copyWithCombo(1);
  }

  void _onIncoming(LiveGiftEvent event) {
    if (!_isDisplayable(event)) return;
    final enriched = _applyCombo(event);
    notifications.insert(0, enriched);
    if (notifications.length > 5) {
      notifications.removeRange(5, notifications.length);
    }
    activeFullscreen = enriched;
    notifyListeners();

    final duration = enriched.rarity.fullscreenDuration;
    Future.delayed(duration, () {
      if (activeFullscreen?.id == enriched.id) {
        activeFullscreen = null;
        notifyListeners();
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      notifications.removeWhere((e) => e.id == enriched.id);
      notifyListeners();
    });
  }

  bool _isDisplayable(LiveGiftEvent e) {
    bool ok(String s) =>
        s.isNotEmpty && !s.startsWith('{') && !s.contains('https://');
    return ok(e.senderName) && ok(e.receiverName) && ok(e.giftName);
  }

  @override
  void dispose() {
    _sub?.cancel();
    detach();
    super.dispose();
  }
}

class _ComboState {
  _ComboState(this.count, this.lastAt);
  int count;
  DateTime lastAt;
}

extension _LiveGiftEventCopy on LiveGiftEvent {
  LiveGiftEvent copyWithCombo(int c) {
    return LiveGiftEvent(
      id: id,
      senderId: senderId,
      senderName: senderName,
      receiverName: receiverName,
      giftId: giftId,
      giftName: giftName,
      quantity: quantity,
      coinCost: coinCost,
      combo: c,
      timestamp: timestamp,
      iconUrl: iconUrl,
      animationKey: animationKey,
      rarity: rarity,
      animationKind: animationKind,
      soundKey: soundKey,
    );
  }
}
