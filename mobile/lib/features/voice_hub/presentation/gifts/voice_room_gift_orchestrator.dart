import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gifts/domain/gift_entity.dart';
import '../../../gifts/domain/gift_event_catalog_enricher.dart';
import '../../../gifts/presentation/providers/gift_catalog_index_provider.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../../visual_fx/domain/fx_gift_display_item.dart';
import '../../../visual_fx/domain/fx_gift_tier.dart';
import '../../../visual_fx/presentation/providers/voice_room_gift_display_provider.dart';
import '../providers/voice_recent_gifts_provider.dart';
import '../providers/voice_seat_gift_flash_provider.dart';

/// Oda oturumu — canonical hediye event id dedupe (SSE + realtime + poll).
class VoiceRoomGiftOrchestrator {
  VoiceRoomGiftOrchestrator();

  static const _maxIds = 512;
  final _processedIds = <String>{};

  bool tryAccept(LiveGiftEvent event) {
    final id = canonicalGiftEventId(event);
    if (id.isEmpty) return false;
    if (_processedIds.contains(id)) return false;
    _processedIds.add(id);
    while (_processedIds.length > _maxIds) {
      _processedIds.remove(_processedIds.first);
    }
    return true;
  }

  void clear() => _processedIds.clear();
}

final voiceRoomGiftOrchestratorProvider = Provider.family
    .autoDispose<VoiceRoomGiftOrchestrator, String>(
  (ref, roomKey) => VoiceRoomGiftOrchestrator(),
);

/// Tek giriş noktası — sesli oda hediye UI (toast/ticker/chat çoğaltma yok).
void dispatchVoiceRoomGiftEvent({
  required WidgetRef ref,
  required String sessionKey,
  required LiveGiftEvent raw,
  required String source,
  String? userRole,
  bool isHost = false,
}) {
  if (sessionKey.isEmpty || raw.jetonAmount <= 0) return;

  final orchestrator = ref.read(voiceRoomGiftOrchestratorProvider(sessionKey));
  final catalog = lookupGiftCatalog(
    ref.read(allGiftCatalogByIdProvider),
    raw.giftId,
  );
  final event = enrichGiftEventFromCatalog(raw, catalog);
  if (!orchestrator.tryAccept(event)) return;

  final featured = _isFeaturedGift(event, catalog);

  ref.read(giftSessionProvider(sessionKey).notifier).onVoiceGiftSent(
        event,
        source: source,
        userRole: userRole,
        isHost: isHost,
      );
  ref.read(voiceRoomGiftDisplayProvider.notifier).onGiftEvent(
        event,
        forceFeaturedBanner: featured,
      );
  ref.read(voiceRecentGiftsProvider.notifier).recordGifterOnly(event);
  ref.read(voiceSeatGiftFlashProvider(sessionKey).notifier).enqueue(event);
}

void dispatchVoiceRoomGiftEventRef({
  required Ref ref,
  required String sessionKey,
  required LiveGiftEvent raw,
  required String source,
}) {
  if (sessionKey.isEmpty || raw.jetonAmount <= 0) return;
  final orchestrator = ref.read(voiceRoomGiftOrchestratorProvider(sessionKey));
  final catalog = lookupGiftCatalog(
    ref.read(allGiftCatalogByIdProvider),
    raw.giftId,
  );
  final event = enrichGiftEventFromCatalog(raw, catalog);
  if (!orchestrator.tryAccept(event)) return;
  final featured = _isFeaturedGift(event, catalog);
  ref.read(giftSessionProvider(sessionKey).notifier).onVoiceGiftSent(
        event,
        source: source,
      );
  ref.read(voiceRoomGiftDisplayProvider.notifier).onGiftEvent(
        event,
        forceFeaturedBanner: featured,
      );
  ref.read(voiceRecentGiftsProvider.notifier).recordGifterOnly(event);
  ref.read(voiceSeatGiftFlashProvider(sessionKey).notifier).enqueue(event);
}

bool _isFeaturedGift(LiveGiftEvent event, GiftEntity? catalog) {
  if (catalog?.isFeatured == true) return true;
  if (event.isFullscreen == true || event.visibleAsFullscreen == true) {
    return true;
  }
  return FxGiftTier.fromJeton(event.jetonAmount).isBigGift;
}

String canonicalGiftEventId(LiveGiftEvent event) =>
    FxGiftDisplayItem.fromLiveGift(event).eventId;
