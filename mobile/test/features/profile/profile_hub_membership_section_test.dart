import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

void main() {
  group('ProfileHubMembershipSection logic', () {
    test('ücretsiz kullanıcı banner gösterir', () {
      final info = resolveProfileMembership(rawMembership: 'free');
      expect(info.hasPaidTier, isFalse);
      expect(info.hasActiveSubscription, isFalse);
    });

    test('aktif ücretli kullanıcı premium kart gösterir', () {
      final info = resolveProfileMembership(
        rawMembership: 'gold',
        daysRemaining: 12,
      );
      expect(info.hasActiveSubscription, isTrue);
      expect(info.tierLabel, 'Gold');
    });

    test('süresi dolmuş ücretli kullanıcı premium kart gösterir', () {
      final info = resolveProfileMembership(
        rawMembership: 'gold',
        daysRemaining: 0,
      );
      expect(info.hasPaidTier, isTrue);
      expect(info.hasActiveSubscription, isFalse);
      expect(info.isExpired, isTrue);
      expect(
        info.hasActiveSubscription || info.isExpired,
        isTrue,
      );
    });
  });
}
