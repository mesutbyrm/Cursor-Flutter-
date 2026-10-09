import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/ui/responsive/responsive_layout.dart';
import 'shell_ui.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../home/presentation/widgets/approved/bottom_navigation_widget.dart';

/// Sesli sohbet odası (RTC) dışındaki sayfalarda alt navigasyon.
class AppBottomNavHost extends ConsumerWidget {
  const AppBottomNavHost({
    super.key,
    required this.child,
    required this.location,
    this.inShell,
  });

  final Widget child;

  /// Ekranda en üstte görünen sayfanın yolu ([visibleRoute]).
  final String location;

  /// Görünen sayfa alt barlı kabuğun (MainShellPage) içinde mi?
  /// `null` → yalnız yola bakılır ([shellHasBottomNav]).
  final bool? inShell;

  /// go_router `push` URI'yi değiştirmez (`/feed` üstüne itilen `/shorts`
  /// hâlâ `/feed` görünür). Bu yüzden eşleşme listesinin en sonuna bakılır:
  /// görünen sayfanın yolu ve kabuk navigatöründe olup olmadığı.
  static ({String path, bool inShell}) visibleRoute(RouteMatchList config) {
    final top = config.matches.isEmpty ? null : config.matches.last;
    RouteMatchBase? m = top;
    while (m is ShellRouteMatch && m.matches.isNotEmpty) {
      m = m.matches.last;
    }
    final path =
        m is ImperativeRouteMatch ? m.matches.uri.path : config.uri.path;
    return (path: path, inShell: top is ShellRouteMatch);
  }

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
    // Tam ekran / kamera / oyun masası — kendi alt kontrolleri var.
    const immersive = [
      '/live/prep',
      '/live/pk',
      '/live/swipe',
      '/shorts/upload',
      '/dm-voice-call',
      '/games-room/',
      '/social/stories/view',
    ];
    for (final p in immersive) {
      if (path == p || path.startsWith(p.endsWith('/') ? p : '$p/')) {
        return true;
      }
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
    ];
    for (final root in roots) {
      if (path == root || path.startsWith('$root/')) return true;
    }
    return false;
  }

  static bool shouldShowBottomNav(String location, {bool? inShell}) {
    if (hidesBottomNav(location)) return false;
    if (inShell ?? shellHasBottomNav(location)) return false;
    return true;
  }

  static HomeBottomTab activeTabFor(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;
    if (path.startsWith('/shorts/upload')) return HomeBottomTab.create;
    if (path.contains('tanis-kaynas')) return HomeBottomTab.meet;
    if (path.startsWith('/fortune') ||
        uri?.queryParameters['type'] == 'tarot' ||
        location.contains('type=tarot')) {
      return HomeBottomTab.fortuneTarot;
    }
    if (path == '/feed' || path.startsWith('/feed/')) {
      return HomeBottomTab.home;
    }
    if (path.startsWith('/social') || path.startsWith('/shorts')) {
      return HomeBottomTab.social;
    }
    if (path.startsWith('/voice-rooms')) return HomeBottomTab.voice;
    if (path.startsWith('/live')) return HomeBottomTab.create;
    if (path.startsWith('/profile')) return HomeBottomTab.profile;
    if (path.startsWith('/jeton-store') || path.startsWith('/wallet')) {
      return HomeBottomTab.fortuneTarot;
    }
    if (path.startsWith('/messages') || path.startsWith('/notifications')) {
      return HomeBottomTab.social;
    }
    return HomeBottomTab.home;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final showNav = shouldShowBottomNav(location, inShell: inShell);
    // Klavye açıkken bar gizlenir; sayfa kendi composer'ını klavyeye oturtur.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (!showNav || keyboardOpen) return child;

    final tab = activeTabFor(location);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= ResponsiveLayout.wideBreakpoint;

    if (useRail) {
      final railIndex = switch (tab) {
        HomeBottomTab.home => 0,
        HomeBottomTab.social => 1,
        HomeBottomTab.voice => 2,
        HomeBottomTab.create => 3,
        HomeBottomTab.fortuneTarot => 4,
        HomeBottomTab.meet => 5,
        HomeBottomTab.profile => 6,
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
                    router.go('/feed');
                    ref.read(homeReselectProvider.notifier).state++;
                  case 1:
                    router.go('/social');
                  case 2:
                    router.go('/voice-rooms');
                  case 3:
                    ShellUi.showPublishNavSheet(context, router);
                  case 4:
                    router.go('/fortune');
                  case 5:
                    router.push('/social/tanis-kaynas');
                  case 6:
                    router.go('/profile');
                }
              },
              backgroundColor: ShellUi.bottomNavBackground(context),
              indicatorColor: context.colors.primary.withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Ana Sayfa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: Text('Sosyal'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.headphones_rounded),
                  selectedIcon: Icon(Icons.headphones),
                  label: Text('Sesli'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_camera_outlined),
                  selectedIcon: Icon(Icons.photo_camera_rounded),
                  label: Text('Yayın'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: Text('Fal&Tarot'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
                  label: Text('Tanış'),
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
            onHome: () {
              router.go('/feed');
              ref.read(homeReselectProvider.notifier).state++;
            },
            onSocial: () => router.go('/social'),
            onVoice: () => router.go('/voice-rooms'),
            onCreate: () => ShellUi.showPublishNavSheet(context, router),
            onFortuneTarot: () => router.go('/fortune'),
            onMeet: () => router.push('/social/tanis-kaynas'),
            onProfile: () => router.go('/profile'),
          ),
        ],
      ),
    );
  }
}
