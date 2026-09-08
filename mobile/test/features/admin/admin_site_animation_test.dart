import 'package:canlifal_social/features/admin/data/admin_site_animation_seed_catalog.dart';
import 'package:canlifal_social/features/admin/domain/admin_site_animation.dart';
import 'package:canlifal_social/features/admin/domain/admin_site_animation_preview_mapper.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed catalog has at least 12 entrance animations', () {
    final items = AdminSiteAnimationSeedCatalog.all();
    final entrances = items
        .where((a) => a.category == AdminSiteAnimationCategory.entrance)
        .toList();
    expect(entrances.length, greaterThanOrEqualTo(12));
  });

  test('seed catalog has 12 profile frames', () {
    final frames = AdminSiteAnimationSeedCatalog.all()
        .where((a) => a.category == AdminSiteAnimationCategory.profileFrame)
        .toList();
    expect(frames.length, greaterThanOrEqualTo(12));
  });

  test('hub exposes 16 admin categories', () {
    expect(AdminSiteAnimationCategory.hubCategories.length, 16);
  });

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

  test('preview mapper maps gold entrance with lottie asset', () {
    final gold = AdminSiteAnimationSeedCatalog.all().firstWhere(
      (a) => a.id == 'anim_entrance_gold_crown',
    );
    final cmd = adminAnimationToPreviewCommand(gold);
    expect(cmd.type, SiteAnimationType.memberJoined);
    expect(cmd.displayDuration.inMilliseconds, 3000);
    expect(cmd.asset.hasBundle, isTrue);
    expect(cmd.asset.bundlePath, contains('crown.json'));
    expect(cmd.soundUrl, isNull);
    expect(cmd.cooldownMs, 8000);
  });

  test('default entrance ids map tiers per spec', () {
    final defaults = AdminSiteAnimationSeedCatalog.defaultEntranceIds();
    expect(defaults[AdminSiteAnimationMembership.gold], 'anim_entrance_gold_crown');
    expect(
      defaults[AdminSiteAnimationMembership.diamond],
      'anim_entrance_diamond_burst',
    );
    expect(
      defaults[AdminSiteAnimationMembership.premium],
      'anim_entrance_golden_spotlight',
    );
    expect(defaults[AdminSiteAnimationMembership.vip], 'anim_entrance_royal_gate');
    expect(defaults[AdminSiteAnimationMembership.svip], 'anim_entrance_vip_galaxy');
  });
}
