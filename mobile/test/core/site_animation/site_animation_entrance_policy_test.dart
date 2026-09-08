import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/presentation/site_animation_entrance_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldSkipFullscreenVipEntrance', () {
    test('returns false when catalog empty', () {
      expect(
        shouldSkipFullscreenVipEntrance(
          catalog: const SiteAnimationCatalogSnapshot(),
          hasCosmeticEntrance: false,
        ),
        isFalse,
      );
    });

    test('returns true when entrance defaults exist', () {
      expect(
        shouldSkipFullscreenVipEntrance(
          catalog: const SiteAnimationCatalogSnapshot(
            entranceDefaults: {SiteAnimationTier.gold: 'anim_entrance_gold'},
          ),
          hasCosmeticEntrance: false,
        ),
        isTrue,
      );
    });

    test('returns false when cosmetic entrance active', () {
      expect(
        shouldSkipFullscreenVipEntrance(
          catalog: const SiteAnimationCatalogSnapshot(
            entranceDefaults: {SiteAnimationTier.gold: 'anim_entrance_gold'},
          ),
          hasCosmeticEntrance: true,
        ),
        isFalse,
      );
    });

    test('hasActiveEntranceCatalog detects entrance category', () {
      const catalog = SiteAnimationCatalogSnapshot(
        animations: {
          'a1': SiteAnimationCatalogEntry(
            id: 'a1',
            name: 'Gold',
            category: 'entrance',
            tier: SiteAnimationTier.gold,
          ),
        },
      );
      expect(catalog.hasActiveEntranceCatalog, isTrue);
    });
  });
}
