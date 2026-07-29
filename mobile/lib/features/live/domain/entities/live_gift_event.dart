import 'package:equatable/equatable.dart';

import '../../../gifts/domain/gift_animation_kind.dart';
import '../../../gifts/domain/gift_rarity.dart';

/// Canlı yayında görünen hediye olayı (API poll, SSE veya yerel yayın).
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
    this.receiverId,
    this.combo = 1,
    this.iconUrl,
    this.giftImageUrl,
    this.animationKey,
    this.rarity = GiftRarity.common,
    this.animationKind = GiftAnimationKind.lottie,
    this.soundKey,
    this.giftPrice = 0,
    this.totalCoin = 0,
    this.totalDiamond = 0,
    this.remainingBalance,
    this.seatIndex,
    this.senderAvatar,
    this.receiverAvatar,
    this.giftType,
    this.giftIcon,
    this.assetUrl,
    this.assetType,
    this.displayType,
    this.isFullscreen,
    this.visibleAsFullscreen,
    this.screenPosition,
    this.displayDurationMs,
    this.tier,
    this.assetFormat,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.animationDurationMs,
    this.startDelayMs,
    this.effectColor,
    this.musicUrl,
    this.enginePriority,
    this.engineDisplayArea,
    this.engineAnimationType,
    this.engineDurationMs,
    this.engineQueueGapMs,
    this.engineFeedDurationMs,
    this.engineSeatEffects = const [],
    this.engineParticleKey,
    this.mediaType,
    this.mediaWidth,
    this.mediaHeight,
  });

  final String id;
  final String? senderId;
  final String? receiverId;
  final String senderName;
  final String receiverName;
  final String giftId;
  final String giftName;
  final int quantity;
  /// Birim jeton (giftPrice ile aynı; geriye uyumluluk).
  final int coinCost;
  final int giftPrice;
  final int totalCoin;
  final int totalDiamond;
  final int combo;
  final DateTime timestamp;
  final String? iconUrl;
  final String? giftImageUrl;
  final String? animationKey;
  final GiftRarity rarity;
  final GiftAnimationKind animationKind;
  final String? soundKey;
  final int? remainingBalance;
  final int? seatIndex;
  final String? senderAvatar;
  final String? receiverAvatar;
  final String? giftType;
  final String? giftIcon;
  final String? assetUrl;
  final String? assetType;
  final String? displayType;
  final bool? isFullscreen;
  final bool? visibleAsFullscreen;
  final String? screenPosition;
  final int? displayDurationMs;
  final String? tier;
  final String? assetFormat;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? animationDurationMs;
  final int? startDelayMs;
  final String? effectColor;
  final String? musicUrl;
  final String? enginePriority;
  final String? engineDisplayArea;
  final String? engineAnimationType;
  final int? engineDurationMs;
  final int? engineQueueGapMs;
  final int? engineFeedDurationMs;
  final List<String> engineSeatEffects;
  final String? engineParticleKey;
  final String? mediaType;
  final int? mediaWidth;
  final int? mediaHeight;

  int get eventTimestampMs => timestamp.millisecondsSinceEpoch;

  /// Ekranda gösterilecek jeton — asla çift çarpım yapmaz; totalCoin öncelikli.
  int get jetonAmount {
    if (totalCoin > 0) return totalCoin;
    final unit = giftPrice > 0 ? giftPrice : coinCost;
    final q = quantity > 0 ? quantity : 1;
    return unit > 0 ? unit * q : 0;
  }

  String? get displayImageUrl {
    final img = giftImageUrl ?? iconUrl;
    if (img == null || img.isEmpty) return null;
    return img;
  }

  String get notificationText {
    final q = quantity > 1 ? 'x$quantity' : '';
    final jeton = jetonAmount;
    return '$senderName → $receiverName $giftName$q ($jeton jeton) gönderdi';
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        senderName,
        receiverName,
        giftId,
        giftName,
        quantity,
        coinCost,
        giftPrice,
        totalCoin,
        totalDiamond,
        combo,
        timestamp,
        iconUrl,
        giftImageUrl,
        animationKey,
        rarity,
        animationKind,
        soundKey,
        remainingBalance,
        seatIndex,
        senderAvatar,
        receiverAvatar,
        giftType,
        giftIcon,
        assetUrl,
        assetType,
        displayType,
        isFullscreen,
        visibleAsFullscreen,
        screenPosition,
        displayDurationMs,
        tier,
        assetFormat,
        imageUrl,
        videoUrl,
        thumbnailUrl,
        animationDurationMs,
        startDelayMs,
        effectColor,
        musicUrl,
        enginePriority,
        engineDisplayArea,
        engineAnimationType,
        engineDurationMs,
        engineQueueGapMs,
        engineFeedDurationMs,
        engineSeatEffects,
        engineParticleKey,
        mediaType,
        mediaWidth,
        mediaHeight,
      ];
}
