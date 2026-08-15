import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_store_teaser_banner.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('MembershipStoreTeaserBanner', () {
    testWidgets('ücretsiz kullanıcı teaser görür', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(WalletBalances.empty),
            ),
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'basic',
                tier: VipTier.basic,
              ),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MembershipStoreTeaserBanner(
                store: MembershipStoreKind.jeton,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Premium Üyelik'), findsOneWidget);
      expect(find.textContaining('jeton yüklerken'), findsOneWidget);
    });

    testWidgets('aktif ücretli kullanıcıda gizlenir', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(WalletBalances.empty),
            ),
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'gold',
                tier: VipTier.gold,
                daysRemaining: 10,
              ),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MembershipStoreTeaserBanner(
                store: MembershipStoreKind.cfc,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MembershipStoreTeaserBanner), findsOneWidget);
      expect(find.text('Premium Üyelik'), findsNothing);
    });
  });
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() {
    return const MembershipUiState(
      apiPackages: [
        MembershipPackageEntity(
          id: 'gold',
          planId: 'p1',
          title: 'Gold',
          durationDays: 30,
          priceJeton: 2000,
          bonusJeton: 1500,
          falDiscountPercent: 10,
          popular: true,
        ),
      ],
    );
  }
}

class _FixedWalletNotifier extends WalletBalancesNotifier {
  _FixedWalletNotifier(this._wallet);

  final WalletBalances _wallet;

  @override
  Future<WalletBalances> build() async => _wallet;
}
