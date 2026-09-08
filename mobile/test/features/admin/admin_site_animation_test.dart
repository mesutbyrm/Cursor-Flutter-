import 'package:canlifal_social/features/admin/data/admin_site_animation_seed_catalog.dart';
import 'package:canlifal_social/features/admin/domain/admin_site_animation.dart';
import 'package:canlifal_social/features/admin/domain/admin_site_animation_preview_mapper.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed catalog covers entrance tiers from design refs', () {
    final items = AdminSiteAnimationSeedCatalog.all();
    expect(items.length, greaterThan(20));

    final entrances = items
        .where((a) => a.category == AdminSiteAnimationCategory.entrance)
        .toList();
    expect(entrances.any((a) => a.membership == AdminSiteAnimationMembership.gold),
        isTrue);
    expect(
      entrances.any((a) => a.membership == AdminSiteAnimationMembership.diamond),
      isTrue,
    );
    expect(
      entrances.any((a) => a.membership == AdminSiteAnimationMembership.admin),
      isTrue,
    );
  });

  test('stats computed from seed list', () {
    final stats = AdminSiteAnimationStats.fromList(
      AdminSiteAnimationSeedCatalog.all(),
    );
    expect(stats.total, greaterThan(0));
    expect(stats.active, stats.total);
    expect(stats.entrance, greaterThan(0));
  });

  test('preview mapper maps gold entrance', () {
    final gold = AdminSiteAnimationSeedCatalog.all().firstWhere(
      (a) => a.id == 'anim_entrance_gold_crown',
    );
    final cmd = adminAnimationToPreviewCommand(gold);
    expect(cmd.type, SiteAnimationType.memberJoined);
    expect(cmd.displayDuration.inMilliseconds, 3000);
  });

  test('default entrance ids map tiers', () {
    final defaults = AdminSiteAnimationSeedCatalog.defaultEntranceIds();
    expect(defaults[AdminSiteAnimationMembership.gold], 'anim_entrance_gold_crown');
    expect(
      defaults[AdminSiteAnimationMembership.diamond],
      'anim_entrance_diamond_burst',
    );
  });
}
