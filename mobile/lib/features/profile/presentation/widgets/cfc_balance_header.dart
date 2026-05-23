import 'package:flutter/material.dart';

import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/theme/app_colors.dart';

/// CFC yükleme sayfası — yalnızca CFC bakiyesi.
class CfcBalanceHeader extends StatelessWidget {
  const CfcBalanceHeader({super.key, required this.cfc});

  final int cfc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.diamondBlue.withValues(alpha: 0.25),
            AppColors.bgPurpleGlow.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: AppColors.diamondBlue.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CurrencyUsageInfo.cfcTitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$cfc CFC',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: AppColors.diamondBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yalnızca CFC yüklenir · ${CurrencyUsageInfo.cfcPriceHint}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
