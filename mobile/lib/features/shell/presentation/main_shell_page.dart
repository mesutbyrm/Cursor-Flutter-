import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/premium_home/premium_planet_fab_icon.dart';

/// Alt bar: cam blur, üst radius, ortada neon gezegen FAB (mockup).
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 28, bottom: bottomInset),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF12081E).withValues(alpha: 0.76),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.cosmicPurple.withValues(alpha: 0.55),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.22),
                        blurRadius: 32,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 58,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ShellNavItem(
                              icon: Icons.explore_outlined,
                              selectedIcon: Icons.explore_rounded,
                              label: 'Keşfet',
                              selected: idx == 0,
                              onTap: () => _goBranch(0),
                            ),
                          ),
                          Expanded(
                            child: _ShellNavItem(
                              icon: Icons.workspace_premium_outlined,
                              selectedIcon: Icons.workspace_premium_rounded,
                              label: 'Abonelikler',
                              selected: idx == 1,
                              onTap: () => _goBranch(1),
                            ),
                          ),
                          const SizedBox(width: 56),
                          Expanded(
                            child: _ShellNavItem(
                              icon: Icons.chat_bubble_outline_rounded,
                              selectedIcon: Icons.chat_bubble_rounded,
                              label: 'Mesajlar',
                              selected: idx == 3,
                              onTap: () => _goBranch(3),
                              showBadge: true,
                            ),
                          ),
                          Expanded(
                            child: _ShellNavItem(
                              icon: Icons.person_outline_rounded,
                              selectedIcon: Icons.person_rounded,
                              label: 'Profil',
                              selected: idx == 4,
                              onTap: () => _goBranch(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: bottomInset + 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _goBranch(2),
                child: Ink(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.fabGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.65),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppTheme.accentSecondary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: PremiumPlanetFabIcon(size: 30),
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

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final active = AppTheme.accentSecondary;
    final idle = AppTheme.muted.withValues(alpha: 0.88);
    final c = selected ? active : idle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentSecondary.withValues(alpha: 0.55),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    size: 24,
                    color: c,
                  ),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF12081E),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: c,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
