import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_membership_shortcuts.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  group('ProfileHubMembershipShortcuts', () {
    testWidgets('ücretsiz kullanıcı plan chip katalog ipucu', (tester) async {
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
            home: Scaffold(
              body: ProfileHubMembershipShortcuts(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planlar'), findsOneWidget);
      expect(find.textContaining('öne çıkan'), findsOneWidget);
    });

    testWidgets('aktif ücretli kullanıcı plan ipucu', (tester) async {
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
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(
                const WalletBalances(
                  jeton: 0,
                  cfc: 0,
                  membership: 'gold',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileHubMembershipShortcuts(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planı Yönet'), findsOneWidget);
      expect(find.textContaining('8 gün'), findsOneWidget);
      expect(find.textContaining('VIP odalar aktif'), findsOneWidget);
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
