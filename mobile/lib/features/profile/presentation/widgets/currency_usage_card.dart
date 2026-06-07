import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';

/// CFC veya Jeton kullanım alanları kartı.
class CurrencyUsageCard extends StatelessWidget {
  const CurrencyUsageCard.cfc({super.key}) : isCfc = true;

  const CurrencyUsageCard.jeton({super.key}) : isCfc = false;

  final bool isCfc;

  @override
  Widget build(BuildContext context) {
    final title = isCfc ? CurrencyUsageInfo.cfcTitle : CurrencyUsageInfo.jetonTitle;
    final items =
        isCfc ? CurrencyUsageInfo.cfcUsageItems : CurrencyUsageInfo.jetonUsageItems;

    return ProGlassCard(
      blur: 14,
      animateIn: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title — nerelerde kullanılır?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if (isCfc) ...[
            SizedBox(height: 8),
            Text(
              CurrencyUsageInfo.cfcPriceHint,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppThemeColors.diamondBlue.withValues(alpha: 0.95),
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppThemeColors.liveRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppThemeColors.liveRed.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppThemeColors.liveRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      CurrencyUsageInfo.cfcNotConvertible,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 10),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      items[i],
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
