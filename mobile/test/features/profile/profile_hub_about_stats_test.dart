import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/membership/presentation/controllers/membership_controller.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/membership_status_pill.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_extended_entity.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_about_stats_row.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';

void main() {
  const user = UserEntity(id: 'u1', username: 'tester');
  const stats = ProfileStatsEntity();

  group('ProfileHubAboutStatsRow expired pill', () {
    testWidgets('süresi dolmuş üyelik pill görünür', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletBalancesProvider.overrideWith(
              () => _FixedWalletNotifier(
                const WalletBalances(
                  membership: 'gold',
                  membershipExpiresAt: '2020-05-10T00:00:00.000Z',
                ),
              ),
            ),
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'gold',
                tier: VipTier.gold,
                daysRemaining: 0,
              ),
            ),
            membershipControllerProvider.overrideWith(_StubMembershipController.new),
            profileExtendedProvider.overrideWith(
              (ref) async => const ProfileExtendedEntity(),
            ),
            profileUserStatisticsProvider.overrideWith(
              (ref) async => const ProfileUserStatisticsEntity(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileHubAboutStatsRow(user: user, stats: stats),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MembershipStatusPill), findsOneWidget);
      expect(find.text('Gold · 10.05.2020'), findsWidgets);
    });

    testWidgets('ücretsiz kullanıcı istatistik alt başlığı', (tester) async {
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
            profileExtendedProvider.overrideWith(
              (ref) async => const ProfileExtendedEntity(),
            ),
            profileUserStatisticsProvider.overrideWith(
              (ref) async => const ProfileUserStatisticsEntity(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileHubAboutStatsRow(user: user, stats: stats),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('yükseltin'), findsOneWidget);
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
