import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_screen_state.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_premium_card.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_membership_section.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_vip_banner.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  const user = UserEntity(id: 'u1', username: 'tester');

  ProfileScreenState baseState() {
    return const ProfileScreenState(user: user);
  }

  group('ProfileHubMembershipSection widget', () {
    testWidgets('ücretsiz kullanıcı banner görür', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'basic',
                tier: VipTier.basic,
              ),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(WalletBalances.empty),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileHubMembershipSection(state: baseState()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileHubVipBanner), findsOneWidget);
      expect(find.text('Üyelik Planları'), findsOneWidget);
      expect(find.byType(ProfilePremiumCard), findsNothing);
    });

    testWidgets('aktif ücretli kullanıcı premium kart görür', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'gold',
                tier: VipTier.gold,
                daysRemaining: 12,
              ),
            ),
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(WalletBalances.empty),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileHubMembershipSection(state: baseState()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ProfileHubVipBanner), findsNothing);
      expect(find.byType(ProfilePremiumCard), findsOneWidget);
      expect(find.text('Gold Üyelik'), findsOneWidget);
    });

    testWidgets('süresi dolmuş ücretli kullanıcı premium kart görür', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'gold',
                tier: VipTier.gold,
                daysRemaining: 0,
              ),
            ),
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(WalletBalances.empty),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProfileHubMembershipSection(state: baseState()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ProfileHubVipBanner), findsNothing);
      expect(find.byType(ProfilePremiumCard), findsOneWidget);
      expect(find.text('Gold · süresi doldu'), findsOneWidget);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}

class _FixedWalletNotifier extends WalletBalancesNotifier {
  _FixedWalletNotifier(this._wallet);

  final WalletBalances _wallet;

  @override
  Future<WalletBalances> build() async => _wallet;
}
