import 'package:equatable/equatable.dart';

import '../../../live/domain/entities/live_gift_event.dart';

/// Son hediyeler kutusu — combo ile (❤️ x1 → x2 → x3).
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

  GiftRecentItem bumpCombo(int addJeton) => GiftRecentItem(
        id: id,
        senderId: senderId,
        senderName: senderName,
        receiverName: receiverName,
        giftId: giftId,
        giftName: giftName,
        jetonAmount: jetonAmount + addJeton,
        combo: combo + 1,
        at: DateTime.now(),
        iconUrl: iconUrl,
        seatIndex: seatIndex,
      );

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

/// Tek oturum hediye state — host/guest/moderatör aynı kaynak.
class GiftSessionState extends Equatable {
  const GiftSessionState({
    this.recentGifts = const [],
    this.animationQueue = const [],
    this.activeAnimation,
    this.activeFullscreen,
    this.roomTotalJeton = 0,
    this.remainingBalance,
    this.processedEventIds = const {},
    this.latestEvent,
  });

  final List<GiftRecentItem> recentGifts;
  final List<LiveGiftEvent> animationQueue;
  final LiveGiftEvent? activeAnimation;
  final LiveGiftEvent? activeFullscreen;
  final int roomTotalJeton;
  final int? remainingBalance;
  final Set<String> processedEventIds;
  final LiveGiftEvent? latestEvent;

  GiftSessionState copyWith({
    List<GiftRecentItem>? recentGifts,
    List<LiveGiftEvent>? animationQueue,
    LiveGiftEvent? activeAnimation,
    bool clearActiveAnimation = false,
    LiveGiftEvent? activeFullscreen,
    bool clearActiveFullscreen = false,
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
      activeFullscreen: clearActiveFullscreen
          ? null
          : (activeFullscreen ?? this.activeFullscreen),
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
        activeFullscreen,
        roomTotalJeton,
        remainingBalance,
        processedEventIds,
        latestEvent,
      ];
}
