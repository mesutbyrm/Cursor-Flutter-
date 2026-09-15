import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tier ladder Basic < Gold < Premium < Diamond < SVIP', () {
    expect(VipTier.basic.isAtLeast(VipTier.gold), isFalse);
    expect(VipTier.gold.isAtLeast(VipTier.premium), isFalse);
    expect(VipTier.premium.isAtLeast(VipTier.gold), isTrue);
    expect(VipTier.diamond.isAtLeast(VipTier.premium), isTrue);
    expect(VipTier.svip.isAtLeast(VipTier.diamond), isTrue);
  });

  test('fromMembership resolves five tiers', () {
    expect(VipTier.fromMembership('gold'), VipTier.gold);
    expect(VipTier.fromMembership('premium'), VipTier.premium);
    expect(VipTier.fromMembership('diamond'), VipTier.diamond);
    expect(VipTier.fromMembership('svip'), VipTier.svip);
  });
}
