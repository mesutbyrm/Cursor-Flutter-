import 'package:canlifal_social/core/site_animation/domain/site_animation_copy.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_tier.dart';
import 'package:canlifal_social/core/site_animation/domain/site_animation_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gold entrance copy matches design reference', () {
    expect(
      SiteAnimationCopy.subtitle(
        userName: 'Ayşe Yıldız',
        type: SiteAnimationType.memberJoined,
        tier: SiteAnimationTier.gold,
      ),
      'Ayşe Yıldız — Gold üye odaya katıldı',
    );
  });

  test('exit copy varies by tier', () {
    expect(
      SiteAnimationCopy.subtitle(
        userName: 'Mehmet',
        type: SiteAnimationType.memberLeft,
        tier: SiteAnimationTier.gold,
      ),
      'Mehmet — Tekrar bekleriz',
    );
    expect(
      SiteAnimationCopy.subtitle(
        userName: 'Mehmet',
        type: SiteAnimationType.memberLeft,
        tier: SiteAnimationTier.normal,
      ),
      'Mehmet — Güle güle',
    );
  });

  test('host seat copy', () {
    expect(
      SiteAnimationCopy.subtitle(
        userName: 'Host User',
        type: SiteAnimationType.hostSeat,
        tier: SiteAnimationTier.host,
      ),
      'Host User — Host koltuğuna geçti',
    );
  });
}
