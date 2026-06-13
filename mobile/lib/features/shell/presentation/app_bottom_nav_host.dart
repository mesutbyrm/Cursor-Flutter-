import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../home/presentation/theme/home_approved_design.dart';
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
    if (path.startsWith('/voice-room/')) return true;
    if (path == '/live/room' || path.startsWith('/live/room/')) return true;
    if (path.contains('/session') && path.startsWith('/canli-falcilar')) {
      return true;
    }
    return false;
  }

  static bool shellHasBottomNav(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    const roots = ['/feed', '/social', '/live', '/fortune', '/profile'];
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
    final path = Uri.tryParse(location)?.path ?? location;
    if (path.startsWith('/voice-rooms')) return HomeBottomTab.rooms;
    if (path.startsWith('/jeton-store') || path.startsWith('/wallet')) {
      return HomeBottomTab.jeton;
    }
    if (path.startsWith('/canli-falcilar') ||
        path.startsWith('/live/prep') ||
        path.startsWith('/live/swipe')) {
      return HomeBottomTab.live;
    }
    if (path.startsWith('/messages') ||
        path.startsWith('/notifications') ||
        path.startsWith('/content-hub')) {
      return HomeBottomTab.home;
    }
    return HomeBottomTab.home;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final showNav = shouldShowBottomNav(location);
    if (!showNav) return child;

    final tab = activeTabFor(location);

    return ColoredBox(
      color: HomeApprovedDesign.background,
      child: Column(
        children: [
          Expanded(child: child),
          BottomNavigationWidget(
            activeTab: tab,
            onHome: () => router.go('/feed'),
            onLive: () => router.go('/live'),
            onRooms: () => router.push('/voice-rooms'),
            onJeton: () => router.push('/jeton-store'),
            onProfile: () => router.go('/profile'),
          ),
        ],
      ),
    );
  }
}
