import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../domain/gift_engine_sse_router.dart';
import '../../domain/gift_payload_util.dart';
import '../../../voice_hub/presentation/providers/voice_gift_providers.dart';
import 'gift_session_controller.dart';
import 'gift_sync_log.dart';

/// SSE hediye payload'ını motor kurallarına göre yönlendirir.
void dispatchGiftSsePayload({
  required WidgetRef ref,
  required String sessionKey,
  required Map<String, dynamic> payload,
  required LiveGiftsRemoteDataSource giftsRemote,
  bool voiceRealtime = true,
}) {
  final unwrapped = GiftPayloadUtil.unwrap(payload);
  final controller = ref.read(giftSessionProvider(sessionKey).notifier);
  final action = controller.routeGiftSsePayload(unwrapped);
  final eventId = unwrapped['id']?.toString() ?? '';

  switch (action) {
    case GiftEngineSseAction.skip:
      GiftSyncLog.dedupeSkipped(sessionKey, eventId, 'engine_sse_skip');
      return;
    case GiftEngineSseAction.queueSync:
      controller.onEngineQueueUpdated(
        unwrapped,
        parseItem: (item) =>
            giftsRemote.parseGiftEvent(item, streamId: sessionKey),
      );
      return;
    case GiftEngineSseAction.finished:
      controller.onEngineGiftFinished(unwrapped);
      return;
    case GiftEngineSseAction.visualize:
    case GiftEngineSseAction.legacyVisualize:
      final ev = giftsRemote.parseGiftEvent(unwrapped, streamId: sessionKey);
      if (ev == null) return;
      GiftSyncLog.broadcast(sessionKey, 'sse', ev.id);
      if (voiceRealtime) {
        ref.read(voiceRoomGiftRealtimeProvider).publishRemote(ev);
      } else {
        ref.read(liveGiftRealtimeProvider).publishRemote(ev);
      }
  }
}

/// `Ref` tabanlı (provider notifier içinden) aynı yönlendirme.
void dispatchGiftSsePayloadRef({
  required Ref ref,
  required String sessionKey,
  required Map<String, dynamic> payload,
  required LiveGiftsRemoteDataSource giftsRemote,
  bool voiceRealtime = true,
}) {
  final unwrapped = GiftPayloadUtil.unwrap(payload);
  final controller = ref.read(giftSessionProvider(sessionKey).notifier);
  final action = controller.routeGiftSsePayload(unwrapped);
  final eventId = unwrapped['id']?.toString() ?? '';

  switch (action) {
    case GiftEngineSseAction.skip:
      GiftSyncLog.dedupeSkipped(sessionKey, eventId, 'engine_sse_skip');
      return;
    case GiftEngineSseAction.queueSync:
      controller.onEngineQueueUpdated(
        unwrapped,
        parseItem: (item) =>
            giftsRemote.parseGiftEvent(item, streamId: sessionKey),
      );
      return;
    case GiftEngineSseAction.finished:
      controller.onEngineGiftFinished(unwrapped);
      return;
    case GiftEngineSseAction.visualize:
    case GiftEngineSseAction.legacyVisualize:
      final ev = giftsRemote.parseGiftEvent(unwrapped, streamId: sessionKey);
      if (ev == null) return;
      GiftSyncLog.broadcast(sessionKey, 'sse', ev.id);
      if (voiceRealtime) {
        ref.read(voiceRoomGiftRealtimeProvider).publishRemote(ev);
      } else {
        ref.read(liveGiftRealtimeProvider).publishRemote(ev);
      }
  }
}
