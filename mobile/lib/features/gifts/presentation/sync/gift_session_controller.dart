import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_revenue_display.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../../domain/gift_animation_policy.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_event_catalog_enricher.dart';
import '../../domain/gift_render_meta.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import 'gift_hourly_reset.dart';
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
  Timer? _fullscreenTimer;
  void Function()? _cancelHourlyReset;
  late String _roomId;
  int? _joinTimestampMs;

  @override
  GiftSessionState build(String roomId) {
    _roomId = roomId;
    _joinTimestampMs = DateTime.now().millisecondsSinceEpoch;
    ref.onDispose(_disposeTimers);
    GiftHourlyReset.scheduleRepeating(
      _resetHourlyTotals,
      onCancel: (cancel) => _cancelHourlyReset = cancel,
    );
    return const GiftSessionState();
  }

  void _resetHourlyTotals() {
    _comboKeys.clear();
    for (final t in _recentExpiryTimers.values) {
      t.cancel();
    }
    _recentExpiryTimers.clear();
    state = state.copyWith(
      recentGifts: const [],
      animationQueue: const [],
      roomTotalJeton: 0,
      clearActiveAnimation: true,
      clearActiveFullscreen: true,
    );
  }

  void _disposeTimers() {
    _cancelHourlyReset?.call();
    for (final t in _recentExpiryTimers.values) {
      t.cancel();
    }
    _recentExpiryTimers.clear();
    _animationTimer?.cancel();
    _fullscreenTimer?.cancel();
  }

  /// Tüm roller aynı yolu kullanır — host/guest ayrımı yok.
  void onGiftSent(
    LiveGiftEvent raw, {
    required String source,
    String? userRole,
    bool isHost = false,
  }) {
    _onGiftSentImpl(
      raw,
      source: source,
      userRole: userRole,
      isHost: isHost,
      stageOverlayOnly: false,
    );
  }

  /// Sesli oda — ağır tam ekran katmanı yerine yalnızca sahne bandı.
  void onVoiceGiftSent(
    LiveGiftEvent raw, {
    required String source,
    String? userRole,
    bool isHost = false,
  }) {
    _onGiftSentImpl(
      raw,
      source: source,
      userRole: userRole,
      isHost: isHost,
      stageOverlayOnly: true,
    );
  }

  void _onGiftSentImpl(
    LiveGiftEvent raw, {
    required String source,
    String? userRole,
    bool isHost = false,
    required bool stageOverlayOnly,
  }) {
    final roomId = _roomId;
    if (!_isDisplayable(raw)) {
      GiftSyncLog.dedupeSkipped(roomId, raw.id, 'not_displayable');
      return;
    }

    if (raw.id.startsWith('local-')) {
      GiftSyncLog.dedupeSkipped(roomId, raw.id, 'local_blocked');
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

    final sseOnly = source == 'sse';
    final joinedMs = _joinTimestampMs;
    final beforeJoin = joinedMs != null &&
        event.eventTimestampMs > 0 &&
        event.eventTimestampMs < joinedMs;
    final animate = sseOnly && !beforeJoin;

    state = state.copyWith(
      recentGifts: recent,
      roomTotalJeton: roomTotal,
      remainingBalance: event.remainingBalance ?? state.remainingBalance,
      processedEventIds: ids,
      latestEvent: event,
    );

    if (!animate) {
      if (beforeJoin) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'before_join');
      } else if (!sseOnly) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'non_sse_source');
      }
      GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
      return;
    }

    final showFs = GiftRenderMeta.isFullscreenLayer(event, catalog) ||
        (!stageOverlayOnly && _shouldFullscreen(event, jeton, catalog));

    state = state.copyWith(
      activeFullscreen: showFs ? event : state.activeFullscreen,
    );

    if (showFs) {
      final duration = GiftRenderMeta.displayDuration(event, catalog);
      _fullscreenTimer?.cancel();
      _fullscreenTimer = Timer(duration, () {
        if (state.activeFullscreen?.id == event.id) {
          state = state.copyWith(clearActiveFullscreen: true);
        }
      });
    } else if (GiftRenderMeta.isStageBandLayer(event, catalog) ||
        !stageOverlayOnly) {
      _enqueueAnimation(event, catalog);
    }

    GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
    GiftSyncLog.uiRender(roomId, 'recent+animation+${showFs ? 'fullscreen' : 'flight'}');
  }

  void clear() {
    _disposeTimers();
    _comboKeys.clear();
    _joinTimestampMs = null;
    state = const GiftSessionState();
  }

  void dequeueAnimation(String eventId) {
    final clearingActive = state.activeAnimation?.id == eventId;
    final filteredQueue =
        state.animationQueue.where((e) => e.id != eventId).toList();
    if (!clearingActive && filteredQueue.length == state.animationQueue.length) {
      return;
    }
    state = state.copyWith(
      clearActiveAnimation: clearingActive,
      animationQueue: filteredQueue,
    );
    if (clearingActive) {
      _pumpAnimationQueue();
    }
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
      giftIcon: raw.giftIcon,
      assetUrl: raw.assetUrl,
      assetType: raw.assetType,
      displayType: raw.displayType,
      isFullscreen: raw.isFullscreen,
      visibleAsFullscreen: raw.visibleAsFullscreen,
      screenPosition: raw.screenPosition,
      displayDurationMs: raw.displayDurationMs,
      tier: raw.tier,
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

  void _enqueueAnimation(LiveGiftEvent event, GiftEntity? catalog) {
    state = state.copyWith(
      animationQueue: [...state.animationQueue, event],
    );
    _pumpAnimationQueue(catalog);
  }

  GiftEntity? _catalogFor(String giftId) =>
      lookupGiftCatalog(ref.read(allGiftCatalogByIdProvider), giftId);

  void _pumpAnimationQueue([GiftEntity? catalogHint]) {
    if (state.activeAnimation != null) return;
    if (state.animationQueue.isEmpty) return;

    final next = state.animationQueue.first;
    final catalog = catalogHint ?? _catalogFor(next.giftId);
    final rest = state.animationQueue.length > 1
        ? state.animationQueue.sublist(1)
        : <LiveGiftEvent>[];

    state = state.copyWith(activeAnimation: next, animationQueue: rest);

    _animationTimer?.cancel();
    final duration = GiftAnimationPolicy.queueDuration(
      jetonPrice: next.jetonAmount,
      animationDurationMs: catalog?.animationDurationMs,
    );
    _animationTimer = Timer(duration + GiftAnimationPolicy.queueGapDuration, () {
      if (state.activeAnimation?.id == next.id) {
        state = state.copyWith(clearActiveAnimation: true);
      }
      _pumpAnimationQueue();
    });
  }

  bool _shouldFullscreen(
    LiveGiftEvent event,
    int jeton,
    GiftEntity? catalog,
  ) {
    if (GiftAnimationPolicy.shouldFullscreen(
      catalog: catalog,
      jetonPrice: jeton,
      displayType: catalog?.displayType,
      hasNetworkAnimation: (event.animationKey ?? '').startsWith('http'),
    )) {
      return true;
    }
    if (PremiumGiftCatalog2026.triggersFullscreen(
      giftId: event.giftId,
      coinCost: jeton,
    )) {
      return true;
    }
    return false;
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
