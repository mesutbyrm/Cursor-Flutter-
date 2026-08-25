import '../../../../core/util/json_util.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/gift_display_settings.dart';
import '../../domain/gift_feed_item.dart';
import '../../domain/homepage_gift_ticker.dart';

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
    this.displayLabel,
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
      displayLabel: HomepageGiftTicker.composeAnnouncement(
        senderName: item.senderName,
        giftName: item.giftName,
        receiverName: item.receiverName,
        amount: item.amount,
        giftIcon: item.giftIcon,
      ),
    );
  }

  factory GlobalGiftNotification.fromTicker(TickerGiftAnnouncement gift) {
    return GlobalGiftNotification(
      eventId: gift.eventId,
      senderName: gift.senderName,
      receiverName: gift.receiverName,
      giftName: gift.giftName,
      amount: gift.amount,
      displayLabel: gift.announcementLabel,
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
      displayLabel: HomepageGiftTicker.composeAnnouncement(
        senderName: event.senderName,
        giftName: event.giftName,
        receiverName: event.receiverName,
        amount: event.jetonAmount,
        giftIcon: event.giftIcon ?? event.iconUrl ?? event.giftImageUrl,
      ),
    );
  }

  factory GlobalGiftNotification.fromMap(Map<String, dynamic> json) {
    final eventId = (json['eventId'] ??
            json['id'] ??
            json['transactionId'] ??
            '')
        .toString()
        .trim();
    final senderName = jsonDisplayLabelOr(
      json['senderName'] ?? json['fromName'] ?? json['sender'] ?? json['from'],
      'Biri',
    );
    final receiverName = jsonDisplayLabel(
      json['receiverName'] ?? json['receiver'] ?? json['toName'] ?? json['to'],
    );
    final giftName = jsonDisplayLabelOr(
      json['giftName'] ?? json['gift'] ?? json['name'],
      'Hediye',
    );
    final giftMap = json['gift'];
    final nestedIcon = giftMap is Map
        ? (giftMap['icon'] ?? giftMap['iconUrl'] ?? giftMap['emoji'])
        : null;
    final nestedAmount = giftMap is Map
        ? (giftMap['price'] ?? giftMap['jeton'] ?? giftMap['amount'])
        : null;
    final giftIcon = (json['giftIcon'] ??
            json['icon'] ??
            json['iconUrl'] ??
            nestedIcon)
        ?.toString();
    final amount = _asInt(
      json['amount'] ?? json['jeton'] ?? json['coinCost'] ?? nestedAmount,
    );
    return GlobalGiftNotification(
      eventId: eventId.isNotEmpty ? eventId : _syntheticIdFromMap(json),
      giftId: json['giftId']?.toString(),
      senderId: json['senderId']?.toString(),
      senderName: senderName,
      receiverId: json['receiverId']?.toString(),
      receiverName: receiverName,
      giftName: giftName,
      giftIcon: giftIcon,
      amount: amount,
      roomId: json['roomId']?.toString(),
      timestamp: DateTime.tryParse(
            json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      displayLabel: HomepageGiftTicker.composeAnnouncement(
        senderName: senderName,
        giftName: giftName,
        receiverName: receiverName,
        amount: amount,
        giftIcon: giftIcon,
      ),
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
  final String? displayLabel;

  /// Aynı hediyeyi ticker + feed + bildirimden bir kez göstermek için.
  String get semanticKey {
    final sender = senderName.trim().toLowerCase();
    final recv = (receiverName ?? '').trim().toLowerCase();
    final gift = giftName.trim().toLowerCase();
    return '$sender|$recv|$gift|$amount';
  }

  String label(GiftDisplaySettings settings) {
    final custom = displayLabel?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return HomepageGiftTicker.composeAnnouncement(
      senderName: settings.showSender ? senderName : '',
      giftName: settings.showGiftName ? giftName : 'Hediye',
      receiverName: receiverName,
      amount: settings.showAmount ? amount : 0,
      giftIcon: settings.showGiftIcon ? giftIcon : null,
    );
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
