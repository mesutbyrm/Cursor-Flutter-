import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';

/// Combo devre dışı — olaylar olduğu gibi iletilir.
class VoiceGiftComboTracker extends Notifier<void> {
  @override
  void build() {}

  LiveGiftEvent enrich(LiveGiftEvent raw) => raw.copyWithCombo(1);

  void reset() {}
}

final voiceGiftComboTrackerProvider =
    NotifierProvider<VoiceGiftComboTracker, void>(VoiceGiftComboTracker.new);

extension _LiveGiftEventCombo on LiveGiftEvent {
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
      timestamp: timestamp,
      combo: c,
      iconUrl: iconUrl,
      animationKey: animationKey,
      rarity: rarity,
      animationKind: animationKind,
      soundKey: soundKey,
    );
  }
}
