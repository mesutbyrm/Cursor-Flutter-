import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/features/admin/screens/admin_screen.dart';
import '../presentation/features/auth/screens/auth_screen.dart';
import '../presentation/features/chat/screens/chat_screen.dart';
import '../presentation/features/explore/screens/explore_screen.dart';
import '../presentation/features/fortune/screens/fortune_screen.dart';
import '../presentation/features/home/screens/home_screen.dart';
import '../presentation/features/live/screens/live_screen.dart';
import '../presentation/features/profile/screens/profile_screen.dart';
import '../presentation/features/shell/screens/shell_screen.dart';
import '../presentation/providers/providers.dart';

final routerProvider = Provider<GoRouter>((Ref ref) {
  final AuthController auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthRoute = state.uri.path == '/auth';
      final bool requiresAuth = <String>[
        '/profile',
        '/admin',
        '/live/create',
      ].any(state.uri.path.startsWith);
      if (!auth.isAuthenticated && requiresAuth && !isAuthRoute) {
        return '/auth';
      }
      if (auth.isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage(state, const AuthScreen());
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainShellScreen(location: state.uri.path, child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const HomeScreen());
            },
          ),
          GoRoute(
            path: '/live',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const LiveScreen());
            },
          ),
          GoRoute(
            path: '/live/create',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const LiveBroadcastSetupScreen());
            },
          ),
          GoRoute(
            path: '/live/:id',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(
                state,
                LiveWatchScreen(streamId: state.pathParameters['id']!),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const ChatScreen());
            },
          ),
          GoRoute(
            path: '/fortune',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const FortuneScreen());
            },
          ),
          GoRoute(
            path: '/explore',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const ExploreScreen());
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const ProfileScreen());
            },
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return _fadePage(state, const AdminScreen());
            },
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<Offset> offset =
              Tween<Offset>(
                begin: const Offset(0, .02),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
  );
}
