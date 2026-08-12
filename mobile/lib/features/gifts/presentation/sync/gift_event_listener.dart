import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../../live/presentation/providers/live_room_providers.dart';
import '../../../voice_hub/presentation/providers/voice_gift_providers.dart';
import '../../../voice_hub/presentation/providers/voice_recent_gifts_provider.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';
import '../../../voice_hub/presentation/providers/voice_room_provider.dart';
import '../../../voice_hub/presentation/providers/voice_gift_combo_tracker.dart';
import '../../../voice_hub/presentation/providers/voice_gift_leaderboard_provider.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../global/global_gift_event_bridge.dart';
import 'gift_session_controller.dart';
import 'gift_sync_log.dart';

/// Tek ortak hediye dinleyici — host/guest/admin aynı event yolunu kullanır.
class GiftEventListener extends ConsumerStatefulWidget {
  const GiftEventListener({
    super.key,
    required this.sessionKey,
    required this.child,
    this.isHost = false,
    this.userRole,
    this.useVoiceRealtime = true,
    this.useLiveRealtime = false,
    this.liveStreamId,
  });

  final String sessionKey;
  final Widget child;
  final bool isHost;
  final String? userRole;
  final bool useVoiceRealtime;
  final bool useLiveRealtime;
  final String? liveStreamId;

  @override
  ConsumerState<GiftEventListener> createState() => _GiftEventListenerState();
}

class _GiftEventListenerState extends ConsumerState<GiftEventListener> {
  StreamSubscription<LiveGiftEvent>? _voiceSub;
  StreamSubscription<LiveGiftEvent>? _liveSub;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant GiftEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionKey != widget.sessionKey ||
        oldWidget.useVoiceRealtime != widget.useVoiceRealtime ||
        oldWidget.useLiveRealtime != widget.useLiveRealtime) {
      _rebind();
    }
  }

  void _bind() {
    GiftSyncLog.broadcast(widget.sessionKey, 'bind', widget.sessionKey);
    if (widget.useVoiceRealtime) {
      final service = ref.read(voiceRoomGiftRealtimeProvider);
      _voiceSub?.cancel();
      _voiceSub = service.events.listen(_onEvent);
    }
    if (widget.useLiveRealtime && widget.liveStreamId != null) {
      // Live realtime bağlantısı sayfa tarafından başlatılır; burada yalnızca dinle.
      final liveSvc = ref.read(liveGiftRealtimeProvider);
      _liveSub?.cancel();
      _liveSub = liveSvc.events.listen(_onEvent);
    }
  }

  void _rebind() {
    _voiceSub?.cancel();
    _liveSub?.cancel();
    _bind();
  }

  void _onEvent(LiveGiftEvent event) {
    if (!mounted) return;
    scheduleMicrotask(() {
      if (!mounted) return;
      final enriched = widget.useVoiceRealtime
          ? ref.read(voiceGiftComboTrackerProvider.notifier).enrich(event)
          : event;
      if (widget.useVoiceRealtime) {
        ref
            .read(voiceSessionGiftLeaderboardProvider.notifier)
            .record(enriched);
        enqueueGlobalGiftFromLiveEvent(ref, enriched);
      } else {
        enqueueGlobalGiftFromLiveEvent(ref, event);
      }
      final notifier =
          ref.read(giftSessionProvider(widget.sessionKey).notifier);
      if (widget.useVoiceRealtime) {
        notifier.onVoiceGiftSent(
          enriched,
          source: 'voice_realtime',
          userRole: widget.userRole,
          isHost: widget.isHost,
        );
      } else {
        notifier.onGiftSent(
          enriched,
          source: 'live_realtime',
          userRole: widget.userRole,
          isHost: widget.isHost,
        );
      }
      ref.read(voiceRecentGiftsProvider.notifier).record(enriched);
      if (widget.useVoiceRealtime && enriched.jetonAmount >= 1000) {
        ref.read(staffEntranceMarqueeProvider.notifier).enqueueBigGift(
              senderName: enriched.senderName,
              receiverName: enriched.receiverName,
              jeton: enriched.jetonAmount,
              giftName: enriched.giftName,
            );
      }
      if (widget.useVoiceRealtime && widget.sessionKey.isNotEmpty) {
        ref
            .read(voiceRoomLiveProvider(widget.sessionKey).notifier)
            .appendGiftChatMessage(enriched);
      }
      if (widget.useLiveRealtime && widget.liveStreamId != null) {
        ref
            .read(liveRoomProvider(widget.liveStreamId!).notifier)
            .appendGiftSystemMessage(event);
      }
    });
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _liveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
