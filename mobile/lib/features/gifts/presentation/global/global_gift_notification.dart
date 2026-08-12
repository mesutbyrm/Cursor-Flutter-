import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/gift_display_settings.dart';
import '../../domain/gift_feed_item.dart';

/// Tek bir global hediye bildirimi — kuyruk öğesi.
class GlobalGiftNotification {
  const GlobalGiftNotification({
    required this.eventId,
    required this.senderName,
    this.receiverName,
    required this.giftName,
    this.giftIcon,
    this.amount = 0,
    this.giftId,
    this.senderId,
    this.receiverId,
    this.roomId,
    this.timestamp,
  });

  factory GlobalGiftNotification.fromFeedItem(GiftFeedItem item) {
    return GlobalGiftNotification(
      eventId: item.id.isNotEmpty ? item.id : _syntheticId(item),
      senderName: item.senderName,
      receiverName: item.receiverName,
      giftName: item.giftName,
      giftIcon: item.giftIcon,
      amount: item.amount,
      timestamp: item.at ?? DateTime.now(),
    );
  }

  factory GlobalGiftNotification.fromLiveGift(LiveGiftEvent event) {
    final id = event.giftHistoryId?.trim() ??
        event.queueItemId?.trim() ??
        event.id.trim();
    return GlobalGiftNotification(
      eventId: id.isNotEmpty
          ? id
          : '${event.senderId}_${event.receiverId}_${event.giftName}_${event.jetonAmount}',
      senderId: event.senderId,
      senderName: event.senderName,
      receiverId: event.receiverId,
      receiverName: event.receiverName,
      giftId: event.giftId,
      giftName: event.giftName,
      giftIcon: event.giftIcon ?? event.iconUrl ?? event.giftImageUrl,
      amount: event.jetonAmount,
      timestamp: event.timestamp,
    );
  }

  factory GlobalGiftNotification.fromMap(Map<String, dynamic> json) {
    final eventId = (json['eventId'] ??
            json['id'] ??
            json['transactionId'] ??
            '')
        .toString()
        .trim();
    return GlobalGiftNotification(
      eventId: eventId.isNotEmpty ? eventId : _syntheticIdFromMap(json),
      giftId: json['giftId']?.toString(),
      senderId: json['senderId']?.toString(),
      senderName: (json['senderName'] ?? json['fromName'] ?? 'Biri').toString(),
      receiverId: json['receiverId']?.toString(),
      receiverName: json['receiverName']?.toString(),
      giftName: (json['giftName'] ?? json['name'] ?? 'Hediye').toString(),
      giftIcon: (json['giftIcon'] ?? json['icon'] ?? json['iconUrl'])?.toString(),
      amount: _asInt(json['amount'] ?? json['jeton'] ?? json['coinCost']),
      roomId: json['roomId']?.toString(),
      timestamp: DateTime.tryParse(
            json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  final String eventId;
  final String? giftId;
  final String? senderId;
  final String senderName;
  final String? receiverId;
  final String? receiverName;
  final String giftName;
  final String? giftIcon;
  final int amount;
  final String? roomId;
  final DateTime? timestamp;

  String label(GiftDisplaySettings settings) {
    final parts = <String>[];
    if (settings.showSender) {
      parts.add(senderName.trim().isEmpty ? 'Biri' : senderName.trim());
    }
    if (settings.showGiftIcon && (giftIcon?.isNotEmpty ?? false)) {
      parts.add(giftIcon!.trim());
    } else if (settings.showGiftName) {
      parts.add(giftName.trim().isEmpty ? 'Hediye' : giftName.trim());
    }
    if (settings.showAmount && amount > 0) {
      parts.add('×$amount');
    }
    if (settings.showReceiver &&
        receiverName != null &&
        receiverName!.trim().isNotEmpty) {
      parts.add('→ ${receiverName!.trim()}');
    }
    if (parts.isEmpty) return '🎁 Hediye';
    return parts.join('  ');
  }

  static String _syntheticId(GiftFeedItem item) =>
      '${item.senderName}_${item.receiverName}_${item.giftName}_${item.amount}';

  static String _syntheticIdFromMap(Map<String, dynamic> json) =>
      '${json['senderName']}_${json['receiverName']}_${json['giftName']}_${json['amount']}';

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
