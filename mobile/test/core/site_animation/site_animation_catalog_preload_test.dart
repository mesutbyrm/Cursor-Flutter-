import 'package:canlifal_social/core/site_animation/data/site_animation_catalog_preload.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('warm completes for empty snapshot', () async {
    await SiteAnimationCatalogPreload.warm(const SiteAnimationCatalogSnapshot());
  });

  test('warm schedules sound and remote CDN asset for entrance', () async {
    const snapshot = SiteAnimationCatalogSnapshot(
      animations: {
        'anim_entrance_gold_crown': SiteAnimationCatalogEntry(
          id: 'anim_entrance_gold_crown',
          name: 'Gold',
          category: 'entrance',
          tier: SiteAnimationTier.gold,
          animationType: 'lottie',
          soundUrl:
              'https://cdn.canlifal.com/animations/sounds/anim_entrance_gold_crown.mp3',
        ),
      },
    );
    await SiteAnimationCatalogPreload.warm(snapshot);
  });
}
