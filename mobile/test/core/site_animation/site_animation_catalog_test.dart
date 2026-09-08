import 'package:canlifal_social/core/site_animation/data/site_animation_resolver.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_catalog_entry.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_slot.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:canlifal_social/core/site_animation/data/site_animation_parser.dart';
import 'package:canlifal_social/features/admin/data/admin_site_animation_seed_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

SiteAnimationCatalogSnapshot _catalog() {
  final items = AdminSiteAnimationSeedCatalog.all();
  return SiteAnimationCatalogSnapshot(
    animations: {for (final a in items) a.id: _entry(a.id, a.name, 'entrance', SiteAnimationTier.gold, isActive: a.isActive)},
    entranceDefaults: {
      SiteAnimationTier.gold: 'anim_entrance_gold_crown',
      SiteAnimationTier.normal: 'anim_entrance_normal',
    },
  );
}

SiteAnimationCatalogEntry _entry(
  String id,
  String name,
  String category,
  SiteAnimationTier tier, {
  bool isActive = true,
  int priority = 70,
  int durationMs = 3000,
}) {
  return SiteAnimationCatalogEntry(
    id: id,
    name: name,
    category: category,
    tier: tier,
    durationMs: durationMs,
    priority: priority,
    isActive: isActive,
  );
}

void main() {
  group('SiteAnimationResolver', () {
    test('applies membership entrance default', () {
      final base = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-1',
          'userId': 'u1',
          'name': 'Altın Üye',
          'membership': 'gold',
        },
      )!;
      final resolved = SiteAnimationResolver.resolve(
        base: base,
        catalog: _catalog(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.layout.durationMs, 3000);
      expect(resolved.priorityOverride, 70);
    });

    test('returns null for passive catalog entry', () {
      final catalog = SiteAnimationCatalogSnapshot(
        animations: {
          'anim_entrance_gold_crown': _entry(
            'anim_entrance_gold_crown',
            'Gold',
            'entrance',
            SiteAnimationTier.gold,
            isActive: false,
          ),
        },
        entranceDefaults: {
          SiteAnimationTier.gold: 'anim_entrance_gold_crown',
        },
      );
      final base = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-passive',
          'userId': 'u1',
          'membership': 'gold',
        },
      )!;
      expect(
        SiteAnimationResolver.resolve(base: base, catalog: catalog),
        isNull,
      );
    });

    test('user assignment overrides membership default', () {
      final catalog = SiteAnimationCatalogSnapshot(
        animations: {
          'anim_entrance_gold_crown': _entry(
            'anim_entrance_gold_crown',
            'Gold default',
            'entrance',
            SiteAnimationTier.gold,
            priority: 70,
          ),
          'anim_entrance_diamond_burst': _entry(
            'anim_entrance_diamond_burst',
            'Diamond custom',
            'entrance',
            SiteAnimationTier.diamond,
            priority: 95,
            durationMs: 4000,
          ),
        },
        entranceDefaults: {
          SiteAnimationTier.gold: 'anim_entrance_gold_crown',
        },
        userAssignments: {
          'vip-user': {
            SiteAnimationSlot.entrance: const SiteAnimationUserAssignment(
              animationId: 'anim_entrance_diamond_burst',
            ),
          },
        },
      );
      final base = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_joined',
        payload: {
          'eventId': 'evt-assign',
          'userId': 'vip-user',
          'membership': 'gold',
        },
      )!;
      final resolved = SiteAnimationResolver.resolve(base: base, catalog: catalog)!;
      expect(resolved.priorityOverride, 95);
      expect(resolved.layout.durationMs, 4000);
      expect(resolved.catalogLabel, 'Diamond custom');
    });

    test('applies exit defaults by tier', () {
      final catalog = SiteAnimationCatalogSnapshot(
        animations: {
          'anim_exit_gold': _entry(
            'anim_exit_gold',
            'Gold exit',
            'exit',
            SiteAnimationTier.gold,
            durationMs: 2000,
            priority: 35,
          ),
        },
        exitDefaults: {
          SiteAnimationTier.gold: 'anim_exit_gold',
        },
      );
      final base = SiteAnimationParser.fromRoomEvent(
        roomId: 'room-1',
        event: 'user_left',
        payload: {
          'eventId': 'evt-exit',
          'userId': 'u1',
          'membership': 'gold',
        },
      )!;
      final resolved = SiteAnimationResolver.resolve(base: base, catalog: catalog)!;
      expect(resolved.layout.durationMs, 2000);
      expect(resolved.priorityOverride, 35);
    });
  });
}
