import '../../live/domain/entities/live_gift_event.dart';
import '../data/gift_catalog_maps.dart';
import 'gift_animation_kind.dart';
import 'gift_asset_type.dart';
import 'gift_entity.dart';
import 'gift_engine_models.dart';

/// SSE hediye olayını CMS katalog satırı ile zenginleştirir (video/Lottie URL).
LiveGiftEvent enrichGiftEventFromCatalog(
  LiveGiftEvent event,
  GiftEntity? catalog,
) {
  if (catalog == null) return event;
  final animUrl = catalog.networkAnimationUrl;
  final kind = GiftCatalogMaps.resolvedKind(catalog);
  final icon = event.iconUrl ??
      event.giftImageUrl ??
      catalog.displayIconUrl;
  final isVideo = catalog.assetType == GiftAssetType.video ||
      kind == GiftAnimationKind.video;
  final hasAnim = animUrl != null && kind != GiftAnimationKind.none;
  if (!hasAnim && icon == event.iconUrl) return event;

  final thumb = event.thumbnailUrl ?? catalog.thumbnailUrl;
  final videoUrl = event.videoUrl ?? (isVideo ? animUrl : null);
  final assetFormat = event.assetFormat ?? _assetFormatFrom(catalog, animUrl);
  final engineAnimType = event.engineAnimationType ??
      _engineAnimationType(catalog, kind, animUrl);

  return LiveGiftEvent(
    id: event.id,
    senderId: event.senderId,
    receiverId: event.receiverId,
    senderName: event.senderName,
    receiverName: event.receiverName,
    giftId: event.giftId,
    giftName: event.giftName.trim().isNotEmpty ? event.giftName : catalog.name,
    quantity: event.quantity,
    coinCost: event.coinCost > 0 ? event.coinCost : catalog.price,
    giftPrice: event.giftPrice > 0 ? event.giftPrice : catalog.price,
    totalCoin: event.totalCoin,
    totalDiamond: event.totalDiamond,
    combo: event.combo,
    timestamp: event.timestamp,
    iconUrl: icon,
    giftImageUrl: icon,
    animationKey: animUrl ?? event.animationKey ?? catalog.animationRef,
    rarity: event.rarity,
    animationKind: hasAnim ? kind : event.animationKind,
    soundKey: event.soundKey ?? catalog.soundUrl ?? catalog.soundKey,
    remainingBalance: event.remainingBalance,
    seatIndex: event.seatIndex,
    senderAvatar: event.senderAvatar,
    receiverAvatar: event.receiverAvatar,
    giftType: event.giftType,
    giftIcon: event.giftIcon,
    assetUrl: event.assetUrl ?? animUrl,
    assetType: event.assetType ?? catalog.assetType.name,
    displayType: event.displayType ?? catalog.displayType.name,
    isFullscreen: event.isFullscreen ?? catalog.isFullscreen ?? isVideo,
    animationDurationMs: event.animationDurationMs ??
        (catalog.animationDurationMs > 0
            ? catalog.animationDurationMs
            : (isVideo ? 8000 : 0)),
    assetFormat: assetFormat,
    imageUrl: event.imageUrl ?? thumb,
    videoUrl: videoUrl,
    thumbnailUrl: thumb,
    engineDisplayArea: event.engineDisplayArea ??
        (isVideo ? 'FULL_SCREEN' : null),
    enginePriority: event.enginePriority ?? (isVideo ? 'LARGE' : null),
    engineAnimationType: engineAnimType,
    engineDurationMs: event.engineDurationMs ??
        (catalog.animationDurationMs > 0
            ? catalog.animationDurationMs
            : (isVideo ? 8000 : null)),
    engineQueueGapMs: event.engineQueueGapMs,
    engineFeedDurationMs: event.engineFeedDurationMs,
    engineSeatEffects: event.engineSeatEffects,
    engineParticleKey: event.engineParticleKey,
    mediaType: event.mediaType ?? catalog.mediaType,
    mediaWidth: event.mediaWidth ?? catalog.mediaWidth,
    mediaHeight: event.mediaHeight ?? catalog.mediaHeight,
  );
}

String? _assetFormatFrom(GiftEntity catalog, String? animUrl) {
  if (catalog.assetType == GiftAssetType.video) {
    final inferred = GiftEngineAnimationType.inferFromUrl(animUrl);
    if (inferred == GiftEngineAnimationType.webm) return 'webm';
    return 'mp4';
  }
  return switch (catalog.animationKind) {
    GiftAnimationKind.gif => 'gif',
    GiftAnimationKind.lottie => 'lottie',
    GiftAnimationKind.svga => 'svga',
    GiftAnimationKind.video => 'mp4',
    _ => null,
  };
}

String? _engineAnimationType(
  GiftEntity catalog,
  GiftAnimationKind kind,
  String? animUrl,
) {
  if (catalog.assetType == GiftAssetType.video || kind == GiftAnimationKind.video) {
    final inferred = GiftEngineAnimationType.inferFromUrl(animUrl);
    return inferred == GiftEngineAnimationType.webm ? 'webm' : 'mp4';
  }
  return switch (kind) {
    GiftAnimationKind.lottie => 'lottie',
    GiftAnimationKind.svga => 'svga',
    GiftAnimationKind.gif => 'gif',
    GiftAnimationKind.image => 'png',
    _ => null,
  };
}
