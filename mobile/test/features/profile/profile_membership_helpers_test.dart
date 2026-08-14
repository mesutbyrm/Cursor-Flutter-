import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_screen_builder.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_screen_state.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('resolveProfileMembership', () {
    test('free ve basic ücretli sayılmaz', () {
      expect(resolveProfileMembership(rawMembership: 'free').hasPaidTier, isFalse);
      expect(resolveProfileMembership(rawMembership: 'basic').hasPaidTier, isFalse);
      expect(resolveProfileMembership(rawMembership: null).hasPaidTier, isFalse);
    });

    test('gold VIP sayılır', () {
      final info = resolveProfileMembership(rawMembership: 'gold');
      expect(info.hasPaidTier, isTrue);
      expect(info.isVip, isTrue);
      expect(info.tierLabel, 'Gold');
    });

    test('premium ücretli ama VIP değil', () {
      final info = resolveProfileMembership(rawMembership: 'premium');
      expect(info.hasPaidTier, isTrue);
      expect(info.isVip, isFalse);
    });

    test('hasPaidMembershipRaw kısayolu', () {
      expect(hasPaidMembershipRaw('free'), isFalse);
      expect(hasPaidMembershipRaw('diamond'), isTrue);
    });

    test('hasActiveSubscription süre dolmuşsa false', () {
      final info = resolveProfileMembership(
        rawMembership: 'gold',
        daysRemaining: 0,
      );
      expect(info.hasPaidTier, isTrue);
      expect(info.hasActiveSubscription, isFalse);
    });
  });

  group('buildProfileWalletState', () {
    const user = UserEntity(
      id: 'u1',
      username: 'test',
      displayName: 'Test',
    );
    final base = ProfileScreenState(user: user);

    test('free üyelik isVip false ve membership null', () {
      const wallet = WalletBalances(membership: 'free');
      final state = buildProfileWalletState(base, wallet);
      expect(state.isVip, isFalse);
      expect(state.membership, isNull);
    });

    test('gold üyelik isVip true', () {
      const wallet = WalletBalances(
        membership: 'gold',
        membershipExpiresAt: '2030-01-01T00:00:00.000Z',
      );
      final state = buildProfileWalletState(base, wallet);
      expect(state.isVip, isTrue);
      expect(state.membership, 'Gold');
    });
  });
}
