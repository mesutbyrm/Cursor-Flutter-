import 'package:canlifal_social/core/membership/membership_capabilities.dart';
import 'package:canlifal_social/core/membership/membership_capability_keys.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/providers/vip_membership_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback allows gold ad-free and blocks basic', () {
    final gold = MembershipCapabilities.forTier(VipTier.gold);
    final basic = MembershipCapabilities.forTier(VipTier.basic);
    expect(gold.allows(MembershipCapabilityKeys.adFree), isTrue);
    expect(basic.allows(MembershipCapabilityKeys.adFree), isFalse);
  });

  test('parse API capabilities map', () {
    final cap = MembershipCapabilities.parse({
      'membership': 'premium',
      'capabilities': {
        MembershipCapabilityKeys.profileVisitors: {'enabled': true, 'limit': 50},
      },
    });
    expect(cap.tier, VipTier.premium);
    expect(cap.allows(MembershipCapabilityKeys.profileVisitors), isTrue);
    expect(cap.limitFor(MembershipCapabilityKeys.profileVisitors), 50);
    expect(cap.source, MembershipCapabilitySource.api);
  });

  test('vip rooms fallback requires diamond not gold', () {
    expect(canEnterVipRoom(VipTier.gold), isFalse);
    expect(canEnterVipRoom(VipTier.premium), isFalse);
    expect(canEnterVipRoom(VipTier.diamond), isTrue);
    expect(
      canEnterVipRoomWith(
        MembershipCapabilities.parse({
          'membership': 'gold',
          'capabilities': {
            MembershipCapabilityKeys.vipRooms: {'enabled': true},
          },
        }),
      ),
      isTrue,
    );
  });

  test('svip lounge requires svip tier in fallback', () {
    expect(
      MembershipCapabilities.forTier(VipTier.diamond)
          .allows(MembershipCapabilityKeys.svipLounge),
      isFalse,
    );
    expect(
      MembershipCapabilities.forTier(VipTier.svip)
          .allows(MembershipCapabilityKeys.svipLounge),
      isTrue,
    );
  });
}
