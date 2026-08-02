import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_engine_models.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_revenue_display.dart';
import '../engine/gift_engine_preloader.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../providers/gift_providers.dart';
import '../../domain/gift_event_catalog_enricher.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../engine/voice_gift_ambient_overlay.dart';
import 'gift_hourly_reset.dart';
import 'gift_session_state.dart';
import 'gift_sync_log.dart';

/// Gift Engine oturum kontrolcüsü — ses → animasyon → jeton sırası.
class GiftSessionController extends AutoDisposeFamilyNotifier<GiftSessionState, String> {
  static const _maxRecent = 8;
  static const _maxProcessedIds = 512;
  static const _joinGraceMs = 15000;

  final _feedExpiryTimers = <String, Timer>{};
  final _receivedAtMs = <String, int>{};
  Timer? _animationTimer;
  void Function()? _cancelHourlyReset;
  var _pumping = false;
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
    _receivedAtMs.clear();
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
    _receivedAtMs.clear();
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

    final receivedMs = DateTime.now().millisecondsSinceEpoch;
    _receivedAtMs[raw.id] = receivedMs;

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

    const animatedSources = {
      'sse',
      'live_realtime',
      'voice_realtime',
      'voice_announce',
    };
    final canAnimate = animatedSources.contains(source);
    final joinedMs = _joinTimestampMs;
    final beforeJoin = joinedMs != null &&
        event.eventTimestampMs > 0 &&
        event.eventTimestampMs < joinedMs - _joinGraceMs;
    final animate = canAnimate && !beforeJoin;

    final jeton = event.jetonAmount;
    final roomTotal = state.roomTotalJeton + jeton;
    final recentItem = _buildRecentItem(event);
    final feedItem = _buildFeedItem(event);

    if (!animate) {
      state = state.copyWith(
        recentGifts: _prependRecent(recentItem),
        roomTotalJeton: roomTotal,
        remainingBalance: event.remainingBalance ?? state.remainingBalance,
        processedEventIds: ids,
        latestEvent: event,
      );
      _applyFeedItem(feedItem, event);
      if (!beforeJoin) {
        _playGiftSound(event, catalog);
      }
      if (beforeJoin) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'before_join');
      } else if (!canAnimate) {
        GiftSyncLog.dedupeSkipped(roomId, event.id, 'non_animated_source');
      }
      GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
      return;
    }

    // Feed / jeton anında — animasyon kuyruğu ayrı (yüzlerce hediye kaybolmaz).
    state = state.copyWith(
      recentGifts: _prependRecent(recentItem),
      roomTotalJeton: roomTotal,
      remainingBalance: event.remainingBalance ?? state.remainingBalance,
      processedEventIds: ids,
      latestEvent: event,
    );
    _applyFeedItem(feedItem, event);

    _enqueueAnimation(event);
    GiftSyncLog.eventProcessed(roomId, event.id, combo: event.combo);
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
    _receivedAtMs.remove(eventId);
    state = state.copyWith(
      clearActiveAnimation: clearingActive,
      animationQueue: filteredQueue,
    );
    if (clearingActive) {
      GiftSyncLog.videoEnded(_roomId, eventId);
      _pumpAnimationQueue();
    }
  }

  GiftRecentItem _buildRecentItem(LiveGiftEvent event) {
    final senderId = (event.senderId ?? event.senderName).trim();
    return GiftRecentItem(
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
  }

  List<GiftRecentItem> _prependRecent(GiftRecentItem item) {
    return [item, ...state.recentGifts].take(_maxRecent).toList(growable: false);
  }

  GiftFeedItem _buildFeedItem(LiveGiftEvent event) {
    final config = GiftEngineParser.fromEvent(event);
    return GiftFeedItem(
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
  }

  void _applyFeedItem(GiftFeedItem item, LiveGiftEvent event) {
    final items = [item, ...state.feedItems].take(6).toList();
    state = state.copyWith(feedItems: items);

    _feedExpiryTimers[item.id]?.cancel();
    _feedExpiryTimers[item.id] = Timer(
      Duration(
        milliseconds: GiftEngineParser.fromEvent(event).feedDurationMs,
      ),
      () {
        _feedExpiryTimers.remove(item.id);
        state = state.copyWith(
          feedItems: state.feedItems.where((f) => f.id != item.id).toList(),
        );
      },
    );
  }

  void _playGiftSound(LiveGiftEvent event, GiftEntity? catalog) {
    if (catalog != null) {
      unawaited(ref.read(giftSoundPoolProvider).preloadGift(catalog));
    }
    unawaited(
      ref.read(giftSoundPoolProvider).playForEvent(event, catalog: catalog),
    );
  }

  void _enqueueAnimation(LiveGiftEvent event) {
    state = state.copyWith(
      animationQueue: [...state.animationQueue, event],
    );
    _pumpAnimationQueue();
  }

  void _pumpAnimationQueue() {
    if (_pumping || state.activeAnimation != null) return;
    if (state.animationQueue.isEmpty) return;
    unawaited(_pumpAnimationQueueAsync());
  }

  Future<void> _pumpAnimationQueueAsync() async {
    if (_pumping || state.activeAnimation != null) return;
    if (state.animationQueue.isEmpty) return;

    _pumping = true;
    final next = state.animationQueue.first;

    try {
      final catalog = lookupGiftCatalog(
        ref.read(allGiftCatalogByIdProvider),
        next.giftId,
      );
      final receivedMs = _receivedAtMs[next.id] ?? DateTime.now().millisecondsSinceEpoch;

      GiftSyncLog.pipelineStage(next.id, 'prefetch');
      final tPrefetch = DateTime.now();
      final backlog = state.animationQueue.length;
      try {
        await GiftEnginePreloader.prefetch(next).timeout(
          Duration(
            milliseconds: backlog > 4
                ? 1800
                : (GiftEngineParser.fromEvent(next).animationType ==
                        GiftEngineAnimationType.mp4 ||
                    GiftEngineParser.fromEvent(next).animationType ==
                        GiftEngineAnimationType.webm
                    ? 2500
                    : 900),
          ),
        );
      } catch (_) {}
      GiftSyncLog.pipelineMs(
        next.id,
        'prefetch',
        DateTime.now().difference(tPrefetch).inMilliseconds,
      );

      if (catalog != null) {
        unawaited(ref.read(giftSoundPoolProvider).preloadGift(catalog));
      }

      GiftSyncLog.pipelineStage(next.id, 'sound');
      final tSound = DateTime.now();
      _playGiftSound(next, catalog);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      GiftSyncLog.pipelineMs(
        next.id,
        'sound',
        DateTime.now().difference(tSound).inMilliseconds,
      );

      final rest = state.animationQueue.length > 1
          ? state.animationQueue.sublist(1)
          : <LiveGiftEvent>[];
      state = state.copyWith(activeAnimation: next, animationQueue: rest);

      final totalMs = DateTime.now().millisecondsSinceEpoch - receivedMs;
      GiftSyncLog.pipelineTotal(next.id, totalMs);
      GiftSyncLog.uiRender(_roomId, 'gift_engine_queue');
      GiftSyncLog.videoStarted(_roomId, next.id);

      final config = GiftEngineParser.fromEvent(next);
      var durationMs = config.durationMs;
      if (config.animationType == GiftEngineAnimationType.mp4 ||
          config.animationType == GiftEngineAnimationType.webm) {
        durationMs = durationMs < 8000 ? 12000 : durationMs;
      }
      final watchdogMs = config.startDelayMs +
          durationMs +
          config.queueGapMs +
          VoiceGiftAmbientOverlay.fadeInMs +
          VoiceGiftAmbientOverlay.fadeOutMs +
          12000;

      _animationTimer?.cancel();
      _animationTimer = Timer(Duration(milliseconds: watchdogMs), () {
        if (state.activeAnimation?.id == next.id) {
          dequeueAnimation(next.id);
        }
      });
    } finally {
      _pumping = false;
      if (state.activeAnimation == null && state.animationQueue.isNotEmpty) {
        _pumpAnimationQueue();
      }
    }
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
