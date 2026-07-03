import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../profile_theme.dart';

/// Premium hızlı işlem / panel kartı — 3 sütun grid için.
class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.gradient,
    this.iconColor,
    this.delayMs = 0,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final List<Color>? gradient;
  final Color? iconColor;
  final int delayMs;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final colors = gradient ??
        [
          ProfilePremiumTheme.neonPurple.withValues(alpha: 0.35),
          ProfilePremiumTheme.deepBg.withValues(alpha: 0.9),
        ];

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusSm),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusSm),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(color: ProfilePremiumTheme.glassBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: iconColor ?? Colors.white.withValues(alpha: 0.95),
                      ),
                      if (badge != null && badge! > 0)
                        Positioned(
                          right: -10,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge! > 99 ? '99+' : '$badge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: 220.ms);
  }
}
