import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/video/video_cache_service.dart';
import '../../domain/site_animation_asset.dart';
import 'site_animation_fallback.dart';
import '../../domain/site_animation_command.dart';

/// Lottie / video / native fallback oynatıcı.
class SiteAnimationMedia extends StatefulWidget {
  const SiteAnimationMedia({
    super.key,
    required this.command,
    this.useFallbackOnly = false,
  });

  final SiteAnimationCommand command;
  final bool useFallbackOnly;

  @override
  State<SiteAnimationMedia> createState() => _SiteAnimationMediaState();
}

class _SiteAnimationMediaState extends State<SiteAnimationMedia> {
  var _failed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.useFallbackOnly || _failed) {
      return SiteAnimationFallbackCard(
        userName: widget.command.userName,
        tier: widget.command.tier,
        type: widget.command.type,
        avatarUrl: widget.command.avatarUrl,
      );
    }

    final asset = widget.command.asset;
    if (asset.hasBundle) {
      return Lottie.asset(
        asset.bundlePath!,
        fit: BoxFit.contain,
        repeat: false,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return SiteAnimationFallbackCard(
            userName: widget.command.userName,
            tier: widget.command.tier,
            type: widget.command.type,
            avatarUrl: widget.command.avatarUrl,
          );
        },
      );
    }

    if (asset.hasRemote && asset.kind == SiteAnimationMediaKind.lottie) {
      return Lottie.network(
        asset.url!,
        fit: BoxFit.contain,
        repeat: false,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
          return SiteAnimationFallbackCard(
            userName: widget.command.userName,
            tier: widget.command.tier,
            type: widget.command.type,
            avatarUrl: widget.command.avatarUrl,
          );
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
        fallback: SiteAnimationFallbackCard(
          userName: widget.command.userName,
          tier: widget.command.tier,
          type: widget.command.type,
          avatarUrl: widget.command.avatarUrl,
        ),
      );
    }

    return SiteAnimationFallbackCard(
      userName: widget.command.userName,
      tier: widget.command.tier,
      type: widget.command.type,
      avatarUrl: widget.command.avatarUrl,
    );
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
