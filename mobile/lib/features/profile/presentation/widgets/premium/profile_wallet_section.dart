import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Cüzdanım'),
        ProfileGlass(
          padding: const EdgeInsets.all(16),
          borderColor: AppThemeColors.accentPurple.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bakiyeler',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              DualBalanceChips(jeton: jeton, cfc: cfc, onTap: onTopUp),
              const SizedBox(height: 8),
              Text(
                'Jeton: canlı yayın, sohbet, hediye · CFC (CanlıFal Coin): oyun ve fal',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WalletAction(
                icon: Icons.add_card_rounded,
                label: 'Jeton Yükle',
                onTap: onTopUp,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletAction(
                icon: Icons.diamond_rounded,
                label: 'CFC Yükle',
                onTap: onCfcTopUp,
                accent: AppThemeColors.diamondBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WalletAction(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Kazançlarım',
                onTap: onEarnings,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 10),
        _WalletAction(
          icon: Icons.payment_rounded,
          label: 'Ödeme Bildirimi',
          onTap: onPaymentNotice,
          accent: AppThemeColors.accentPink,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WalletAction(
                icon: Icons.receipt_long_rounded,
                label: 'İşlemler',
                onTap: onTransactions,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WalletAction(
                icon: Icons.workspace_premium_rounded,
                label: 'Abonelikler',
                onTap: onSubscriptions,
              ),
            ),
          ],
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
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.accentPurple.withValues(alpha: 0.35),
                  AppThemeColors.accentPink.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(icon, size: 18, color: accent ?? AppThemeColors.accentCyan),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
