import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/dual_balance_chips.dart';

/// CFC + Jeton + kısa yönlendirme — CFC yükle / Premium üyelik.
class WalletBalanceHeader extends StatelessWidget {
  const WalletBalanceHeader({
    super.key,
    required this.jeton,
    required this.cfc,
    this.membership,
    this.daysRemaining,
    this.showQuickLinks = true,
  });

  final int jeton;
  final int cfc;
  final String? membership;
  final int? daysRemaining;
  final bool showQuickLinks;

  @override
  Widget build(BuildContext context) {
    final tier = membership?.toLowerCase() ?? 'basic';
    final isGold = tier == 'gold' && (daysRemaining ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _BalanceLine(
                label: 'Jeton Bakiyeniz',
                value: '$jeton',
                color: AppThemeColors.coinGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BalanceLine(
                label: 'CFC Bakiyeniz',
                value: '$cfc',
                color: AppThemeColors.diamondBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DualBalanceChips(jeton: jeton, cfc: cfc),
        if (isGold) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD54F).withValues(alpha: 0.35),
                  const Color(0xFFB8860B).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD54F), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GOLD ÜYESİNİZ — $daysRemaining gün kaldı, uzatın',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showQuickLinks) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  icon: Icons.diamond_rounded,
                  label: 'CFC Yükle',
                  color: AppThemeColors.diamondBlue,
                  onTap: () => context.push('/cfc-store'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickLink(
                  icon: Icons.monetization_on_rounded,
                  label: 'Jeton',
                  color: AppThemeColors.coinGold,
                  onTap: () => context.push('/jeton-store'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickLink(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Üyelik',
                  color: const Color(0xFFFFD54F),
                  onTap: () => context.push('/premium-membership'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.onSurfaceMuted.withValues(alpha: 0.95)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
