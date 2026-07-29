import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/gift_catalog_maps.dart';
import '../../domain/gift_animation_kind.dart';
import '../../domain/gift_asset_type.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import '../../domain/gift_rarity.dart';
import '../../domain/gift_render_meta.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../providers/gift_catalog_index_provider.dart';
import 'gift_media_widget.dart';
import 'premium_2026/premium_gift_icon.dart';

/// CMS video / GIF / Lottie / SVGA — sesli oda ve canlı yayın tam ekran.
class GiftAnimationPlayer extends ConsumerWidget {
  const GiftAnimationPlayer({
    super.key,
    required this.giftId,
    this.gift,
    this.event,
    this.size = 220,
    this.repeat = false,
    this.preferPremiumVisual = false,
    this.fit = BoxFit.contain,
    this.onVideoControllerChanged,
  });

  final String giftId;
  final GiftEntity? gift;
  final LiveGiftEvent? event;
  final double size;
  final bool repeat;
  final bool preferPremiumVisual;
  final BoxFit fit;
  final ValueChanged<VideoPlayerController?>? onVideoControllerChanged;

  GiftEntity _resolve(WidgetRef ref) {
    if (gift != null) return gift!;
    final fromCatalog = lookupGiftCatalog(
      ref.read(giftCatalogByIdProvider),
      giftId,
    );
    final ev = event;
    if (ev != null) {
      final animUrl = GiftRenderMeta.animationUrl(ev, fromCatalog);
      final kind = GiftRenderMeta.animationKindFor(ev, fromCatalog);
      return GiftEntity(
        id: giftId,
        name: ev.giftName,
        price: ev.jetonAmount,
        animationRef: animUrl ?? ev.animationKey,
        rarity: ev.rarity,
        animationKind: kind != GiftAnimationKind.none
            ? kind
            : (fromCatalog?.animationKind ?? GiftAnimationKind.lottie),
        iconUrl: ev.giftImageUrl ??
            ev.iconUrl ??
            ev.thumbnailUrl ??
            fromCatalog?.iconUrl,
        thumbnailUrl: ev.thumbnailUrl ?? fromCatalog?.thumbnailUrl,
        assetType: fromCatalog?.assetType ?? GiftAssetType.unknown,
        mediaType: ev.mediaType ?? fromCatalog?.mediaType,
        mediaWidth: ev.mediaWidth ?? fromCatalog?.mediaWidth,
        mediaHeight: ev.mediaHeight ?? fromCatalog?.mediaHeight,
        assetFormat: ev.assetFormat ?? fromCatalog?.assetFormat,
        animationDurationMs: ev.animationDurationMs ??
            ev.displayDurationMs ??
            fromCatalog?.animationDurationMs ??
            0,
      );
    }
    if (fromCatalog != null) return fromCatalog;
    return GiftEntity(
      id: giftId,
      name: event?.giftName ?? giftId,
      price: event?.jetonAmount ?? event?.coinCost ?? 0,
      animationRef: event?.animationKey,
      rarity: event?.rarity ?? GiftRarity.common,
      animationKind: event?.animationKind ?? GiftAnimationKind.lottie,
      iconUrl: event?.giftImageUrl ?? event?.iconUrl,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = _resolve(ref);
    final canonical = PremiumGiftCatalog2026.canonicalId(giftId) ?? giftId;
    final usePremium =
        preferPremiumVisual && !g.hasCmsAnimation && GiftCatalogMaps.usePremiumPainter(g);
    if (usePremium) {
      return RepaintBoundary(
        child: PremiumGiftIcon(giftId: canonical, size: size),
      );
    }

    final kind = GiftCatalogMaps.resolvedKind(g);
    final emoji = GiftCatalogMaps.emoji(g);
    final ev = event;
    final catalog = lookupGiftCatalog(ref.read(giftCatalogByIdProvider), giftId);

    final mediaSpec = ev != null
        ? GiftMediaSpec.fromEvent(ev, catalog: catalog ?? g)
        : GiftMediaSpec.fromGiftEntity(g);

    final useUnifiedMedia = _usesGiftMediaWidget(kind, mediaSpec.mediaType);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: switch (kind) {
          GiftAnimationKind.lottie when !useUnifiedMedia => _LottiePlayer(
              asset: GiftCatalogMaps.lottieAsset(g),
              networkUrl: g.networkAnimationUrl,
              emoji: emoji,
              size: size,
              repeat: repeat,
              fit: fit,
            ),
          GiftAnimationKind.rive => PremiumGiftIcon(
              giftId: canonical,
              size: size,
            ),
          GiftAnimationKind.svga => _SvgaFallback(
              spec: mediaSpec,
              emoji: emoji,
              size: size,
            ),
          _ when useUnifiedMedia => GiftMediaWidget(
              spec: mediaSpec,
              width: size,
              height: size,
              fit: fit,
              fallbackEmoji: emoji,
              onVideoControllerChanged: onVideoControllerChanged,
            ),
          GiftAnimationKind.none => GiftMediaWidget(
              spec: GiftMediaSpec(
                mediaUrl: g.displayIconUrl,
                thumbnailUrl: g.resolvedThumbnailUrl,
                mediaType: GiftMediaType.png,
              ),
              width: size,
              height: size,
              fit: fit,
              fallbackEmoji: emoji,
            ),
          _ => GiftMediaWidget(
              spec: mediaSpec,
              width: size,
              height: size,
              fit: fit,
              fallbackEmoji: emoji,
              onVideoControllerChanged: onVideoControllerChanged,
            ),
        },
      ),
    );
  }

  static bool _usesGiftMediaWidget(
    GiftAnimationKind kind,
    GiftMediaType mediaType,
  ) {
    if (mediaType.isVideo) return true;
    return switch (kind) {
      GiftAnimationKind.video ||
      GiftAnimationKind.gif ||
      GiftAnimationKind.image =>
        true,
      _ => mediaType == GiftMediaType.svg ||
          mediaType == GiftMediaType.png ||
          mediaType == GiftMediaType.webp,
    };
  }
}

class _LottiePlayer extends StatelessWidget {
  const _LottiePlayer({
    required this.asset,
    required this.networkUrl,
    required this.emoji,
    required this.size,
    required this.repeat,
    this.fit = BoxFit.contain,
  });

  final String? asset;
  final String? networkUrl;
  final String emoji;
  final double size;
  final bool repeat;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final net = networkUrl;
    if (net != null && net.isNotEmpty) {
      return Lottie.network(
        net,
        width: size,
        height: size,
        repeat: repeat,
        fit: fit,
        errorBuilder: (_, _, _) =>
            Text(emoji, style: TextStyle(fontSize: size * 0.45)),
      );
    }
    if (asset == null) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.45));
    }
    return Lottie.asset(
      asset!,
      width: size,
      height: size,
      repeat: repeat,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

class _SvgaFallback extends StatelessWidget {
  const _SvgaFallback({
    required this.spec,
    required this.emoji,
    required this.size,
  });

  final GiftMediaSpec spec;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GiftMediaWidget(
      spec: GiftMediaSpec(
        mediaUrl: spec.thumbnailUrl,
        thumbnailUrl: spec.thumbnailUrl,
        mediaType: GiftMediaType.png,
      ),
      width: size,
      height: size,
      fallbackEmoji: emoji,
    );
  }
}
