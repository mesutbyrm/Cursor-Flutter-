import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/site_animation_asset.dart';
import '../../domain/site_animation_catalog_entry.dart';
import '../../domain/site_animation_tier.dart';
import '../../domain/site_animation_type.dart';
import '../../data/site_animation_asset_registry.dart';
import 'site_animation_profile_frame_fallback.dart';

/// Animasyonlu profil çerçevesi — avatar boyutu/konumu korunur.
class SiteAnimationFramedAvatar extends StatelessWidget {
  const SiteAnimationFramedAvatar({
    super.key,
    required this.entry,
    required this.child,
    this.size = 92,
  });

  final SiteAnimationCatalogEntry entry;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final backend = entry.assetUrl != null && entry.assetUrl!.isNotEmpty
        ? SiteAnimationAsset(
            bundlePath: entry.assetUrl!.startsWith('assets/')
                ? entry.assetUrl
                : null,
            url: entry.assetUrl!.startsWith('assets/') ? null : entry.assetUrl,
            kind: entry.assetUrl!.endsWith('.json')
                ? SiteAnimationMediaKind.lottie
                : SiteAnimationMediaKind.native,
            previewMp4Key: entry.previewMp4Key,
          )
        : null;

    final asset = SiteAnimationAssetRegistry.resolve(
      type: SiteAnimationType.memberJoined,
      tier: entry.tier,
      backendAsset: backend,
    );

    final innerPad = size * 0.14;
    final Widget frame;
    if (asset.hasBundle) {
      frame = Lottie.asset(
        asset.bundlePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (_, __, ___) => SiteAnimationProfileFrameFallback(
          tier: entry.tier,
          size: size,
          animationId: entry.id,
        ),
      );
    } else {
      frame = SiteAnimationProfileFrameFallback(
        tier: entry.tier,
        size: size,
        animationId: entry.id,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: frame),
          Padding(
            padding: EdgeInsets.all(innerPad),
            child: ClipOval(child: child),
          ),
        ],
      ),
    );
  }
}
