import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/sync/gift_session_state.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Pane hediye bildirimi — gift session (gerçek realtime + API).
class LivePkPaneGiftToast extends ConsumerStatefulWidget {
  const LivePkPaneGiftToast({
    super.key,
    required this.sessionKey,
    required this.hostUserId,
    required this.hostLabel,
  });

  final String sessionKey;
  final String? hostUserId;
  final String hostLabel;

  /// Bildirim bu süre sonra kaybolur (kalıcı kalmaz).
  static const displaySeconds = 5;

  @override
  ConsumerState<LivePkPaneGiftToast> createState() =>
      _LivePkPaneGiftToastState();
}

class _LivePkPaneGiftToastState extends ConsumerState<LivePkPaneGiftToast> {
  Timer? _tick;

  String get sessionKey => widget.sessionKey;
  String? get hostUserId => widget.hostUserId;
  String get hostLabel => widget.hostLabel;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // Cihaz/sunucu saat farkından bağımsız: ilk görüldüğü andan itibaren sayılır.
  final _seen = <String, DateTime>{};

  bool _fresh(LiveGiftEvent e) {
    final first = _seen.putIfAbsent(e.id, DateTime.now);
    return DateTime.now().difference(first).inSeconds <
        LivePkPaneGiftToast.displaySeconds;
  }

  @override
  Widget build(BuildContext context) {
    if (sessionKey.isEmpty) return const SizedBox.shrink();

    final latest = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.latestEvent),
    );
    final recent = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.recentGifts),
    );

    final events = <LiveGiftEvent>[];
    if (latest != null && _targetsHost(latest) && _fresh(latest)) {
      events.add(latest);
    }
    for (final r in recent.take(4)) {
      if (events.any((e) => e.id == r.id)) continue;
      final ev = _eventFromRecent(r);
      if (_targetsHost(ev) && _fresh(ev)) events.add(ev);
    }
    if (events.isEmpty) return const SizedBox.shrink();

    final tail = events.length > 2 ? events.sublist(0, 2) : events;

    // Üstteki düğme/çip satırlarının ALTINDA, panelin sol-ortasında göster.
    return Align(
      alignment: const Alignment(-1, -0.1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in tail)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _GiftLine(event: e),
              ),
          ],
        ),
      ),
    );
  }

  bool _targetsHost(LiveGiftEvent e) {
    final uid = hostUserId?.trim() ?? '';
    if (uid.isNotEmpty && e.receiverId?.trim() == uid) return true;
    final label = hostLabel.trim().toLowerCase();
    final recv = e.receiverName.trim().toLowerCase();
    if (label.isNotEmpty && recv == label) return true;
    if (label.isNotEmpty && recv.contains(label)) return true;
    return false;
  }

  LiveGiftEvent _eventFromRecent(GiftRecentItem r) {
    return LiveGiftEvent(
      id: r.id,
      senderId: r.senderId,
      senderName: r.senderName,
      receiverName: r.receiverName,
      giftId: r.giftId,
      giftName: r.giftName,
      quantity: r.combo > 1 ? r.combo : 1,
      coinCost: r.jetonAmount,
      timestamp: r.at,
      iconUrl: r.iconUrl,
    );
  }
}

class _GiftLine extends StatelessWidget {
  const _GiftLine({required this.event});

  final LiveGiftEvent event;

  @override
  Widget build(BuildContext context) {
    final avatar = event.senderAvatar?.trim() ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            if (avatar.isNotEmpty)
              ClipOval(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CanlifalNetworkImage(url: avatar, fit: BoxFit.cover),
                ),
              )
            else
              CircleAvatar(
                radius: 11,
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                child: Text(
                  event.senderName.isNotEmpty
                      ? event.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '→ ${event.receiverName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    '${event.giftName} ×${event.quantity}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
