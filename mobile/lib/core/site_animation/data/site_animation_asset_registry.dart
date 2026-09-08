import '../domain/site_animation_asset.dart';
import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';

/// Tier / tür → asset eşlemesi. MP4 anahtarları preview; production native/Lottie fallback.
abstract final class SiteAnimationAssetRegistry {
  static const _previewBase = 'site_animation_preview';

  static SiteAnimationAsset resolve({
    required SiteAnimationType type,
    required SiteAnimationTier tier,
    SiteAnimationAsset? backendAsset,
  }) {
    if (backendAsset != null && backendAsset.isPlayable) {
      return backendAsset;
    }

    final previewKey = _previewKey(type, tier);
    final bundle = _bundlePath(type, tier);

    return SiteAnimationAsset(
      url: backendAsset?.url,
      bundlePath: bundle,
      kind: bundle != null
          ? SiteAnimationMediaKind.lottie
          : SiteAnimationMediaKind.native,
      previewMp4Key: previewKey,
    );
  }

  static String? _previewKey(SiteAnimationType type, SiteAnimationTier tier) {
    return switch (type) {
      SiteAnimationType.memberJoined || SiteAnimationType.hostSeat =>
        switch (tier) {
          SiteAnimationTier.admin => 'admin_girisi.mp4',
          SiteAnimationTier.diamond => 'diamond_uye_girisi.mp4',
          SiteAnimationTier.premium => 'premium_uye_girisi.mp4',
          SiteAnimationTier.gold => 'gold_uye_girisi.mp4',
          SiteAnimationTier.host => 'host_koltugu.mp4',
          _ => null,
        },
      SiteAnimationType.micEnabled => 'mikrofon_acma.mp4',
      SiteAnimationType.micDisabled => 'mikrofon_kapatma.mp4',
      SiteAnimationType.seatRankGlow when tier == SiteAnimationTier.host =>
        'host_koltugu.mp4',
      _ => null,
    };
  }

  static String? _bundlePath(SiteAnimationType type, SiteAnimationTier tier) {
    if (type == SiteAnimationType.memberJoined ||
        type == SiteAnimationType.hostSeat) {
      return switch (tier) {
        SiteAnimationTier.diamond ||
        SiteAnimationTier.svip =>
          'assets/gifts/lottie/crown.json',
        SiteAnimationTier.premium => 'assets/gifts/lottie/star.json',
        SiteAnimationTier.gold => 'assets/gifts/lottie/heart.json',
        SiteAnimationTier.admin => 'assets/gifts/lottie/car.json',
        _ => null,
      };
    }
    if (type == SiteAnimationType.micEnabled) {
      return 'assets/gifts/lottie/star.json';
    }
    if (type == SiteAnimationType.micDisabled) {
      return null;
    }
    return null;
  }
}
