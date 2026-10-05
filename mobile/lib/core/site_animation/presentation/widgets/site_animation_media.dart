import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/video/video_cache_service.dart';
import '../../domain/site_animation_asset.dart';
import '../../domain/site_animation_type.dart';
import 'site_animation_fallback.dart';
import '../../domain/site_animation_command.dart';
import 'site_animation_entrance_card.dart';
import 'site_animation_exit_card.dart';

/// Lottie / video / native fallback oynatıcı.
class SiteAnimationMedia extends StatefulWidget {
  const SiteAnimationMedia({
    super.key,
    required this.command,
    this.useFallbackOnly = false,
    this.animationPhase = 0,
  });

  final SiteAnimationCommand command;
  final bool useFallbackOnly;
  final double animationPhase;

  @override
  State<SiteAnimationMedia> createState() => _SiteAnimationMediaState();
}

class _SiteAnimationMediaState extends State<SiteAnimationMedia> {
  var _failed = false;

  Widget _fallback({bool failed = false}) {
    return SiteAnimationFallbackCard(
      userName: widget.command.userName,
      tier: widget.command.tier,
      type: widget.command.type,
      avatarUrl: widget.command.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useFallbackOnly || _failed) {
      return _fallback();
    }

    // Merkezi animasyon sistemi (backend kataloğu): görsel, kartın ARKASINDA
    // geniş bir bant olarak gösterilir; kart ad/alt yazıyı taşır.
    final remote = widget.command.asset;
    if ((widget.command.type.isEntrance || widget.command.type.isExit) &&
        remote.kind == SiteAnimationMediaKind.image &&
        remote.hasRemote) {
      final card = widget.command.type.isEntrance
          ? SiteAnimationEntranceCard(
              command: widget.command,
              phase: widget.animationPhase,
              compact: true,
            )
          : SiteAnimationExitCard(
              command: widget.command,
              phase: widget.animationPhase,
            );
      return _BackdropBanner(
        url: remote.url!,
        scale: widget.command.layout.scale,
        child: card,
        onFailed: () => setState(() => _failed = true),
      );
    }

    if (widget.command.type.isEntrance) {
      return SiteAnimationEntranceCard(
        command: widget.command,
        phase: widget.animationPhase,
      );
    }

    if (widget.command.type.isExit) {
      return SiteAnimationExitCard(
        command: widget.command,
        phase: widget.animationPhase,
      );
    }

    final asset = widget.command.asset;
    if (asset.kind == SiteAnimationMediaKind.rive ||
        asset.kind == SiteAnimationMediaKind.svga) {
      return _fallback();
    }

    if (asset.hasBundle) {
      return Lottie.asset(
        asset.bundlePath!,
        fit: BoxFit.contain,
        repeat: false,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return _fallback();
        },
      );
    }

    if (asset.hasRemote && asset.kind == SiteAnimationMediaKind.lottie) {
      final url = asset.url!;
      if (url.endsWith('.lottie')) {
        return Lottie.network(
          url,
          fit: BoxFit.contain,
          repeat: !widget.command.type.isEntrance && !widget.command.type.isExit,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _failed = true);
            });
            return _fallback();
          },
        );
      }
      return Lottie.network(
        asset.url!,
        fit: BoxFit.contain,
        repeat: false,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return _fallback();
        },
      );
    }

    if (asset.hasRemote &&
        (asset.kind == SiteAnimationMediaKind.video ||
            asset.url!.endsWith('.mp4') ||
            asset.url!.endsWith('.webm'))) {
      return _CachedVideoThumb(
        url: asset.url!,
        onFailed: () => setState(() => _failed = true),
        fallback: _fallback(),
      );
    }

    return _fallback();
  }
}

class _CachedVideoThumb extends StatefulWidget {
  const _CachedVideoThumb({
    required this.url,
    required this.onFailed,
    required this.fallback,
  });

  final String url;
  final VoidCallback onFailed;
  final Widget fallback;

  @override
  State<_CachedVideoThumb> createState() => _CachedVideoThumbState();
}

class _CachedVideoThumbState extends State<_CachedVideoThumb> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _warm();
  }

  Future<void> _warm() async {
    try {
      await VideoCacheService.instance.prefetch(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return widget.fallback;
    // MP4 opaque arka plan — production'da native kart tercih edilir.
    return widget.fallback;
  }
}

/// Kartın arkasında taşan, ölçeklenen backend görseli (SVG / PNG / GIF / APNG).
class _BackdropBanner extends StatelessWidget {
  const _BackdropBanner({
    required this.url,
    required this.scale,
    required this.child,
    required this.onFailed,
  });

  final String url;
  final double scale;
  final Widget child;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    final isSvg = url.toLowerCase().split('?').first.endsWith('.svg');
    void fail() => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onFailed();
        });
    final art = isSvg
        ? SvgPicture.network(
            url,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const SizedBox.shrink(),
          )
        : Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              fail();
              return const SizedBox.shrink();
            },
          );
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -16 * scale,
          right: -16 * scale,
          top: -34 * scale,
          bottom: -34 * scale,
          child: IgnorePointer(child: art),
        ),
        child,
      ],
    );
  }
}
