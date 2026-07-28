import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_revenue_display.dart';
import '../engine/gift_engine_preloader.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../../domain/gift_event_catalog_enricher.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../engine/voice_gift_ambient_overlay.dart';
import 'gift_hourly_reset.dart';
import 'gift_session_state.dart';
import 'gift_sync_log.dart';

/// Gift Engine oturum kontrolcüsü — tek FIFO kuyruk, backend render.
class GiftSessionController extends AutoDisposeFamilyNotifier<GiftSessionState, String> {
  static const _maxRecent = 5;
  static const _maxProcessedIds = 256;
  static const _joinGraceMs = 15000;

  final _feedExpiryTimers = <String, Timer>{};
  Timer? _animationTimer;
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
    for (final t in _feedExpiryTimers.values) {
      t.cancel();
    }
    _feedExpiryTimers.clear();
    state = state.copyWith(
      recentGifts: const [],
      animationQueue: const [],
      feedItems: const [],
      roomTotalJeton: 0,
      clearActiveAnimation: true,
    );
  }

  void _disposeTimers() {
    _cancelHourlyReset?.call();
    for (final t in _feedExpiryTimers.values) {
      t.cancel();
    }
    _feedExpiryTimers.clear();
    _animationTimer?.cancel();
  }

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
    );
  }

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
    );
  }

  void _onGiftSentImpl(
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
    final event = enrichGiftEventFromCatalog(raw, catalog);
    final ids = {...state.processedEventIds, event.id};
    if (ids.length > _maxProcessedIds) {
      ids.remove(ids.first);
    }

    final recent = _appendRecent(event);
    final jeton = event.jetonAmount;
    final roomTotal = state.roomTotalJeton + jeton;

    final sseOnly = source == 'sse' || source == 'live_realtime';
    final joinedMs = _joinTimestampMs;
    final beforeJoin = joinedMs != null &&
        event.eventTimestampMs > 0 &&
        event.eventTimestampMs < joinedMs - _joinGraceMs;
    final animate = sseOnly && !beforeJoin;

    state = state.copyWith(
      recentGifts: recent,
      roomTotalJeton: roomTotal,
      remainingBalance: event.remainingBalance ?? state.remainingBalance,
      processedEventIds: ids,
      latestEvent: event,
    );

    _addFeedItem(event);

    if (!animate) {
      if (beforeJoin) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'before_join');
      } else if (!sseOnly) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'non_sse_source');
      }
      GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
      return;
    }

    unawaited(GiftEnginePreloader.prefetch(event));
    _enqueueAnimation(event);

    GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
    GiftSyncLog.uiRender(roomId, 'gift_engine_queue');
  }

  void clear() {
    _disposeTimers();
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
    _animationTimer?.cancel();
    state = state.copyWith(
      clearActiveAnimation: clearingActive,
      animationQueue: filteredQueue,
    );
    if (clearingActive) {
      _pumpAnimationQueue();
    }
  }

  List<GiftRecentItem> _appendRecent(LiveGiftEvent event) {
    final senderId = (event.senderId ?? event.senderName).trim();
    final item = GiftRecentItem(
      id: 'recent-${event.id}',
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
      at: DateTime.now(),
      iconUrl: event.displayImageUrl,
      seatIndex: event.seatIndex,
    );
    final merged = [item, ...state.recentGifts]
        .take(_maxRecent)
        .toList(growable: false);
    return merged;
  }

  void _addFeedItem(LiveGiftEvent event) {
    final config = GiftEngineParser.fromEvent(event);
    final item = GiftFeedItem(
      id: 'feed-${event.id}',
      senderName: event.senderName.trim().isNotEmpty
          ? event.senderName.trim()
          : 'Biri',
      giftName: event.giftName.trim().isNotEmpty
          ? event.giftName.trim()
          : 'Hediye',
      jetonAmount: event.jetonAmount,
      combo: config.combo,
      expiresAt: DateTime.now().add(
        Duration(milliseconds: config.feedDurationMs),
      ),
      iconUrl: event.displayImageUrl,
      giftIcon: event.giftIcon,
    );

    final items = [item, ...state.feedItems].take(6).toList();
    state = state.copyWith(feedItems: items);

    _feedExpiryTimers[item.id]?.cancel();
    _feedExpiryTimers[item.id] = Timer(
      Duration(milliseconds: config.feedDurationMs),
      () {
        _feedExpiryTimers.remove(item.id);
        state = state.copyWith(
          feedItems: state.feedItems.where((f) => f.id != item.id).toList(),
        );
      },
    );
  }

  void _enqueueAnimation(LiveGiftEvent event) {
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

    final config = GiftEngineParser.fromEvent(next);
    final watchdogMs = config.startDelayMs +
        config.durationMs +
        config.queueGapMs +
        VoiceGiftAmbientOverlay.fadeInMs +
        VoiceGiftAmbientOverlay.fadeOutMs +
        5000;

    _animationTimer?.cancel();
    _animationTimer = Timer(Duration(milliseconds: watchdogMs), () {
      if (state.activeAnimation?.id == next.id) {
        dequeueAnimation(next.id);
      }
    });
  }

  bool _isDisplayable(LiveGiftEvent e) {
    bool ok(String s) => s.trim().isNotEmpty && !s.startsWith('{');
    return ok(e.giftName) || e.giftId.isNotEmpty;
  }

  int broadcasterNetDelta(LiveGiftEvent event) =>
      GiftRevenueDisplay.liveBroadcasterNet(event.jetonAmount);
}

final giftSessionProvider = NotifierProvider.autoDispose
    .family<GiftSessionController, GiftSessionState, String>(
  GiftSessionController.new,
);
