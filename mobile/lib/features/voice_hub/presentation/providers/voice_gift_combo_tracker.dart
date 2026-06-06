import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../gifts/domain/premium_gift_catalog_2026.dart';

/// Aynı gönderici + hediye için combo birleştirme (TikTok tarzı).
class VoiceGiftComboTracker extends Notifier<void> {
  static const _window = Duration(seconds: 8);

  final _last = <String, _ComboSlot>{};

  @override
  void build() {}

  LiveGiftEvent enrich(LiveGiftEvent raw) {
    final senderKey = raw.senderId ?? raw.senderName;
    final giftKey = PremiumGiftCatalog2026.canonicalId(raw.giftId) ?? raw.giftId;
    final key = '$senderKey:$giftKey';
    final now = DateTime.now();
    final prev = _last[key];

    var combo = raw.combo;
    var qty = raw.quantity;
    if (prev != null && now.difference(prev.at) <= _window) {
      combo = prev.combo + raw.quantity;
      qty = prev.totalQty + raw.quantity;
    } else {
      combo = raw.combo > 1 ? raw.combo : raw.quantity;
      qty = raw.quantity;
    }

    _last[key] = _ComboSlot(at: now, combo: combo, totalQty: qty);

    final rarity = PremiumGiftCatalog2026.rarity(raw.giftId);
    final name = PremiumGiftCatalog2026.displayName(
      raw.giftId,
      fallback: raw.giftName,
    );

    return LiveGiftEvent(
      id: raw.id,
      senderId: raw.senderId,
      senderName: raw.senderName,
      receiverName: raw.receiverName,
      giftId: giftKey,
      giftName: name,
      quantity: qty,
      coinCost: raw.coinCost,
      timestamp: raw.timestamp,
      combo: combo,
      iconUrl: raw.iconUrl,
      animationKey: raw.animationKey,
      rarity: rarity.index > raw.rarity.index ? rarity : raw.rarity,
      animationKind: raw.animationKind,
      soundKey: raw.soundKey,
    );
  }

  void reset() => _last.clear();
}

class _ComboSlot {
  _ComboSlot({
    required this.at,
    required this.combo,
    required this.totalQty,
  });

  final DateTime at;
  final int combo;
  final int totalQty;
}

final voiceGiftComboTrackerProvider =
    NotifierProvider<VoiceGiftComboTracker, void>(VoiceGiftComboTracker.new);
