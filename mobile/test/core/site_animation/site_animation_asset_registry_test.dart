import 'package:canlifal_social/core/site_animation/data/site_animation_asset_registry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_asset.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundle assetUrl from API resolves to local lottie path', () {
    final asset = SiteAnimationAssetRegistry.resolve(
      type: SiteAnimationType.memberJoined,
      tier: SiteAnimationTier.gold,
      backendAsset: const SiteAnimationAsset(
        url: 'assets/gifts/lottie/crown.json',
        kind: SiteAnimationMediaKind.lottie,
      ),
    );
    expect(asset.bundlePath, 'assets/gifts/lottie/crown.json');
    expect(asset.kind, SiteAnimationMediaKind.lottie);
  });

  test('tier fallback bundle without backend asset', () {
    final asset = SiteAnimationAssetRegistry.resolve(
      type: SiteAnimationType.memberJoined,
      tier: SiteAnimationTier.premium,
    );
    expect(asset.bundlePath, 'assets/gifts/lottie/star.json');
  });
}
