import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/gift_render_meta.dart';
import '../../data/gift_cache_service.dart';
import '../../data/gift_catalog_maps.dart';
import '../../domain/gift_animation_kind.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_rarity.dart';
import '../../domain/premium_gift_catalog_2026.dart';
import '../providers/gift_catalog_index_provider.dart';
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
  });

  final String giftId;
  final GiftEntity? gift;
  final LiveGiftEvent? event;
  final double size;
  final bool repeat;
  final bool preferPremiumVisual;
  final BoxFit fit;

  GiftEntity _resolve(WidgetRef ref) {
    if (gift != null) return gift!;
    final fromCatalog = lookupGiftCatalog(
      ref.read(giftCatalogByIdProvider),
      giftId,
    );
    final ev = event;
    if (ev != null) {
      final animUrl = GiftRenderMeta.animationUrl(ev, fromCatalog);
      final kindFromAsset = ev.assetType != null && ev.assetType!.trim().isNotEmpty
          ? GiftAnimationKind.parse(ev.assetType)
          : GiftAnimationKind.none;
      final kindFromUrl = GiftAnimationKind.fromUrl(animUrl);
      final kind = kindFromAsset != GiftAnimationKind.none
          ? kindFromAsset
          : (ev.animationKind != GiftAnimationKind.lottie &&
                  ev.animationKind != GiftAnimationKind.none
              ? ev.animationKind
              : kindFromUrl);
      return GiftEntity(
        id: giftId,
        name: ev.giftName,
        price: ev.jetonAmount,
        animationRef: animUrl ?? ev.animationKey,
        rarity: ev.rarity,
        animationKind: kind != GiftAnimationKind.none
            ? kind
            : (fromCatalog?.animationKind ?? GiftAnimationKind.lottie),
        iconUrl: ev.giftImageUrl ?? ev.iconUrl ?? fromCatalog?.iconUrl,
        animationDurationMs: ev.displayDurationMs ?? fromCatalog?.animationDurationMs ?? 0,
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
    final networkUrl = g.networkAnimationUrl;

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: switch (kind) {
          GiftAnimationKind.video => _NetworkVideoPlayer(
              url: networkUrl ?? '',
              emoji: emoji,
              size: size,
              durationMs: g.animationDurationMs,
              fit: fit,
            ),
          GiftAnimationKind.gif => _GifPlayer(
              url: networkUrl ?? g.displayIconUrl ?? '',
              emoji: emoji,
              size: size,
              fit: fit,
            ),
          GiftAnimationKind.image => _IconOrEmoji(
              iconUrl: networkUrl ?? g.displayIconUrl,
              emoji: emoji,
              size: size,
              fit: fit,
            ),
          GiftAnimationKind.lottie => _LottiePlayer(
              asset: GiftCatalogMaps.lottieAsset(g),
              networkUrl: networkUrl,
              emoji: emoji,
              size: size,
              repeat: repeat,
              fit: fit,
            ),
          GiftAnimationKind.rive => PremiumGiftIcon(
              giftId: canonical,
              size: size,
            ),
          GiftAnimationKind.svga => _SvgaPlayer(
              networkUrl: networkUrl,
              fallbackIcon: g.displayIconUrl,
              emoji: emoji,
              size: size,
            ),
          GiftAnimationKind.none => _IconOrEmoji(
              iconUrl: g.displayIconUrl ?? event?.iconUrl,
              emoji: emoji,
              size: size,
            ),
        },
      ),
    );
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

class _NetworkVideoPlayer extends StatefulWidget {
  const _NetworkVideoPlayer({
    required this.url,
    required this.emoji,
    required this.size,
    this.durationMs = 0,
    this.fit = BoxFit.contain,
  });

  final String url;
  final String emoji;
  final double size;
  final int durationMs;
  final BoxFit fit;

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  VideoPlayerController? _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.url.trim();
    if (url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    try {
      await GiftCacheService.instance.getBytes(url);
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.setLooping(false);
      await c.play();
      setState(() => _controller = c);
      final ms = widget.durationMs > 0
          ? widget.durationMs
          : c.value.duration.inMilliseconds;
      if (ms > 0) {
        Future.delayed(Duration(milliseconds: ms), () {
          if (mounted && _controller == c) c.pause();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NetworkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || widget.url.isEmpty) {
      return Text(widget.emoji, style: TextStyle(fontSize: widget.size * 0.45));
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
      );
    }
    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _GifPlayer extends StatelessWidget {
  const _GifPlayer({
    required this.url,
    required this.emoji,
    required this.size,
    this.fit = BoxFit.contain,
  });

  final String url;
  final String emoji;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.45));
    }
    return CanlifalNetworkImage(
      url: url,
      width: size,
      height: size,
      fit: fit,
      errorWidget: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

class _SvgaPlayer extends StatefulWidget {
  const _SvgaPlayer({
    required this.networkUrl,
    required this.fallbackIcon,
    required this.emoji,
    required this.size,
  });

  final String? networkUrl;
  final String? fallbackIcon;
  final String emoji;
  final double size;

  @override
  State<_SvgaPlayer> createState() => _SvgaPlayerState();
}

class _SvgaPlayerState extends State<_SvgaPlayer> {
  @override
  void initState() {
    super.initState();
    final url = widget.networkUrl;
    if (url != null && url.isNotEmpty) {
      unawaited(GiftCacheService.instance.getBytes(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.fallbackIcon;
    if (icon != null && icon.isNotEmpty) {
      return CanlifalNetworkImage(
        url: icon,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorWidget: _pulseEmoji(widget.emoji, widget.size),
      );
    }
    return _pulseEmoji(widget.emoji, widget.size);
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
    this.fit = BoxFit.contain,
  });

  final String? iconUrl;
  final String emoji;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return CanlifalNetworkImage(
        url: iconUrl!,
        width: size,
        height: size,
        fit: fit,
        errorWidget: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
      );
    }
    return Text(emoji, style: TextStyle(fontSize: size * 0.45));
  }
}
