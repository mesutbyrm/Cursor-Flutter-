import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';
import 'profile_glass.dart';

class ProfilePremiumBanner extends StatelessWidget {
  const ProfilePremiumBanner({super.key, this.onViewPrivileges});

  final VoidCallback? onViewPrivileges;

  @override
  Widget build(BuildContext context) {
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
      borderColor: AppDesign.accentPink.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              boxShadow: AppDesign.glowShadow(
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
          const Expanded(
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
                  'Özel rozetler, öncelikli destek ve daha fazlası',
                  style: TextStyle(
                    color: AppDesign.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppDesign.accentPink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onViewPrivileges,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'Ayrıcalıkları Gör',
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
