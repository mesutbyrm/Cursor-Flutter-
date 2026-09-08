import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/gifts/presentation/global/global_gift_notification.dart';
import '../../../features/live/domain/entities/live_gift_event.dart';
import '../data/site_animation_resolver.dart';
import 'site_animation_catalog_provider.dart';
import 'site_animation_provider.dart';
import 'widgets/site_animation_context_host.dart';

typedef _SiteAnimationRead = T Function<T>(ProviderListenable<T> provider);

void _dispatchSiteAnimationGiftHighlight(
  _SiteAnimationRead read, {
  required String eventId,
  required String senderName,
  required int jetonAmount,
  String? senderId,
}) {
  if (jetonAmount < 1000) return;
  final catalog = read(siteAnimationCatalogProvider).valueOrNull;
  if (catalog == null) return;
  final cmd = SiteAnimationResolver.resolveGiftHighlight(
    eventId: eventId,
    senderName: senderName,
    senderId: senderId,
    jetonAmount: jetonAmount,
    catalog: catalog,
  );
  if (cmd == null) return;
  read(siteAnimationProvider(SiteAnimationContext.gift.overlayId).notifier)
      .queue(cmd);
}

/// Büyük hediye olayını site animasyon ctx_gift kuyruğuna yönlendirir.
void dispatchSiteAnimationGiftHighlightRef(
  Ref ref, {
  required String eventId,
  required String senderName,
  required int jetonAmount,
  String? senderId,
}) =>
    _dispatchSiteAnimationGiftHighlight(
      ref.read,
      eventId: eventId,
      senderName: senderName,
      senderId: senderId,
      jetonAmount: jetonAmount,
    );

void dispatchSiteAnimationGiftHighlight(
  WidgetRef ref, {
  required String eventId,
  required String senderName,
  required int jetonAmount,
  String? senderId,
}) =>
    _dispatchSiteAnimationGiftHighlight(
      ref.read,
      eventId: eventId,
      senderName: senderName,
      senderId: senderId,
      jetonAmount: jetonAmount,
    );

void dispatchSiteAnimationGiftFromLiveEventRef(Ref ref, LiveGiftEvent event) {
  _dispatchSiteAnimationGiftHighlight(
    ref.read,
    eventId: event.id,
    senderName: event.senderName,
    senderId: event.senderId,
    jetonAmount: event.jetonAmount,
  );
}

void dispatchSiteAnimationGiftFromLiveEvent(WidgetRef ref, LiveGiftEvent event) {
  _dispatchSiteAnimationGiftHighlight(
    ref.read,
    eventId: event.id,
    senderName: event.senderName,
    senderId: event.senderId,
    jetonAmount: event.jetonAmount,
  );
}

void dispatchSiteAnimationGiftFromNotificationRef(
  Ref ref,
  GlobalGiftNotification notification,
) {
  _dispatchSiteAnimationGiftHighlight(
    ref.read,
    eventId: notification.eventId,
    senderName: notification.senderName,
    senderId: notification.senderId,
    jetonAmount: notification.amount,
  );
}

void dispatchSiteAnimationGiftFromNotification(
  WidgetRef ref,
  GlobalGiftNotification notification,
) {
  _dispatchSiteAnimationGiftHighlight(
    ref.read,
    eventId: notification.eventId,
    senderName: notification.senderName,
    senderId: notification.senderId,
    jetonAmount: notification.amount,
  );
}
