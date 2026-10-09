import 'package:canlifal_social/features/shell/presentation/app_bottom_nav_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/feed',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => shell,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/feed', builder: (_, _) => const Text('feed')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/social',
              builder: (_, _) => const Text('social'),
              routes: [
                GoRoute(
                  path: 'tanis-kaynas',
                  builder: (_, _) => const Text('tk'),
                  routes: [
                    GoRoute(
                      path: 'extras',
                      parentNavigatorKey: root,
                      builder: (_, _) => const Text('extras'),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: '/shorts', builder: (_, _) => const Text('shorts')),
    ],
  );
}

void main() {
  test('push edilmiş tam sayfalarda bar görünür, kabukta görünmez', () {
    expect(AppBottomNavHost.shouldShowBottomNav('/shorts', inShell: false),
        isTrue);
    expect(AppBottomNavHost.shouldShowBottomNav('/feed', inShell: true),
        isFalse);
    // Kabuk kökü altında ama kök navigatörde açılan sayfa: bar eklenir.
    expect(
      AppBottomNavHost.shouldShowBottomNav(
        '/social/tanis-kaynas/extras',
        inShell: false,
      ),
      isTrue,
    );
    expect(AppBottomNavHost.shouldShowBottomNav('/chat/1', inShell: false),
        isFalse);
    expect(AppBottomNavHost.shouldShowBottomNav('/shorts/upload',
        inShell: false), isFalse);
    expect(AppBottomNavHost.shouldShowBottomNav('/live/swipe',
        inShell: false), isFalse);
  });

  testWidgets('visibleRoute push edilen sayfayı görür', (t) async {
    final r = _router();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    await t.pumpAndSettle();
    var v = AppBottomNavHost.visibleRoute(r.routerDelegate.currentConfiguration);
    expect(v.path, '/feed');
    expect(v.inShell, isTrue);

    r.push('/shorts');
    await t.pumpAndSettle();
    expect(find.text('shorts'), findsOneWidget);
    v = AppBottomNavHost.visibleRoute(r.routerDelegate.currentConfiguration);
    // URI hâlâ /feed; görünen sayfa /shorts ve kabuk dışında.
    expect(r.routerDelegate.currentConfiguration.uri.path, '/feed');
    expect(v.path, '/shorts');
    expect(v.inShell, isFalse);
    expect(AppBottomNavHost.shouldShowBottomNav(v.path, inShell: v.inShell),
        isTrue);

    r.pop();
    await t.pumpAndSettle();
    r.go('/social/tanis-kaynas');
    await t.pumpAndSettle();
    v = AppBottomNavHost.visibleRoute(r.routerDelegate.currentConfiguration);
    expect(v.inShell, isTrue);

    r.push('/social/tanis-kaynas/extras');
    await t.pumpAndSettle();
    v = AppBottomNavHost.visibleRoute(r.routerDelegate.currentConfiguration);
    expect(v.path, '/social/tanis-kaynas/extras');
    expect(v.inShell, isFalse);
  });
}
