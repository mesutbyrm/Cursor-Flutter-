import '../domain/site_animation_asset.dart';
import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';

/// Tier / tür → asset eşlemesi. MP4 anahtarları preview; production Lottie/native fallback.
abstract final class SiteAnimationAssetRegistry {
  static SiteAnimationAsset resolve({
    required SiteAnimationType type,
    required SiteAnimationTier tier,
    SiteAnimationAsset? backendAsset,
  }) {
    final normalized = _normalizeBackendAsset(backendAsset);
    if (normalized != null && normalized.isPlayable) {
      return normalized;
    }

    final previewKey = _previewKey(type, tier);
    if (type.isEntrance || type == SiteAnimationType.hostSeat) {
      return SiteAnimationAsset(
        kind: SiteAnimationMediaKind.native,
        previewMp4Key: previewKey ?? normalized?.previewMp4Key,
      );
    }

    final bundle = _bundlePath(type, tier);

    return SiteAnimationAsset(
      url: normalized?.url,
      bundlePath: bundle,
      kind: bundle != null
          ? SiteAnimationMediaKind.lottie
          : SiteAnimationMediaKind.native,
      previewMp4Key: previewKey ?? normalized?.previewMp4Key,
    );
  }

  static SiteAnimationAsset? _normalizeBackendAsset(SiteAnimationAsset? asset) {
    if (asset == null) return null;
    final raw = asset.url?.trim();
    if (raw == null || raw.isEmpty) {
      return asset.hasBundle ? asset : null;
    }
    if (raw.startsWith('assets/')) {
      return SiteAnimationAsset(
        bundlePath: raw,
        kind: SiteAnimationMediaKind.lottie,
        previewMp4Key: asset.previewMp4Key,
      );
    }
    return asset;
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
        SiteAnimationTier.diamond || SiteAnimationTier.svip =>
          'assets/gifts/lottie/crown.json',
        SiteAnimationTier.premium => 'assets/gifts/lottie/star.json',
        SiteAnimationTier.gold => 'assets/gifts/lottie/heart.json',
        SiteAnimationTier.vip => 'assets/gifts/lottie/rose.json',
        SiteAnimationTier.admin => 'assets/gifts/lottie/car.json',
        SiteAnimationTier.host => 'assets/gifts/lottie/crown.json',
        _ => null,
      };
    }
    if (type == SiteAnimationType.memberLeft) {
      return switch (tier) {
        SiteAnimationTier.gold => 'assets/gifts/lottie/heart.json',
        SiteAnimationTier.premium => 'assets/gifts/lottie/star.json',
        SiteAnimationTier.diamond || SiteAnimationTier.svip =>
          'assets/gifts/lottie/crown.json',
        SiteAnimationTier.vip => 'assets/gifts/lottie/rose.json',
        _ => null,
      };
    }
    if (type == SiteAnimationType.micEnabled) {
      return 'assets/gifts/lottie/star.json';
    }
    if (type == SiteAnimationType.seatRankGlow ||
        type == SiteAnimationType.seatChanged) {
      return switch (tier) {
        SiteAnimationTier.gold => 'assets/gifts/lottie/heart.json',
        SiteAnimationTier.premium => 'assets/gifts/lottie/star.json',
        SiteAnimationTier.diamond || SiteAnimationTier.svip =>
          'assets/gifts/lottie/crown.json',
        SiteAnimationTier.vip => 'assets/gifts/lottie/rose.json',
        SiteAnimationTier.admin || SiteAnimationTier.host =>
          'assets/gifts/lottie/crown.json',
        _ => null,
      };
    }
    return null;
  }
}
