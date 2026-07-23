import '../../../gifts/domain/lucky_gift_entities.dart';

/// Hediye gönderimi sonrası backend gelir dağılımı (salt okunur).
class VoiceGiftRevenueBreakdown {
  const VoiceGiftRevenueBreakdown({
    required this.total,
    required this.roomType,
    required this.receiverNet,
    required this.ownerNet,
    required this.siteAmount,
  });

  final int total;
  final String roomType;
  final int receiverNet;
  final int ownerNet;
  final int siteAmount;

  factory VoiceGiftRevenueBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const VoiceGiftRevenueBreakdown(
        total: 0,
        roomType: 'NORMAL',
        receiverNet: 0,
        ownerNet: 0,
        siteAmount: 0,
      );
    }
    final receiver = json['receiver'];
    final owner = json['owner'];
    final site = json['site'];
    return VoiceGiftRevenueBreakdown(
      total: (json['total'] as num?)?.toInt() ?? 0,
      roomType: json['roomType']?.toString() ?? 'NORMAL',
      receiverNet: receiver is Map
          ? (receiver['net'] as num?)?.toInt() ?? 0
          : (json['receiverNet'] as num?)?.toInt() ?? 0,
      ownerNet: owner is Map
          ? (owner['net'] as num?)?.toInt() ?? 0
          : (json['ownerNet'] as num?)?.toInt() ?? 0,
      siteAmount: site is Map
          ? (site['amount'] as num?)?.toInt() ?? 0
          : (json['siteAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class VoiceGiftSendResult {
  const VoiceGiftSendResult({this.revenue, this.luckyResult});

  final VoiceGiftRevenueBreakdown? revenue;
  final LuckyGiftSpinResult? luckyResult;
}
