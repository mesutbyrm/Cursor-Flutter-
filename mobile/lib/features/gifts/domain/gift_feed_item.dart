import '../../../core/util/json_util.dart';

/// Canlı hediye akışı satırı — `/api/gifts/insights/feed`.
/// Gizli hediyeler backend tarafından zaten dışlanır.
class GiftFeedItem {
  const GiftFeedItem({
    required this.id,
    required this.senderName,
    required this.receiverName,
    required this.giftName,
    this.giftIcon,
    this.amount = 0,
    this.context,
    this.at,
  });

  factory GiftFeedItem.fromJson(Map<String, dynamic> json) {
    return GiftFeedItem(
      id: (pick(json, ['id', 'eventId']) ?? '').toString(),
      senderName:
          (pick(json, ['senderName', 'sender', 'fromName', 'from']) ?? '')
              .toString(),
      receiverName:
          (pick(json, ['receiverName', 'receiver', 'toName', 'to']) ?? '')
              .toString(),
      giftName: (pick(json, ['giftName', 'gift', 'name']) ?? 'hediye').toString(),
      giftIcon: pick(json, ['giftIcon', 'icon', 'iconUrl', 'image'])?.toString(),
      amount: asInt(pick(json, ['amount', 'coins', 'quantity', 'count'])),
      context: pick(json, ['context'])?.toString(),
      at: DateTime.tryParse(
          pick(json, ['at', 'createdAt', 'date', 'timestamp'])?.toString() ??
              ''),
    );
  }

  final String id;
  final String senderName;
  final String receiverName;
  final String giftName;
  final String? giftIcon;
  final int amount;
  final String? context;
  final DateTime? at;
}
