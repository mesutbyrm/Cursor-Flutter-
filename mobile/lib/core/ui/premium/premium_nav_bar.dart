import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../theme/app_spacing.dart';
import '../../theme/canlifal_tokens.dart';
import 'gradient_fab.dart';

/// Alt navigasyon — BackdropFilter yok (performans), cam yüzey.
class PremiumNavBar extends StatelessWidget {
  const PremiumNavBar({
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
    final tokens = context.tokens;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.navBarBackground,
          border: Border(top: BorderSide(color: tokens.glassBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSpacing.navBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavSlot(
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore_rounded,
                  label: 'Keşfet',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavSlot(
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups_rounded,
                  label: 'Sosyal',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                GradientFab(icon: fabIcon, onTap: onFabTap),
                _NavSlot(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome_rounded,
                  label: 'Fal&Tarot',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavSlot(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profil',
                  selected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.onSurface
        : context.colors.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
