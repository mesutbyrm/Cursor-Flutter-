import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/site_animation/presentation/site_animation_social_bridge.dart';

void main() {
  test('parseSocialEntranceDisplayName strips role prefix', () {
    expect(
      parseSocialEntranceDisplayNameForTest(
        '📣 GOLD Ayşe Yıldız sosyal paylaşımlara giriş yaptı.',
      ),
      'Ayşe Yıldız',
    );
  });

  test('membershipFromSocialBanner detects VIP tier', () {
    expect(
      membershipFromSocialBannerForTest('📣 VIP Mehmet odaya katıldı'),
      'vip',
    );
  });
}
