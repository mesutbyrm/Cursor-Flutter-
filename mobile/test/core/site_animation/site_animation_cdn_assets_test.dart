import 'package:canlifal_social/core/site_animation/data/site_animation_cdn_assets.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveAssetUrl keeps bundle path', () {
    const entry = SiteAnimationCatalogEntry(
      id: 'anim_entrance_gold_crown',
      name: 'Gold',
      category: 'entrance',
      tier: SiteAnimationTier.gold,
      animationType: 'lottie',
      assetUrl: 'assets/gifts/lottie/crown.json',
    );
    expect(
      SiteAnimationCdnAssets.resolveAssetUrl(entry),
      'assets/gifts/lottie/crown.json',
    );
  });

  test('resolveAssetUrl falls back to CDN production lottie', () {
    const entry = SiteAnimationCatalogEntry(
      id: 'anim_entrance_diamond_burst',
      name: 'Diamond',
      category: 'entrance',
      tier: SiteAnimationTier.diamond,
      animationType: 'lottie',
    );
    expect(
      SiteAnimationCdnAssets.resolveAssetUrl(entry),
      'https://cdn.canlifal.com/animations/production/anim_entrance_diamond_burst.lottie',
    );
  });

  test('runtimeAsset uses bundle path for packaged lottie', () {
    const entry = SiteAnimationCatalogEntry(
      id: 'anim_entrance_gold_crown',
      name: 'Gold',
      category: 'entrance',
      tier: SiteAnimationTier.gold,
      animationType: 'lottie',
      assetUrl: 'assets/gifts/lottie/crown.json',
    );
    final asset = SiteAnimationCdnAssets.runtimeAsset(entry)!;
    expect(asset.bundlePath, contains('crown.json'));
    expect(asset.hasRemote, isFalse);
  });

  test('runtimeAsset uses CDN url when assetUrl empty', () {
    const entry = SiteAnimationCatalogEntry(
      id: 'anim_exit_gold',
      name: 'Exit',
      category: 'exit',
      tier: SiteAnimationTier.gold,
      animationType: 'lottie',
    );
    final asset = SiteAnimationCdnAssets.runtimeAsset(entry)!;
    expect(asset.url, contains('production/anim_exit_gold.lottie'));
    expect(asset.hasRemote, isTrue);
  });
}
