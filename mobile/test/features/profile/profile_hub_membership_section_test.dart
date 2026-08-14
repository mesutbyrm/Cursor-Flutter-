import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';

void main() {
  group('ProfileHubMembershipSection logic', () {
    test('ücretsiz kullanıcı banner gösterir', () {
      final info = resolveProfileMembership(rawMembership: 'free');
      expect(info.hasPaidTier, isFalse);
    });

    test('ücretli kullanıcı lazy premium kart gösterir', () {
      final info = resolveProfileMembership(
        rawMembership: 'gold',
        daysRemaining: 12,
      );
      expect(info.hasPaidTier, isTrue);
      expect(info.tierLabel, 'Gold');
    });
  });
}
