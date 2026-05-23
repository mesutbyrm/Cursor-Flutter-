import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover/discover_glass_card.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../widgets/wallet_balance_header.dart';

/// Cüzdan merkezi — Jeton, CFC ve Premium üyelik tek giriş.
class WalletCenterPage extends ConsumerWidget {
  const WalletCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletBalancesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Cüzdanım',
          subtitle: 'Jeton · CFC · Premium üyelik',
          onRefresh: () async => ref.invalidate(walletBalancesProvider),
          body: wallet.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (b) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                WalletBalanceHeader(
                  jeton: b.jeton,
                  cfc: b.cfc,
                  membership: b.membership,
                  daysRemaining: b.membershipDaysRemaining,
                ),
                const SizedBox(height: 24),
                _HubCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premium Üyelik',
                  subtitle: 'Basic · Premium · Gold · Diamond',
                  color: const Color(0xFFFFD54F),
                  onTap: () => context.push('/premium-membership'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.diamond_rounded,
                  title: 'CFC Yükle',
                  subtitle: 'WhatsApp · Papara · Havale/EFT',
                  color: AppColors.diamondBlue,
                  onTap: () => context.push('/cfc-store'),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.monetization_on_rounded,
                  title: 'Jeton Mağazası',
                  subtitle: 'Paketler ve jeton bakiyesi',
                  color: AppColors.coinGold,
                  onTap: () => context.push('/jeton-store'),
                ),
              ],
            ),
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
                    color: AppColors.textMuted.withValues(alpha: 0.95),
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
