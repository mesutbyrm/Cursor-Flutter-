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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: AppTheme.accent.withValues(alpha: 0.15),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppTheme.accent),
                label: 'Akış',
              ),
              NavigationDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon:
                    Icon(Icons.live_tv_rounded, color: AppTheme.accentSecondary),
                label: 'Canlı',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon:
                    Icon(Icons.chat_bubble_rounded, color: AppTheme.accent),
                label: 'Mesaj',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon:
                    Icon(Icons.person_rounded, color: AppTheme.accent),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
