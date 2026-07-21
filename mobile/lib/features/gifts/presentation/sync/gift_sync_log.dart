import 'package:flutter/foundation.dart';

import '../../../live/domain/entities/live_gift_event.dart';

/// Hediye senkronizasyonu — broadcast, SSE, işleme ve UI logları.
abstract final class GiftSyncLog {
  static void broadcast(String roomId, String channel, String eventId) {
    debugPrint('[GiftSync] broadcast room=$roomId channel=$channel id=$eventId');
  }

  static void sseConnected(String roomId) {
    debugPrint('[GiftSync] sse_connected room=$roomId');
  }

  static void eventReceived({
    required String roomId,
    required String source,
    String? role,
    required LiveGiftEvent event,
  }) {
    debugPrint(
      '[GiftSync] event_received room=$roomId source=$source role=${role ?? 'user'} '
      'id=${event.id} gift=${event.giftId} sender=${event.senderId ?? event.senderName} '
      'receiver=${event.receiverId ?? event.receiverName} jeton=${event.jetonAmount}',
    );
  }

  static void eventProcessed(String roomId, String eventId, {int? combo}) {
    debugPrint(
      '[GiftSync] event_processed room=$roomId id=$eventId combo=${combo ?? 1}',
    );
  }

  static void uiRender(String roomId, String layer) {
    debugPrint('[GiftSync] ui_render room=$roomId layer=$layer');
  }

  static void hostReceived(String roomId, String eventId) {
    debugPrint('[GiftSync] host_event room=$roomId id=$eventId');
  }

  static void guestReceived(String roomId, String eventId) {
    debugPrint('[GiftSync] guest_event room=$roomId id=$eventId');
  }

  static void dedupeSkipped(String roomId, String eventId, String reason) {
    debugPrint('[GiftSync] dedupe_skip room=$roomId id=$eventId reason=$reason');
  }
}
