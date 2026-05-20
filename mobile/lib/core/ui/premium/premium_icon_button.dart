import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Cam yüzeyli ikon butonu — bildirim, ayarlar.
class PremiumIconButton extends StatelessWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
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
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                size: size * 0.58,
              ),
              if (showBadge)
                Positioned(
                  top: size * 0.22,
                  right: size * 0.22,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
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
