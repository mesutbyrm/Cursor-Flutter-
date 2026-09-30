import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/ui/responsive/responsive_layout.dart';
import 'shell_ui.dart';
import '../../home/presentation/widgets/approved/bottom_navigation_widget.dart';

/// Sesli sohbet odası (RTC) dışındaki sayfalarda alt navigasyon.
class AppBottomNavHost extends ConsumerWidget {
  const AppBottomNavHost({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static bool hidesBottomNav(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    if (path.isEmpty || path == '/') return true;
    if (path == '/splash') return true;
    if (path == '/login' ||
        path == '/register' ||
        path.startsWith('/auth/')) {
      return true;
    }
    if (path.startsWith('/chat/')) return true;
    if (path.startsWith('/voice-room/')) return true;
    if (path == '/voice-rooms' || path.startsWith('/voice-rooms/')) return true;
    if (path == '/live/room' || path.startsWith('/live/room/')) return true;
    if (path.contains('/session') && path.startsWith('/canli-falcilar')) {
      return true;
    }
    if (path.contains('/waiting') && path.startsWith('/canli-falcilar')) {
      return true;
    }
    if (path.contains('/ad-transition') && path.startsWith('/canli-falcilar')) {
      return true;
    }
    return false;
  }

  static bool shellHasBottomNav(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    const roots = [
      '/feed',
      '/social',
      '/live',
      '/fortune',
      '/profile',
      '/messages',
    ];
    for (final root in roots) {
      if (path == root || path.startsWith('$root/')) return true;
    }
    return false;
  }

  static bool shouldShowBottomNav(String location) {
    if (hidesBottomNav(location)) return false;
    if (shellHasBottomNav(location)) return false;
    return true;
  }

  static HomeBottomTab activeTabFor(String location) {
    if (location.contains('type=tarot')) return HomeBottomTab.tarot;
    final path = Uri.tryParse(location)?.path ?? location;
    if (path.startsWith('/social') || path.startsWith('/shorts')) {
      return HomeBottomTab.social;
    }
    if (path.startsWith('/live')) return HomeBottomTab.live;
    if (path.startsWith('/profile')) return HomeBottomTab.profile;
    if (path.startsWith('/fortune') ||
        path.startsWith('/jeton-store') ||
        path.startsWith('/wallet')) {
      return HomeBottomTab.fortune;
    }
    if (path.startsWith('/messages') || path.startsWith('/notifications')) {
      return HomeBottomTab.social;
    }
    if (path.contains('type=tarot')) return HomeBottomTab.tarot;
    return HomeBottomTab.social;
  }

  static void showCreateSheet(BuildContext context, GoRouter router) {
    ShellUi.showCreateSheet(context, router);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final showNav = shouldShowBottomNav(location);
    if (!showNav) return child;

    final tab = activeTabFor(location);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= ResponsiveLayout.wideBreakpoint;

    if (useRail) {
      final railIndex = switch (tab) {
        HomeBottomTab.social => 0,
        HomeBottomTab.live => 1,
        HomeBottomTab.fortune => 2,
        HomeBottomTab.tarot => 3,
        HomeBottomTab.profile => 4,
      };
      return ColoredBox(
        color: ShellUi.shellBackground(context),
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: railIndex,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    router.go('/social');
                  case 1:
                    router.go('/live');
                  case 2:
                    router.go('/fortune');
                  case 3:
                    router.go('/fortune?type=tarot');
                  case 4:
                    router.go('/profile');
                }
              },
              backgroundColor: ShellUi.bottomNavBackground(context),
              indicatorColor: context.colors.primary.withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: Text('Sosyal'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.podcasts_outlined),
                  selectedIcon: Icon(Icons.podcasts_rounded),
                  label: Text('Canlı'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: Text('Fal'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style_rounded),
                  label: Text('Tarot'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return ColoredBox(
      color: ShellUi.shellBackground(context),
      child: Column(
        children: [
          Expanded(child: child),
          BottomNavigationWidget(
            activeTab: tab,
            onSocial: () => router.go('/social'),
            onLive: () => router.go('/live'),
            onFortune: () => router.go('/fortune'),
            onTarot: () => router.go('/fortune?type=tarot'),
            onProfile: () => router.go('/profile'),
          ),
        ],
      ),
    );
  }
}
