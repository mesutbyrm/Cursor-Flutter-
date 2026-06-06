import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';


/// Fal hub üst bar — mor/altın çerçeveli kare ikon butonu.
class FortuneHubActionButton extends StatelessWidget {
  const FortuneHubActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A0B2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _gold.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.95),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 14),
                    decoration: BoxDecoration(
                      color: AppThemeColors.liveRed,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0A0118), width: 1),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
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
