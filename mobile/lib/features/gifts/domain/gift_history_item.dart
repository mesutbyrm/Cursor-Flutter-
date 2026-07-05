import '../../../core/util/json_util.dart';

/// Hediye geçmişi satırı — `/api/gifts/insights/me/history`.
/// direction: sent | received; status: sent/received/refunded/cancelled.
class GiftHistoryItem {
  const GiftHistoryItem({
    required this.id,
    required this.direction,
    required this.counterpartyName,
    required this.giftName,
    this.giftIcon,
    this.amount = 0,
    this.status = 'sent',
    this.context,
    this.at,
  });

  factory GiftHistoryItem.fromJson(Map<String, dynamic> json) {
    return GiftHistoryItem(
      id: (pick(json, ['id', 'eventId']) ?? '').toString(),
      direction:
          (pick(json, ['direction', 'type']) ?? 'sent').toString().toLowerCase(),
      counterpartyName: (pick(json, [
                'counterparty',
                'counterpartyName',
                'otherName',
                'receiverName',
                'senderName',
                'to',
                'from',
              ]) ??
              '')
          .toString(),
      giftName: (pick(json, ['giftName', 'gift', 'name']) ?? 'hediye').toString(),
      giftIcon: pick(json, ['giftIcon', 'icon', 'iconUrl', 'image'])?.toString(),
      amount: asInt(pick(json, ['amount', 'coins', 'quantity', 'count'])),
      status: (pick(json, ['status']) ?? 'sent').toString().toLowerCase(),
      context: pick(json, ['context'])?.toString(),
      at: DateTime.tryParse(
          pick(json, ['at', 'createdAt', 'date', 'timestamp'])?.toString() ??
              ''),
    );
  }

  final String id;
  final String direction; // sent | received
  final String counterpartyName;
  final String giftName;
  final String? giftIcon;
  final int amount;
  final String status; // sent | received | refunded | cancelled
  final String? context;
  final DateTime? at;

  bool get isSent => direction == 'sent';
  bool get isRefunded => status == 'refunded' || status == 'cancelled';
}
