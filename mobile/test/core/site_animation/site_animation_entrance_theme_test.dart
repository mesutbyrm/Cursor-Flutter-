import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/presentation/widgets/site_animation_entrance_theme.dart';
import 'package:canlifal_social/features/admin/data/admin_site_animation_seed_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every seeded entrance id has a design theme', () {
    final entrances = AdminSiteAnimationSeedCatalog.all()
        .where((a) => a.id.startsWith('anim_entrance_'))
        .map((a) => a.id)
        .toSet();
    for (final id in entrances) {
      final theme = SiteAnimationEntranceTheme.resolve(
        animationId: id,
        tier: SiteAnimationTier.normal,
      );
      expect(theme.animationId, id);
      expect(theme.gradient, isNotEmpty);
    }
    expect(entrances.length, greaterThanOrEqualTo(12));
  });

  test('host crown theme exists', () {
    final theme = SiteAnimationEntranceTheme.resolve(
      animationId: 'anim_host_seat_crown',
      tier: SiteAnimationTier.host,
    );
    expect(theme.badge, 'HOST');
  });
}
