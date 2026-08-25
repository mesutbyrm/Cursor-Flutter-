import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/fx_dedupe_store.dart';
import '../../domain/fx_gift_display_item.dart';
import '../../domain/fx_gift_tier.dart';

class VoiceRoomGiftDisplayState {
  const VoiceRoomGiftDisplayState({
    this.recentQueue = const [],
    this.activeRecent,
    this.bigGift,
    this.bigGiftVisible = false,
    this.joinedAtMs,
  });

  final List<FxGiftDisplayItem> recentQueue;
  final FxGiftDisplayItem? activeRecent;
  final FxGiftDisplayItem? bigGift;
  final bool bigGiftVisible;
  final int? joinedAtMs;

  VoiceRoomGiftDisplayState copyWith({
    List<FxGiftDisplayItem>? recentQueue,
    FxGiftDisplayItem? activeRecent,
    bool clearActiveRecent = false,
    FxGiftDisplayItem? bigGift,
    bool clearBigGift = false,
    bool? bigGiftVisible,
    int? joinedAtMs,
  }) {
    return VoiceRoomGiftDisplayState(
      recentQueue: recentQueue ?? this.recentQueue,
      activeRecent:
          clearActiveRecent ? null : (activeRecent ?? this.activeRecent),
      bigGift: clearBigGift ? null : (bigGift ?? this.bigGift),
      bigGiftVisible: bigGiftVisible ?? this.bigGiftVisible,
      joinedAtMs: joinedAtMs ?? this.joinedAtMs,
    );
  }
}

/// Sesli oda hediye gösterimi — son 3 kuyruk + 1000+ banner.
class VoiceRoomGiftDisplayController extends Notifier<VoiceRoomGiftDisplayState> {
  static const maxRecent = 3;
  static const recentDisplayMs = 3000;
  static const bigGiftDisplayMs = 4500;

  final _dedupe = FxDedupeStore();
  Timer? _recentRotateTimer;
  Timer? _bigGiftHideTimer;
  var _recentIndex = 0;

  @override
  VoiceRoomGiftDisplayState build() {
    ref.onDispose(_disposeTimers);
    return VoiceRoomGiftDisplayState(
      joinedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void resetForRoomChange() {
    _disposeTimers();
    _dedupe.clear();
    _recentIndex = 0;
    state = VoiceRoomGiftDisplayState(
      joinedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void onGiftEvent(LiveGiftEvent event, {bool fromReconnectBootstrap = false}) {
    final item = FxGiftDisplayItem.fromLiveGift(event);
    if (item.jeton <= 0) return;

    if (!_dedupe.markIfNew(item.eventId)) return;

    // Reconnect bootstrap: sadece state güncelle, animasyon oynatma.
    if (fromReconnectBootstrap) return;

    _enqueueRecent(item);

    if (FxGiftTier.fromJeton(item.jeton).isBigGift) {
      _showBigGift(item);
    }
  }

  void _enqueueRecent(FxGiftDisplayItem item) {
    final queue = [...state.recentQueue, item];
    while (queue.length > maxRecent) {
      queue.removeAt(0);
    }
    _recentIndex = queue.length - 1;
    state = state.copyWith(
      recentQueue: queue,
      activeRecent: queue.isEmpty ? null : queue[_recentIndex],
    );
    _scheduleRecentRotation();
  }

  void _scheduleRecentRotation() {
    _recentRotateTimer?.cancel();
    final queue = state.recentQueue;
    if (queue.isEmpty) return;
    _recentRotateTimer = Timer(
      const Duration(milliseconds: recentDisplayMs),
      () {
        if (state.recentQueue.isEmpty) return;
        _recentIndex = (_recentIndex + 1) % state.recentQueue.length;
        state = state.copyWith(activeRecent: state.recentQueue[_recentIndex]);
        _scheduleRecentRotation();
      },
    );
  }

  void _showBigGift(FxGiftDisplayItem item) {
    _bigGiftHideTimer?.cancel();
    state = state.copyWith(bigGift: item, bigGiftVisible: true);
    _bigGiftHideTimer = Timer(
      const Duration(milliseconds: bigGiftDisplayMs),
      () {
        state = state.copyWith(bigGiftVisible: false);
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (!state.bigGiftVisible) {
            state = state.copyWith(clearBigGift: true);
          }
        });
      },
    );
  }

  void _disposeTimers() {
    _recentRotateTimer?.cancel();
    _bigGiftHideTimer?.cancel();
  }
}

final voiceRoomGiftDisplayProvider =
    NotifierProvider<VoiceRoomGiftDisplayController, VoiceRoomGiftDisplayState>(
  VoiceRoomGiftDisplayController.new,
);
