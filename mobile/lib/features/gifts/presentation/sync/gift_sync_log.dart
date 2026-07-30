import 'package:flutter/foundation.dart';

import '../../../live/domain/entities/live_gift_event.dart';

/// Hediye senkronizasyonu — release'te yalnızca pipeline zamanlaması.
abstract final class GiftSyncLog {
  static void broadcast(String roomId, String channel, String eventId) {
    if (kDebugMode) {
      debugPrint('[GiftSync] broadcast room=$roomId channel=$channel id=$eventId');
    }
  }

  static void sseConnected(String roomId) {
    if (kDebugMode) {
      debugPrint('[GiftSync] sse_connected room=$roomId');
    }
  }

  static void eventReceived({
    required String roomId,
    required String source,
    String? role,
    required LiveGiftEvent event,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[GiftSync] event_received room=$roomId source=$source role=${role ?? 'user'} '
        'id=${event.id} gift=${event.giftId}',
      );
    }
  }

  static void eventProcessed(String roomId, String eventId, {int? combo}) {
    if (kDebugMode) {
      debugPrint(
        '[GiftSync] event_processed room=$roomId id=$eventId combo=${combo ?? 1}',
      );
    }
  }

  static void uiRender(String roomId, String layer) {
    if (kDebugMode) {
      debugPrint('[GiftSync] ui_render room=$roomId layer=$layer');
    }
  }

  static void hostReceived(String roomId, String eventId) {
    if (kDebugMode) {
      debugPrint('[GiftSync] host_event room=$roomId id=$eventId');
    }
  }

  static void guestReceived(String roomId, String eventId) {
    if (kDebugMode) {
      debugPrint('[GiftSync] guest_event room=$roomId id=$eventId');
    }
  }

  static void dedupeSkipped(String roomId, String eventId, String reason) {
    if (kDebugMode) {
      debugPrint('[GiftSync] dedupe_skip room=$roomId id=$eventId reason=$reason');
    }
  }

  /// Pipeline aşaması — profil/release'te de ölçüm için.
  static void pipelineStage(String eventId, String stage) {
    debugPrint('[GiftPipeline] id=$eventId stage=$stage');
  }

  /// Aşama süresi (ms).
  static void pipelineMs(String eventId, String stage, int ms) {
    debugPrint('[GiftPipeline] id=$eventId $stage=${ms}ms');
  }

  /// SSE alımından bu yana toplam gecikme.
  static void pipelineTotal(String eventId, int msSinceReceived) {
    debugPrint('[GiftPipeline] id=$eventId total=${msSinceReceived}ms');
    if (msSinceReceived > 300) {
      debugPrint('[GiftPipeline] WARN slow id=$eventId ${msSinceReceived}ms');
    }
  }
}
