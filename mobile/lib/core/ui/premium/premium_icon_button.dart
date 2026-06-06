import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';


/// Cam yüzeyli ikon butonu — bildirim, ayarlar.
class PremiumIconButton extends StatelessWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.95),
                size: size * 0.58,
              ),
              if (showBadge || badgeCount > 0)
                Positioned(
                  top: size * 0.14,
                  right: size * 0.12,
                  child: badgeCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: AppThemeColors.liveRed,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.scaffoldBg,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        )
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppThemeColors.liveRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.scaffoldBg,
                              width: 1.5,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
