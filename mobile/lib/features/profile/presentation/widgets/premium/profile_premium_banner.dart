import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'profile_glass.dart';

class ProfilePremiumBanner extends StatelessWidget {
  const ProfilePremiumBanner({
    super.key,
    this.onViewPrivileges,
    this.membership,
    this.daysRemaining,
  });

  final VoidCallback? onViewPrivileges;
  final String? membership;
  final int? daysRemaining;

  @override
  Widget build(BuildContext context) {
    final tier = membership?.toLowerCase() ?? 'basic';
    final days = daysRemaining ?? 0;
    final isGold = tier == 'gold' && days > 0;
    final subtitle = isGold
        ? 'Gold üyesiniz · $days gün kaldı'
        : 'Özel rozetler, öncelikli destek ve daha fazlası';
    final cta = isGold ? 'Uzat' : 'Ayrıcalıkları Gör';

    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 20,
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1F6E),
          Color(0xFF6B248C),
          Color(0xFF8E2DA8),
        ],
      ),
      borderColor: AppColors.accentPink.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              boxShadow: AppColors.glowShadow(
                const Color(0xFFFFD54F),
                blur: 16,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Üyelik',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isGold
                        ? const Color(0xFFFFD54F).withValues(alpha: 0.95)
                        : AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: isGold ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.accentPink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onViewPrivileges,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  cta,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
