import 'package:canlifal_social/core/site_animation/data/site_animation_profile_resolver.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_slot.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:flutter_test/flutter_test.dart';

SiteAnimationCatalogEntry _frame(String id, SiteAnimationTier tier) {
  return SiteAnimationCatalogEntry(
    id: id,
    name: id,
    category: 'profileFrame',
    tier: tier,
  );
}

void main() {
  test('admin assignment overrides tier default frame', () {
    final catalog = SiteAnimationCatalogSnapshot(
      animations: {
        'anim_frame_gold_crown': _frame('anim_frame_gold_crown', SiteAnimationTier.gold),
        'anim_frame_emperor': _frame('anim_frame_emperor', SiteAnimationTier.svip),
      },
      userAssignments: {
        'u1': {
          SiteAnimationSlot.profileFrame: const SiteAnimationUserAssignment(
            animationId: 'anim_frame_emperor',
          ),
        },
      },
    );

    final resolved = SiteAnimationProfileResolver.resolveFrame(
      userId: 'u1',
      tier: SiteAnimationTier.gold,
      catalog: catalog,
    );
    expect(resolved?.id, 'anim_frame_emperor');
  });

  test('tier match when no assignment', () {
    final catalog = SiteAnimationCatalogSnapshot(
      animations: {
        'anim_frame_gold_crown': _frame('anim_frame_gold_crown', SiteAnimationTier.gold),
        'anim_frame_diamond': _frame('anim_frame_diamond', SiteAnimationTier.diamond),
      },
    );

    final resolved = SiteAnimationProfileResolver.resolveFrame(
      userId: 'u2',
      tier: SiteAnimationTier.diamond,
      catalog: catalog,
    );
    expect(resolved?.id, 'anim_frame_diamond');
  });

  test('expired assignment ignored', () {
    final catalog = SiteAnimationCatalogSnapshot(
      animations: {
        'anim_frame_gold_crown': _frame('anim_frame_gold_crown', SiteAnimationTier.gold),
        'anim_frame_emperor': _frame('anim_frame_emperor', SiteAnimationTier.svip),
      },
      userAssignments: {
        'u3': {
          SiteAnimationSlot.profileFrame: SiteAnimationUserAssignment(
            animationId: 'anim_frame_emperor',
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        },
      },
    );

    final resolved = SiteAnimationProfileResolver.resolveFrame(
      userId: 'u3',
      tier: SiteAnimationTier.gold,
      catalog: catalog,
    );
    expect(resolved?.id, 'anim_frame_gold_crown');
  });
}
