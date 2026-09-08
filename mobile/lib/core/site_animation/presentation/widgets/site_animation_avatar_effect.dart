import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/site_animation_asset.dart';
import '../../domain/site_animation_catalog_entry.dart';
import '../../domain/site_animation_type.dart';
import '../../data/site_animation_asset_registry.dart';
import 'site_animation_profile_frame_fallback.dart';

/// Profil avatarı etrafında site animasyon parçacık halkası.
class SiteAnimationAvatarEffectOverlay extends StatelessWidget {
  const SiteAnimationAvatarEffectOverlay({
    super.key,
    required this.entry,
    this.size = 92,
  });

  final SiteAnimationCatalogEntry entry;
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

    if (asset.hasBundle) {
      return IgnorePointer(
        child: Lottie.asset(
          asset.bundlePath!,
          width: size * 1.18,
          height: size * 1.18,
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (_, __, ___) => SiteAnimationProfileFrameFallback(
            tier: entry.tier,
            size: size * 1.12,
          ),
        ),
      );
    }

    return IgnorePointer(
      child: SiteAnimationProfileFrameFallback(
        tier: entry.tier,
        size: size * 1.12,
      ),
    );
  }
}
