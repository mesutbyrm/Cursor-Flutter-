import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../../voice_hub/presentation/providers/voice_gift_providers.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
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
    ref.read(giftSessionProvider(widget.sessionKey).notifier).onGiftSent(
          event,
          source: widget.useLiveRealtime ? 'live_realtime' : 'voice_realtime',
          userRole: widget.userRole,
          isHost: widget.isHost,
        );
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
