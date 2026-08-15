import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_checkout_footer_hint.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('MembershipCheckoutFooterHint', () {
    testWidgets('seçili plan ipucu görünür', (tester) async {
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
            home: Scaffold(body: MembershipCheckoutFooterHint()),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Gold'), findsOneWidget);
    });
  });
}

class _FixedWalletNotifier extends WalletBalancesNotifier {
  _FixedWalletNotifier(this._wallet);

  final WalletBalances _wallet;

  @override
  Future<WalletBalances> build() async => _wallet;
}

class _StubMembershipController extends MembershipController {
  @override
  MembershipUiState build() => const MembershipUiState();
}
