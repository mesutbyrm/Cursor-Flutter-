import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_card.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

void main() {
  const goldTier = MembershipTierModel(
    id: MembershipTierId.gold,
    title: 'Gold',
    subtitle: 'Aylık jeton',
    monthlyTokens: 1500,
    monthlyPriceTry: 1000,
    accent: Color(0xFFFFD54F),
    badgeIcon: Icons.star,
    glow: Color(0xFFFFC107),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required MembershipTierModel tier,
    ProfileMembershipInfo? membershipInfo,
    bool selected = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MembershipCard(
            tier: tier,
            selected: selected,
            onTap: () {},
            membershipInfo: membershipInfo,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('MembershipCard badge', () {
    testWidgets('aktif üyelik — Aktif rozeti', (tester) async {
      await pumpCard(
        tester,
        tier: goldTier,
        membershipInfo: const ProfileMembershipInfo(
          raw: 'gold',
          tier: VipTier.gold,
          daysRemaining: 12,
        ),
      );

      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Popüler'), findsNothing);
      expect(find.text('Süresi doldu'), findsNothing);
    });

    testWidgets('popüler tier — Popüler rozeti', (tester) async {
      const popularTier = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Aylık jeton',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFD54F),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
        popular: true,
      );
      await pumpCard(
        tester,
        tier: popularTier,
        membershipInfo: const ProfileMembershipInfo(
          raw: 'basic',
          tier: VipTier.basic,
        ),
      );

      expect(find.text('Popüler'), findsOneWidget);
      expect(find.text('Aktif'), findsNothing);
    });

    testWidgets('süresi dolmuş plan — Süresi doldu rozeti', (tester) async {
      await pumpCard(
        tester,
        tier: goldTier,
        membershipInfo: const ProfileMembershipInfo(
          raw: 'gold',
          tier: VipTier.gold,
          daysRemaining: 0,
        ),
      );

      expect(find.text('Süresi doldu'), findsOneWidget);
      expect(find.text('Aktif'), findsNothing);
    });
  });
}
