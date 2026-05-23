import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'fortune_hub_gold_stars.dart';

/// Sezgi bildirimi — kristal küre + metin + yıldızlar (mockup).
class FortuneHubInsightBanner extends StatelessWidget {
  const FortuneHubInsightBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A0B2E).withValues(alpha: 0.9),
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                  boxShadow: AppColors.glowShadow(
                    AppColors.accentPurple,
                    blur: 10,
                  ),
                ),
                child: const Text('🔮', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bugün sezgilerin güçlü, iç sesini dinlemeyi unutma.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const FortuneHubGoldStars(size: 9, spacing: 1),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
