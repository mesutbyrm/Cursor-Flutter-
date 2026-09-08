import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/site_animation/data/site_animation_resolver.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_layout.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';

void main() {
  test('resolveGiftHighlight picks gift category by jeton tier', () {
    final catalog = SiteAnimationCatalogSnapshot(
      animations: {
        'gift_gold': SiteAnimationCatalogEntry(
          id: 'gift_gold',
          name: 'Gold Gift Burst',
          category: 'gift',
          tier: SiteAnimationTier.gold,
          isActive: true,
          anchor: SiteAnimationAnchor.topCenter,
          durationMs: 2500,
        ),
        'gift_vip': SiteAnimationCatalogEntry(
          id: 'anim_gift_vip_royal',
          name: 'VIP Royal Gift',
          category: 'gift',
          tier: SiteAnimationTier.vip,
          isActive: true,
          anchor: SiteAnimationAnchor.topCenter,
          durationMs: 3000,
        ),
      },
    );

    final cmd = SiteAnimationResolver.resolveGiftHighlight(
      eventId: 'gift-1',
      senderName: 'Ayşe',
      senderId: 'u1',
      jetonAmount: 12000,
      catalog: catalog,
    );

    expect(cmd, isNotNull);
    expect(cmd!.userName, 'Ayşe');
    expect(cmd.catalogLabel, 'VIP Royal Gift');
    expect(cmd.layout.anchor, SiteAnimationAnchor.topCenter);
  });

  test('resolveGiftHighlight returns null below threshold', () {
    final cmd = SiteAnimationResolver.resolveGiftHighlight(
      eventId: 'gift-small',
      senderName: 'Ali',
      senderId: 'u2',
      jetonAmount: 500,
      catalog: const SiteAnimationCatalogSnapshot(),
    );
    expect(cmd, isNull);
  });
}
