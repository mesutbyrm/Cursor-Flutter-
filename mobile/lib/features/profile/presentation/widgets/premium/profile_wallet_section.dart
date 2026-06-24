import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/dual_balance_chips.dart';
import 'profile_glass.dart';

class ProfileWalletSection extends StatelessWidget {
  const ProfileWalletSection({
    super.key,
    required this.jeton,
    required this.cfc,
    this.onTopUp,
    this.onCfcTopUp,
    this.onEarnings,
    this.onTransactions,
    this.onPaymentNotice,
    this.onSubscriptions,
  });

  final int jeton;
  final int cfc;
  final VoidCallback? onTopUp;
  final VoidCallback? onCfcTopUp;
  final VoidCallback? onEarnings;
  final VoidCallback? onTransactions;
  final VoidCallback? onPaymentNotice;
  final VoidCallback? onSubscriptions;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.add_card_rounded,
        label: 'Jeton Yükle',
        onTap: onTopUp,
        accent: AppThemeColors.coinGold,
      ),
      (
        icon: Icons.diamond_rounded,
        label: 'CFC Yükle',
        onTap: onCfcTopUp,
        accent: AppThemeColors.diamondBlue,
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        label: 'Kazançlarım',
        onTap: onEarnings,
        accent: AppThemeColors.accentCyan,
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: 'İşlemler',
        onTap: onTransactions,
        accent: AppThemeColors.accentPurple,
      ),
      (
        icon: Icons.payment_rounded,
        label: 'Ödeme Bildirimi',
        onTap: onPaymentNotice,
        accent: AppThemeColors.accentPink,
      ),
      (
        icon: Icons.workspace_premium_rounded,
        label: 'Abonelikler',
        onTap: onSubscriptions,
        accent: AppThemeColors.coinGold,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Cüzdanım'),
        ProfileGlass(
          padding: const EdgeInsets.all(18),
          borderColor: AppThemeColors.accentPurple.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bakiyeler', style: ProfileTypography.cardTitle(context)),
              const SizedBox(height: 14),
              DualBalanceChips(
                jeton: jeton,
                cfc: cfc,
                onTap: onTopUp,
              ),
              const SizedBox(height: 12),
              Text(
                'Jeton: canlı yayın, sohbet ve hediye · CFC: oyun ve fal',
                style: ProfileTypography.cardSubtitle(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.35,
          ),
          itemBuilder: (context, i) {
            final a = actions[i];
            return _WalletAction(
              icon: a.icon,
              label: a.label,
              onTap: a.onTap,
              accent: a.accent,
            );
          },
        ),
      ],
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppThemeColors.accentCyan;
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: ProfileTypography.actionLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
