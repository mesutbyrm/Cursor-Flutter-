import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../premium/gradient_fab.dart';
import 'premium_2026_tokens.dart';
import 'premium_motion.dart';
import 'premium_typography.dart';
import 'liquid_glass.dart';

/// 2026 floating liquid glass bottom navigation.
class PremiumLiquidNavBar extends StatelessWidget {
  const PremiumLiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.fabIcon = Icons.videocam_rounded,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final IconData fabIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.p26;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusLiquid),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: t.navFloater,
              borderRadius: BorderRadius.circular(t.radiusLiquid),
              border: Border.all(color: t.glassBorder.withValues(alpha: 0.35)),
              boxShadow: t.shadowFloating,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppSpacing.navBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LiquidNavItem(
                      index: 0,
                      current: currentIndex,
                      icon: Icons.explore_outlined,
                      selectedIcon: Icons.explore_rounded,
                      label: 'Keşfet',
                      onTap: onTap,
                    ),
                    _LiquidNavItem(
                      index: 1,
                      current: currentIndex,
                      icon: Icons.groups_outlined,
                      selectedIcon: Icons.groups_rounded,
                      label: 'Sosyal',
                      onTap: onTap,
                    ),
                    GradientFab(icon: fabIcon, onTap: onFabTap),
                    _LiquidNavItem(
                      index: 3,
                      current: currentIndex,
                      icon: Icons.auto_awesome_outlined,
                      selectedIcon: Icons.auto_awesome_rounded,
                      label: 'Fal',
                      onTap: onTap,
                    ),
                    _LiquidNavItem(
                      index: 4,
                      current: currentIndex,
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      label: 'Profil',
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: PremiumMotion.medium, curve: PremiumMotion.easeOut)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: PremiumMotion.medium,
          curve: PremiumMotion.expo,
        );
  }
}

class _LiquidNavItem extends StatelessWidget {
  const _LiquidNavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int current;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    final t = context.p26;

    return PressableScale(
      onTap: () => onTap(index),
      scaleDown: 0.9,
      child: AnimatedContainer(
        duration: PremiumMotion.medium,
        curve: PremiumMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusPill),
          color: selected
              ? AppColors.accentPink.withValues(alpha: 0.18)
              : Colors.transparent,
          border: selected
              ? Border.all(
                  color: AppColors.accentPink.withValues(alpha: 0.35),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: PremiumTypography.navLabel(context, selected: selected),
            ),
          ],
        ),
      ),
    );
  }
}
