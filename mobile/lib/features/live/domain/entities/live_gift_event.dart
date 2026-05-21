import 'package:equatable/equatable.dart';

import '../../../gifts/domain/gift_animation_kind.dart';
import '../../../gifts/domain/gift_rarity.dart';

/// Canlı yayında görünen hediye olayı (API poll veya yerel yayın).
class LiveGiftEvent extends Equatable {
  const LiveGiftEvent({
    required this.id,
    required this.senderName,
    required this.receiverName,
    required this.giftId,
    required this.giftName,
    required this.quantity,
    required this.coinCost,
    required this.timestamp,
    this.senderId,
    this.combo = 1,
    this.iconUrl,
    this.animationKey,
    this.rarity = GiftRarity.common,
    this.animationKind = GiftAnimationKind.lottie,
    this.soundKey,
  });

  final String id;
  final String? senderId;
  final String senderName;
  final String receiverName;
  final String giftId;
  final String giftName;
  final int quantity;
  final int coinCost;
  final int combo;
  final DateTime timestamp;
  final String? iconUrl;
  final String? animationKey;
  final GiftRarity rarity;
  final GiftAnimationKind animationKind;
  final String? soundKey;

  String get notificationText {
    final q = quantity > 1 ? '$quantity ' : '';
    return '$senderName → $receiverName $q$giftName gönderdi';
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        receiverName,
        giftId,
        giftName,
        quantity,
        coinCost,
        combo,
        timestamp,
        iconUrl,
        animationKey,
        rarity,
        animationKind,
        soundKey,
      ];
}
