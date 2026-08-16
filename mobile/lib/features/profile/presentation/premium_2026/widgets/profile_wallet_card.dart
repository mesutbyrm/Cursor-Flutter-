import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../membership/presentation/controllers/membership_controller.dart';
import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../membership/presentation/widgets/membership_pending_payment_banner.dart';
import '../../widgets/payment_methods_summary_line.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_membership_helpers.dart';
import '../profile_screen_state.dart';
import '../profile_theme.dart';
import 'profile_action_tile.dart';

/// Cüzdan — tek kart + alt aksiyonlar.
class ProfileWalletCard extends ConsumerWidget {
  const ProfileWalletCard({
    super.key,
    required this.state,
    this.cfcLoading = false,
    this.onTopUp,
    this.onCfcTopUp,
    this.onEarnings,
    this.onTransactions,
    this.onPaymentNotice,
    this.onSubscriptions,
  });

  final ProfileScreenState state;
  final bool cfcLoading;
  final VoidCallback? onTopUp;
  final VoidCallback? onCfcTopUp;
  final VoidCallback? onEarnings;
  final VoidCallback? onTransactions;
  final VoidCallback? onPaymentNotice;
  final VoidCallback? onSubscriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = resolveProfileMembership(
      rawMembership: state.wallet?.membership ?? state.membership,
      daysRemaining: state.membershipDays,
    );
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final subscriptionLabel = buildMembershipWalletSubscriptionStatLabel(
      info: info,
      catalogTier: catalogTier,
      daysRemaining: state.membershipDays,
      expiresAt: state.wallet?.membershipExpiresAt,
    );
    final premiumStatLabel = buildMembershipWalletPremiumStatLabel(info: info);
    final subscriptionsTileLabel =
        buildMembershipWalletSubscriptionsTileLabel(info: info);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          const MembershipPendingPaymentBanner(padding: EdgeInsets.only(bottom: 12)),
          const ProfileSectionTitle(title: 'Cüzdan'),
          ProfileGlass(
            padding: const EdgeInsets.all(20),
            borderRadius: ProfilePremiumTheme.radiusLg,
            borderColor: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BalanceBlock(
                        label: 'Jeton',
                        value: profileFormatCount(state.jeton),
                        icon: Icons.monetization_on_rounded,
                        color: AppThemeColors.coinGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceBlock(
                        label: 'CFC',
                        value: profileFormatCount(state.cfc),
                        icon: Icons.diamond_rounded,
                        color: AppThemeColors.diamondBlue,
                        isLoading: cfcLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Toplam kazanç',
                        value: '${profileFormatCount(state.totalEarnings)} J',
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Bugünkü kazanç',
                        value: '0 J',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Premium',
                        value: premiumStatLabel,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Abonelik',
                        value: subscriptionLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              const cols = 2;
              final tileW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              final tileH = tileW / 2.4;
              final tiles = <Widget>[
                ProfileActionTile(
                  icon: Icons.add_card_rounded,
                  label: 'Jeton Yükle',
                  onTap: onTopUp,
                  gradient: [const Color(0xFF4A3818), const Color(0xFF1A1408)],
                ),
                ProfileActionTile(
                  icon: Icons.diamond_outlined,
                  label: 'CFC Yükle',
                  onTap: onCfcTopUp,
                  gradient: [const Color(0xFF183050), const Color(0xFF081018)],
                ),
                ProfileActionTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Kazançlar',
                  onTap: onEarnings,
                  gradient: [const Color(0xFF1A3040), const Color(0xFF081018)],
                ),
                ProfileActionTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'İşlem Geçmişi',
                  onTap: onTransactions,
                  gradient: [const Color(0xFF281838), const Color(0xFF100818)],
                ),
                ProfileActionTile(
                  icon: Icons.payment_rounded,
                  label: 'Ödeme Bildirimi',
                  onTap: onPaymentNotice,
                  gradient: [const Color(0xFF301828), const Color(0xFF140810)],
                ),
                ProfileActionTile(
                  icon: Icons.workspace_premium_rounded,
                  label: subscriptionsTileLabel,
                  onTap: onSubscriptions,
                  gradient: [const Color(0xFF3A3010), const Color(0xFF181008)],
                ),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: tileW,
                      height: tileH,
                      child: tile,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const PaymentMethodsSummaryLine(
            prefix: 'Ödeme kanalları',
            fontSize: 10,
            textAlign: TextAlign.start,
            showRecommended: false,
          ),
        ],
    );
  }
}

class _BalanceBlock extends StatelessWidget {
  const _BalanceBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ProfilePremiumTheme.glassDecoration(border: color.withValues(alpha: 0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            isLoading ? '…' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: isLoading ? 0.45 : 1),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
