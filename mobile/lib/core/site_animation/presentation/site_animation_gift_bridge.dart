import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/live/domain/entities/live_gift_event.dart';
import '../data/site_animation_resolver.dart';
import 'site_animation_catalog_provider.dart';
import 'site_animation_provider.dart';
import 'widgets/site_animation_context_host.dart';
import '../../features/gifts/presentation/global/global_gift_notification.dart';

/// Büyük hediye olayını site animasyon ctx_gift kuyruğuna yönlendirir.
void dispatchSiteAnimationGiftHighlight(
  Ref ref, {
  required String eventId,
  required String senderName,
  required int jetonAmount,
  String? senderId,
}) {
  if (jetonAmount < 1000) return;
  final catalog = ref.read(siteAnimationCatalogProvider).valueOrNull;
  if (catalog == null) return;
  final cmd = SiteAnimationResolver.resolveGiftHighlight(
    eventId: eventId,
    senderName: senderName,
    senderId: senderId,
    jetonAmount: jetonAmount,
    catalog: catalog,
  );
  if (cmd == null) return;
  ref
      .read(siteAnimationProvider(SiteAnimationContext.gift.overlayId).notifier)
      .queue(cmd);
}

void dispatchSiteAnimationGiftFromLiveEvent(Ref ref, LiveGiftEvent event) {
  dispatchSiteAnimationGiftHighlight(
    ref,
    eventId: event.id,
    senderName: event.senderName,
    senderId: event.senderId,
    jetonAmount: event.jetonAmount,
  );
}

void dispatchSiteAnimationGiftFromNotification(
  Ref ref,
  GlobalGiftNotification notification,
) {
  dispatchSiteAnimationGiftHighlight(
    ref,
    eventId: notification.eventId,
    senderName: notification.senderName,
    senderId: notification.senderId,
    jetonAmount: notification.amount,
  );
}
