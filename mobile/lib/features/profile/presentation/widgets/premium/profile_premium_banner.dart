import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/premium_2026/profile_membership_helpers.dart';
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
    final info = resolveProfileMembership(
      rawMembership: membership,
      daysRemaining: daysRemaining,
    );
    final paid = info.hasActiveSubscription;
    final subtitle = paid && daysRemaining != null && daysRemaining! > 0
        ? '${info.tierLabel} üyesiniz · $daysRemaining gün kaldı'
        : 'Özel rozetler, öncelikli destek ve daha fazlası';
    final cta = paid ? 'Uzat' : 'Ayrıcalıkları Gör';

    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 22,
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1F6E),
          Color(0xFF6B248C),
          Color(0xFF8E2DA8),
        ],
      ),
      borderColor: AppThemeColors.accentPink.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              boxShadow: AppThemeColors.glowShadow(
                const Color(0xFFFFD54F),
                blur: 16,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? '${info.tierLabel} Üyelik' : 'Premium Üyelik',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: paid
                        ? const Color(0xFFFFE082)
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppThemeColors.accentPink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onViewPrivileges ??
                  () => context.push('/premium-membership'),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Text(
                  cta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
