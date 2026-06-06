import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/gift_cache_service.dart';
import '../../data/gift_catalog_maps.dart';
import '../../domain/gift_animation_kind.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_rarity.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import 'premium_2026/premium_gift_icon.dart';

/// Lottie / Rive / SVGA (yerel veya ağ) — RepaintBoundary ile izole oynatıcı.
class GiftAnimationPlayer extends StatelessWidget {
  const GiftAnimationPlayer({
    super.key,
    required this.giftId,
    this.gift,
    this.event,
    this.size = 220,
    this.repeat = false,
    this.preferPremiumVisual = false,
  });

  final String giftId;
  final GiftEntity? gift;
  final LiveGiftEvent? event;
  final double size;
  final bool repeat;
  final bool preferPremiumVisual;

  GiftEntity get _entity {
    if (gift != null) return gift!;
    return GiftEntity(
      id: giftId,
      name: event?.giftName ?? giftId,
      price: event?.coinCost ?? 0,
      animationRef: event?.animationKey,
      rarity: event?.rarity ?? GiftRarity.common,
      animationKind: event?.animationKind ?? GiftAnimationKind.lottie,
      iconUrl: event?.iconUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _entity;
    final canonical = PremiumGiftCatalog2026.canonicalId(giftId) ?? giftId;
    if (preferPremiumVisual || GiftCatalogMaps.usePremiumPainter(g)) {
      return RepaintBoundary(
        child: PremiumGiftIcon(giftId: canonical, size: size),
      );
    }
    final kind = GiftCatalogMaps.resolvedKind(g);
    final emoji = GiftCatalogMaps.emoji(g);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: switch (kind) {
          GiftAnimationKind.lottie => _LottiePlayer(
              asset: GiftCatalogMaps.lottieAsset(g),
              emoji: emoji,
              size: size,
              repeat: repeat,
            ),
          GiftAnimationKind.rive => _RivePlayer(
              asset: GiftCatalogMaps.riveAsset(g),
              emoji: emoji,
              size: size,
            ),
          GiftAnimationKind.svga => _SvgaPlayer(
              networkUrl: _networkAnimUrl(g),
              emoji: emoji,
              size: size,
            ),
          GiftAnimationKind.none => _IconOrEmoji(
              iconUrl: g.iconUrl ?? event?.iconUrl,
              emoji: emoji,
              size: size,
            ),
        },
      ),
    );
  }

  String? _networkAnimUrl(GiftEntity g) {
    final ref = g.animationRef;
    if (ref != null && ref.startsWith('http')) return ref;
    return null;
  }
}

class _LottiePlayer extends StatelessWidget {
  const _LottiePlayer({
    required this.asset,
    required this.emoji,
    required this.size,
    required this.repeat,
  });

  final String? asset;
  final String emoji;
  final double size;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
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

class _RivePlayer extends StatelessWidget {
  const _RivePlayer({
    required this.asset,
    required this.emoji,
    required this.size,
  });

  final String? asset;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = asset;
    if (path == null || path.isEmpty) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.45));
    }
    return RiveAnimation.asset(
      path,
      fit: BoxFit.contain,
      placeHolder: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.4)),
      ),
    );
  }
}

class _SvgaPlayer extends StatelessWidget {
  const _SvgaPlayer({
    required this.networkUrl,
    required this.emoji,
    required this.size,
  });

  final String? networkUrl;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return FutureBuilder(
        future: GiftCacheService.instance.getBytes(networkUrl!),
        builder: (_, snap) => _pulseEmoji(emoji, size),
      );
    }
    return _pulseEmoji(emoji, size);
  }

  Widget _pulseEmoji(String e, double s) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.15),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Text(e, style: TextStyle(fontSize: s * 0.5)),
    );
  }
}

class _IconOrEmoji extends StatelessWidget {
  const _IconOrEmoji({
    required this.iconUrl,
    required this.emoji,
    required this.size,
  });

  final String? iconUrl;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) =>
            Text(emoji, style: TextStyle(fontSize: size * 0.45)),
      );
    }
    return Text(emoji, style: TextStyle(fontSize: size * 0.45));
  }
}
