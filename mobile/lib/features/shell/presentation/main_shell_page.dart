import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

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
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12081E).withValues(alpha: 0.94),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.cosmicPurple.withValues(alpha: 0.45),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
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
                          icon: Icons.favorite_border_rounded,
                          selectedIcon: Icons.favorite_rounded,
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
                          badge: true,
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
                        color: AppTheme.accent.withValues(alpha: 0.55),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    idx == 2 ? Icons.live_tv_rounded : Icons.videocam_rounded,
                    color: Colors.white,
                    size: 30,
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
    this.badge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Colors.white : AppTheme.muted.withValues(alpha: 0.85);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? selectedIcon : icon, size: 24, color: c),
                if (badge)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
