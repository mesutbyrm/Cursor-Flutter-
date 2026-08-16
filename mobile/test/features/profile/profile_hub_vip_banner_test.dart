import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_vip_banner.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';

void main() {
  group('ProfileHubVipBanner', () {
    testWidgets('ücretsiz kullanıcı teaser alt başlık', (tester) async {
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
          child: const MaterialApp(
            home: Scaffold(body: ProfileHubVipBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Üyelik Planları'), findsOneWidget);
      expect(find.textContaining('öne çıkan'), findsOneWidget);
      expect(find.text('Planları Gör >'), findsOneWidget);
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
