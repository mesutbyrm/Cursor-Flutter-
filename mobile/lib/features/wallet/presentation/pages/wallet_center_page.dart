import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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
    final premiumSubtitle = membershipInfo.hasActiveSubscription
        ? '${membershipInfo.tierLabel} · ${balances.membershipDaysRemaining ?? membershipInfo.daysRemaining ?? 0} gün'
        : membershipInfo.isExpired
            ? '${membershipInfo.tierLabel} süresi doldu · yenile'
            : 'Basic · Premium · Gold · Diamond · SVIP';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Cüzdanım',
          subtitle: 'Jeton · CFC · Premium üyelik',
          onRefresh: () =>
              ref.read(walletBalancesProvider.notifier).refresh(force: true),
          body: wallet.isLoading && cached == null
              ? const Center(child: DiscoverAccentLoader())
              : wallet.hasError && cached == null
                  ? Center(child: Text(wallet.error.toString()))
                  : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                WalletBalanceHeader(
                  jeton: balances.jeton,
                  cfc: balances.cfc,
                  membership: balances.membership,
                  daysRemaining: balances.membershipDaysRemaining,
                ),
                const SizedBox(height: 20),
                WalletEarningsSection(balances: balances),
                const SizedBox(height: 16),
                _HubCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Para Çek',
                  subtitle: 'Banka havalesi ile çekim talebi',
                  color: const Color(0xFF81C784),
                  onTap: () => context.push('/withdraw'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premium Üyelik',
                  subtitle: premiumSubtitle,
                  color: const Color(0xFFFFD54F),
                  onTap: () => context.push('/premium-membership'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.diamond_rounded,
                  title: 'CFC Yükle',
                  subtitle: 'WhatsApp · Papara · Havale/EFT',
                  color: AppThemeColors.diamondBlue,
                  onTap: () => context.push('/cfc-store'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.monetization_on_rounded,
                  title: 'Jeton Mağazası',
                  subtitle: 'Paketler ve jeton bakiyesi',
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
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                Text(
                  subtitle,
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
