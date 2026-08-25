import '../../live/domain/entities/live_gift_event.dart';
import 'fx_gift_tier.dart';

/// Sesli odada gösterilecek tek hediye satırı.
class FxGiftDisplayItem {
  const FxGiftDisplayItem({
    required this.eventId,
    required this.senderName,
    required this.receiverName,
    required this.giftName,
    required this.jeton,
    required this.at,
    this.giftIcon,
    this.senderId,
    this.receiverId,
  });

  factory FxGiftDisplayItem.fromLiveGift(LiveGiftEvent event) {
    final id = _resolveEventId(event);
    return FxGiftDisplayItem(
      eventId: id,
      senderId: event.senderId,
      senderName: event.senderName.trim().isEmpty ? 'Biri' : event.senderName.trim(),
      receiverId: event.receiverId,
      receiverName: event.receiverName.trim().isEmpty
          ? 'kullanıcı'
          : event.receiverName.trim(),
      giftName: event.giftName.trim().isEmpty ? 'hediye' : event.giftName.trim(),
      giftIcon: event.giftIcon ?? event.iconUrl ?? event.giftImageUrl,
      jeton: event.jetonAmount,
      at: event.timestamp,
    );
  }

  final String eventId;
  final String? senderId;
  final String senderName;
  final String? receiverId;
  final String receiverName;
  final String giftName;
  final String? giftIcon;
  final int jeton;
  final DateTime at;

  FxGiftTier get tier => FxGiftTier.fromJeton(jeton);

  String get compactLine => '$senderName → $receiverName 🎁 $giftName';

  static String _resolveEventId(LiveGiftEvent event) {
    for (final candidate in [
      event.giftHistoryId,
      event.queueItemId,
      event.id,
    ]) {
      final v = candidate?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '${event.senderId}_${event.receiverId}_${event.giftName}_${event.jetonAmount}_${event.timestamp.millisecondsSinceEpoch}';
  }
}
