import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_revenue_display.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../../domain/gift_event_catalog_enricher.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import 'gift_session_state.dart';
import 'gift_sync_log.dart';

/// Oturum hediye state — tek kaynak (SSE/socket/poll → buraya).
class GiftSessionController extends AutoDisposeFamilyNotifier<GiftSessionState, String> {
  static const _recentTtl = Duration(seconds: 5);
  static const _maxRecent = 5;
  static const _comboWindow = Duration(seconds: 5);
  static const _maxProcessedIds = 256;

  final _recentExpiryTimers = <String, Timer>{};
  final _comboKeys = <String, GiftRecentItem>{};
  Timer? _animationTimer;
  late String _roomId;

  @override
  GiftSessionState build(String roomId) {
    _roomId = roomId;
    ref.onDispose(_disposeTimers);
    return const GiftSessionState();
  }

  void _disposeTimers() {
    for (final t in _recentExpiryTimers.values) {
      t.cancel();
    }
    _recentExpiryTimers.clear();
    _animationTimer?.cancel();
  }

  /// Tüm roller aynı yolu kullanır — host/guest ayrımı yok.
  void onGiftSent(
    LiveGiftEvent raw, {
    required String source,
    String? userRole,
    bool isHost = false,
  }) {
    final roomId = _roomId;
    if (!_isDisplayable(raw)) {
      GiftSyncLog.dedupeSkipped(roomId, raw.id, 'not_displayable');
      return;
    }

    if (state.processedEventIds.contains(raw.id)) {
      GiftSyncLog.dedupeSkipped(roomId, raw.id, 'duplicate_id');
      return;
    }

    GiftSyncLog.eventReceived(
      roomId: roomId,
      source: source,
      role: userRole,
      event: raw,
    );
    if (isHost) {
      GiftSyncLog.hostReceived(roomId, raw.id);
    } else {
      GiftSyncLog.guestReceived(roomId, raw.id);
    }

    final catalog = lookupGiftCatalog(
      ref.read(allGiftCatalogByIdProvider),
      raw.giftId,
    );
    final event = _normalizeCombo(
      enrichGiftEventFromCatalog(raw, catalog),
    );
    final ids = {...state.processedEventIds, event.id};
    if (ids.length > _maxProcessedIds) {
      ids.remove(ids.first);
    }

    final recent = _upsertRecent(event);
    final jeton = event.jetonAmount;
    final roomTotal = state.roomTotalJeton + jeton;

    state = state.copyWith(
      recentGifts: recent,
      roomTotalJeton: roomTotal,
      remainingBalance: event.remainingBalance ?? state.remainingBalance,
      processedEventIds: ids,
      latestEvent: event,
    );

    _enqueueAnimation(event);

    final showFs = _shouldFullscreen(event, jeton);
    if (showFs) {
      state = state.copyWith(activeFullscreen: event);
      final duration = event.rarity.fullscreenDuration;
      Timer(duration, () {
        if (state.activeFullscreen?.id == event.id) {
          state = state.copyWith(clearActiveFullscreen: true);
        }
      });
    }

    GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
    GiftSyncLog.uiRender(roomId, 'recent+animation+${showFs ? 'fullscreen' : 'flight'}');
  }

  void clear() {
    _disposeTimers();
    _comboKeys.clear();
    state = const GiftSessionState();
  }

  void dequeueAnimation(String eventId) {
    if (state.activeAnimation?.id == eventId) {
      state = state.copyWith(clearActiveAnimation: true);
      _pumpAnimationQueue();
    }
    state = state.copyWith(
      animationQueue:
          state.animationQueue.where((e) => e.id != eventId).toList(),
    );
  }

  LiveGiftEvent _normalizeCombo(LiveGiftEvent raw) {
    if (raw.combo > 1) return raw;
    return LiveGiftEvent(
      id: raw.id,
      senderId: raw.senderId,
      receiverId: raw.receiverId,
      senderName: raw.senderName,
      receiverName: raw.receiverName,
      giftId: raw.giftId,
      giftName: raw.giftName,
      quantity: raw.quantity,
      coinCost: raw.coinCost,
      giftPrice: raw.giftPrice,
      totalCoin: raw.totalCoin,
      totalDiamond: raw.totalDiamond,
      combo: 1,
      timestamp: raw.timestamp,
      iconUrl: raw.iconUrl,
      giftImageUrl: raw.giftImageUrl,
      animationKey: raw.animationKey,
      rarity: raw.rarity,
      animationKind: raw.animationKind,
      soundKey: raw.soundKey,
      remainingBalance: raw.remainingBalance,
      seatIndex: raw.seatIndex,
      senderAvatar: raw.senderAvatar,
      receiverAvatar: raw.receiverAvatar,
      giftType: raw.giftType,
    );
  }

  List<GiftRecentItem> _upsertRecent(LiveGiftEvent event) {
    final senderId = (event.senderId ?? event.senderName).trim();
    final comboKey = '$senderId|${event.giftId}';
    final now = DateTime.now();

    GiftRecentItem item;
    final existing = _comboKeys[comboKey];
    if (existing != null &&
        now.difference(existing.at) < _comboWindow) {
      item = existing.bumpCombo(event.jetonAmount);
    } else {
      item = GiftRecentItem(
        id: 'recent-$comboKey-${now.microsecondsSinceEpoch}',
        senderId: senderId,
        senderName: event.senderName.trim().isNotEmpty
            ? event.senderName.trim()
            : 'Biri',
        receiverName: event.receiverName.trim().isNotEmpty
            ? event.receiverName.trim()
            : 'kullanıcı',
        giftId: event.giftId,
        giftName: event.giftName.trim().isNotEmpty
            ? event.giftName.trim()
            : 'hediye',
        jetonAmount: event.jetonAmount,
        combo: event.combo > 1 ? event.combo : 1,
        at: now,
        iconUrl: event.displayImageUrl,
        seatIndex: event.seatIndex,
      );
    }
    _comboKeys[comboKey] = item;

    _recentExpiryTimers[comboKey]?.cancel();
    _recentExpiryTimers[comboKey] = Timer(_recentTtl, () {
      _comboKeys.remove(comboKey);
      _recentExpiryTimers.remove(comboKey);
      state = state.copyWith(
        recentGifts: _comboKeys.values.toList()
          ..sort((a, b) => b.at.compareTo(a.at)),
      );
    });

    final ordered = _comboKeys.values.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return ordered.take(_maxRecent).toList();
  }

  void _enqueueAnimation(LiveGiftEvent event) {
    final showFs = _shouldFullscreen(event, event.jetonAmount);
    if (showFs) return;

    state = state.copyWith(
      animationQueue: [...state.animationQueue, event],
    );
    _pumpAnimationQueue();
  }

  void _pumpAnimationQueue() {
    if (state.activeAnimation != null) return;
    if (state.animationQueue.isEmpty) return;

    final next = state.animationQueue.first;
    final rest = state.animationQueue.length > 1
        ? state.animationQueue.sublist(1)
        : <LiveGiftEvent>[];

    state = state.copyWith(activeAnimation: next, animationQueue: rest);

    _animationTimer?.cancel();
    final duration = const Duration(milliseconds: 2800);
    _animationTimer = Timer(duration, () {
      if (state.activeAnimation?.id == next.id) {
        state = state.copyWith(clearActiveAnimation: true);
      }
      _pumpAnimationQueue();
    });
  }

  bool _shouldFullscreen(LiveGiftEvent event, int jeton) {
    if (PremiumGiftCatalog2026.triggersFullscreen(
      giftId: event.giftId,
      coinCost: jeton,
    )) {
      return true;
    }
    final anim = (event.animationKey ?? '').toLowerCase();
    if (anim.startsWith('http') &&
        (anim.contains('.mp4') ||
            anim.contains('.webm') ||
            anim.contains('.gif') ||
            anim.contains('.json') ||
            anim.contains('.svga'))) {
      return true;
    }
    return jeton >= 100;
  }

  bool _isDisplayable(LiveGiftEvent e) {
    bool ok(String s) => s.trim().isNotEmpty && !s.startsWith('{');
    return ok(e.giftName) || e.giftId.isNotEmpty;
  }

  /// Yayıncı net kazancı (canlı yayın özetleri için).
  int broadcasterNetDelta(LiveGiftEvent event) =>
      GiftRevenueDisplay.liveBroadcasterNet(event.jetonAmount);
}

final giftSessionProvider = NotifierProvider.autoDispose
    .family<GiftSessionController, GiftSessionState, String>(
  GiftSessionController.new,
);
