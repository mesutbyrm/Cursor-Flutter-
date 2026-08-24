import 'package:equatable/equatable.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/gift_engine_models.dart';

/// Son hediyeler kutusu — combo backend'den.
class GiftRecentItem extends Equatable {
  const GiftRecentItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverName,
    required this.giftId,
    required this.giftName,
    required this.jetonAmount,
    required this.combo,
    required this.at,
    this.iconUrl,
    this.seatIndex,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String receiverName;
  final String giftId;
  final String giftName;
  final int jetonAmount;
  final int combo;
  final DateTime at;
  final String? iconUrl;
  final int? seatIndex;

  String get comboLabel => combo > 1 ? ' x$combo' : '';

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        receiverName,
        giftId,
        giftName,
        jetonAmount,
        combo,
        at,
        iconUrl,
        seatIndex,
      ];
}

/// Animasyon bitince uygulanacak jeton / feed güncellemesi.
class GiftDeferredApply extends Equatable {
  const GiftDeferredApply({
    required this.event,
    required this.recentItem,
    required this.feedItem,
    required this.roomTotalJeton,
    this.remainingBalance,
  });

  final LiveGiftEvent event;
  final GiftRecentItem recentItem;
  final GiftFeedItem feedItem;
  final int roomTotalJeton;
  final int? remainingBalance;

  @override
  List<Object?> get props => [
        event.id,
        recentItem,
        feedItem,
        roomTotalJeton,
        remainingBalance,
      ];
}

/// Tek oturum hediye state — Gift Engine kuyruk + feed.
class GiftSessionState extends Equatable {
  const GiftSessionState({
    this.recentGifts = const [],
    this.animationQueue = const [],
    this.activeAnimation,
    this.feedItems = const [],
    this.roomTotalJeton = 0,
    this.remainingBalance,
    this.processedEventIds = const {},
    this.latestEvent,
  });

  final List<GiftRecentItem> recentGifts;
  final List<LiveGiftEvent> animationQueue;
  final LiveGiftEvent? activeAnimation;
  final List<GiftFeedItem> feedItems;
  final int roomTotalJeton;
  final int? remainingBalance;
  final Set<String> processedEventIds;
  final LiveGiftEvent? latestEvent;

  GiftSessionState copyWith({
    List<GiftRecentItem>? recentGifts,
    List<LiveGiftEvent>? animationQueue,
    LiveGiftEvent? activeAnimation,
    bool clearActiveAnimation = false,
    List<GiftFeedItem>? feedItems,
    int? roomTotalJeton,
    int? remainingBalance,
    bool clearRemainingBalance = false,
    Set<String>? processedEventIds,
    LiveGiftEvent? latestEvent,
    bool clearLatestEvent = false,
  }) {
    return GiftSessionState(
      recentGifts: recentGifts ?? this.recentGifts,
      animationQueue: animationQueue ?? this.animationQueue,
      activeAnimation:
          clearActiveAnimation ? null : (activeAnimation ?? this.activeAnimation),
      feedItems: feedItems ?? this.feedItems,
      roomTotalJeton: roomTotalJeton ?? this.roomTotalJeton,
      remainingBalance: clearRemainingBalance
          ? null
          : (remainingBalance ?? this.remainingBalance),
      processedEventIds: processedEventIds ?? this.processedEventIds,
      latestEvent: clearLatestEvent ? null : (latestEvent ?? this.latestEvent),
    );
  }

  @override
  List<Object?> get props => [
        recentGifts,
        animationQueue,
        activeAnimation,
        feedItems,
        roomTotalJeton,
        remainingBalance,
        processedEventIds,
        latestEvent,
      ];
}
