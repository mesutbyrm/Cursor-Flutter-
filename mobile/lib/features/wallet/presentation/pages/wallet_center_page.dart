import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../membership/presentation/controllers/membership_controller.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/providers/payment_requests_notifier.dart';
import '../../../profile/presentation/widgets/payment_methods_summary_line.dart';
import '../../../membership/presentation/widgets/membership_pending_payment_banner.dart';
import '../widgets/wallet_balance_header.dart';
import '../widgets/wallet_earnings_section.dart';
import '../../domain/wallet_balances.dart';

/// Cüzdan merkezi — Jeton, CFC ve Premium üyelik tek giriş.
class WalletCenterPage extends ConsumerWidget {
  const WalletCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletBalancesProvider);
    final authUser = ref.watch(authControllerProvider).valueOrNull;
    final cached = wallet.valueOrNull;
    final balances = cached ??
        WalletBalances(jeton: authUser?.coinBalance ?? 0);
    final membershipInfo = resolveProfileMembership(
      rawMembership: balances.membership,
      daysRemaining: balances.membershipDaysRemaining,
    );
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(membershipInfo, ui.tiers);
    final premiumTitle = buildMembershipPremiumCardTitle(
      info: membershipInfo,
      expiresAt: balances.membershipExpiresAt,
    );
    final premiumSubtitle = buildMembershipWalletHubSubtitle(
      info: membershipInfo,
      tiers: ui.tiers,
      packages: ui.apiPackages,
      catalogTier: catalogTier,
      daysRemaining: balances.membershipDaysRemaining,
      expiresAt: balances.membershipExpiresAt,
    );
    final pageSubtitle =
        buildMembershipWalletCenterPageSubtitle(info: membershipInfo);
    final jetonHubSubtitle = buildMembershipWalletStoreHubCardSubtitle(
      info: membershipInfo,
      store: MembershipStoreKind.jeton,
      catalogTier: catalogTier,
    );
    final cfcHubSubtitle = buildMembershipWalletStoreHubCardSubtitle(
      info: membershipInfo,
      store: MembershipStoreKind.cfc,
      catalogTier: catalogTier,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Cüzdanım',
          subtitle: pageSubtitle,
          onRefresh: () =>
              ref.read(walletBalancesProvider.notifier).refresh(force: true),
          body: wallet.isLoading && cached == null
              ? const Center(child: DiscoverAccentLoader())
              : wallet.hasError && cached == null
                  ? Center(child: Text(wallet.error.toString()))
                  : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const MembershipPendingPaymentBanner(),
                WalletBalanceHeader(
                  jeton: balances.jeton,
                  cfc: balances.cfc,
                  membership: balances.membership,
                  daysRemaining: balances.membershipDaysRemaining,
                  membershipExpiresAt: balances.membershipExpiresAt,
                ),
                const SizedBox(height: 20),
                WalletEarningsSection(balances: balances),
                const SizedBox(height: 16),
                _HubCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Para Çek',
                  subtitle: buildMembershipWithdrawalPageSubtitle(
                    info: membershipInfo,
                  ),
                  color: const Color(0xFF81C784),
                  onTap: () => context.push('/withdraw'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.workspace_premium_rounded,
                  title: premiumTitle,
                  subtitle: premiumSubtitle,
                  color: const Color(0xFFFFD54F),
                  onTap: () => context.push('/premium-membership'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.diamond_rounded,
                  title: 'CFC Yükle',
                  subtitleWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfcHubSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const PaymentMethodsSummaryLine(
                        prefix: '',
                        fontSize: 12,
                        textAlign: TextAlign.start,
                        showRecommended: false,
                      ),
                    ],
                  ),
                  color: AppThemeColors.diamondBlue,
                  onTap: () => context.push('/cfc-store'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.monetization_on_rounded,
                  title: 'Jeton Mağazası',
                  subtitle: jetonHubSubtitle,
                  color: AppThemeColors.coinGold,
                  onTap: () => context.push('/jeton-store'),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.subtitleWidget,
  }) : assert(subtitle != null || subtitleWidget != null);

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DiscoverGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                subtitleWidget ??
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                      ),
                    ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.9)),
        ],
      ),
    );
  }
}
