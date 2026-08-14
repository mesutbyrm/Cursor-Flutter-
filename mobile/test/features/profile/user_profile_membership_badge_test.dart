import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/presentation/widgets/user_profile_membership_badge.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

void main() {
  group('membershipTierFromVipLevel', () {
    test('boş veya free tier göstermez', () {
      expect(membershipTierFromVipLevel(null), isNull);
      expect(membershipTierFromVipLevel(''), isNull);
      expect(membershipTierFromVipLevel('free'), isNull);
      expect(membershipTierFromVipLevel('basic'), isNull);
    });

    test('ücretli tier döner', () {
      expect(membershipTierFromVipLevel('gold'), VipTier.gold);
      expect(membershipTierFromVipLevel('premium'), VipTier.premium);
      expect(membershipTierFromVipLevel('SVIP'), VipTier.svip);
    });
  });
}
