import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Jeton + CFC yan yana — shell ve profil.
class DualBalanceChips extends StatelessWidget {
  const DualBalanceChips({
    super.key,
    required this.jeton,
    required this.cfc,
    this.compact = false,
    this.onTap,
  });

  final int jeton;
  final int cfc;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.push('/jeton-store'),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: 'Jeton',
            value: jeton,
            icon: Icons.monetization_on_rounded,
            color: AppColors.coinGold,
            compact: compact,
          ),
          SizedBox(width: compact ? 4 : 6),
          _Chip(
            label: 'CFC',
            value: cfc,
            icon: Icons.diamond_rounded,
            color: AppColors.diamondBlue,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 4),
          if (!compact)
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.95),
              ),
            ),
          if (!compact) const SizedBox(width: 4),
          Text(
            _fmt(value),
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
