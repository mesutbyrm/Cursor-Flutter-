import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_payment_methods_summary.dart';
import 'package:canlifal_social/features/profile/domain/entities/payment_method_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_membership_manage_tile.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('ProfileMembershipManageTile', () {
    testWidgets('aktif gold katalog ipuçları', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'gold',
                tier: VipTier.gold,
                daysRemaining: 8,
              ),
            ),
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(
                const WalletBalances(
                  membership: 'gold',
                  membershipExpiresAt: '2030-01-01T00:00:00.000Z',
                ),
              ),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileMembershipManageTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gold Üyelik'), findsOneWidget);
      expect(find.textContaining('Gold ·'), findsOneWidget);
      expect(find.textContaining('8'), findsOneWidget);
    });

    testWidgets('süresi dolmuş plan yenile CTA', (tester) async {
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
          child: const MaterialApp(
            home: Scaffold(body: ProfileMembershipManageTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gold · süresi doldu'), findsOneWidget);
      expect(find.textContaining('sona erdi'), findsOneWidget);
    });
  });

  group('MembershipPaymentMethodsSummary', () {
    testWidgets('önerilen kanal ipucu göstermez', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodsProvider.overrideWith(
              (ref) async => const [
                PaymentMethodEntity(
                  id: 'whatsapp',
                  label: 'WhatsApp',
                  recommended: true,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MembershipPaymentMethodsSummary()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('önerilen:'), findsNothing);
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
