import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';
import 'profile_glass.dart';

class ProfileWalletSection extends StatelessWidget {
  const ProfileWalletSection({
    super.key,
    required this.coinBalance,
    this.onTopUp,
    this.onEarnings,
    this.onTransactions,
    this.onSubscriptions,
  });

  final int coinBalance;
  final VoidCallback? onTopUp;
  final VoidCallback? onEarnings;
  final VoidCallback? onTransactions;
  final VoidCallback? onSubscriptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Cüzdanım'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ProfileGlass(
                padding: const EdgeInsets.all(18),
                borderColor: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3D2A10),
                            Color(0xFF2A1F08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFD54F),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Coin Bakiyesi',
                      style: TextStyle(
                        color: AppDesign.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profileFormatCoins(coinBalance),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _WalletAction(
                    icon: Icons.add_card_rounded,
                    label: 'Coin Yükle',
                    onTap: onTopUp,
                  ),
                  const SizedBox(height: 10),
                  _WalletAction(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Kazançlarım',
                    onTap: onEarnings,
                  ),
                  const SizedBox(height: 10),
                  _WalletAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'İşlemler',
                    onTap: onTransactions,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WalletAction(
          icon: Icons.workspace_premium_rounded,
          label: 'Abonelikler',
          onTap: onSubscriptions,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

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
                  AppDesign.accentPurple.withValues(alpha: 0.35),
                  AppDesign.accentPink.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(icon, size: 18, color: AppDesign.accentCyan),
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
