import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/admin_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shell_screen.dart';
import 'state.dart';

class CanlifalApp extends ConsumerWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Canlifal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: CanlifalTheme.dark,
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((Ref ref) {
  final AuthController auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthRoute = state.uri.path == '/auth';
      if (!auth.isAuthenticated && !isAuthRoute) {
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

class CanlifalTheme {
  static ThemeData get dark {
    const Color seed = Color(0xFF8B5CF6);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF10101C),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: seed,
        secondary: const Color(0xFF22D3EE),
        tertiary: const Color(0xFFFF2D75),
      ),
      scaffoldBackgroundColor: const Color(0xFF080713),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF11111D).withValues(alpha: .92),
        indicatorColor: seed.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: .06),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .12)),
        ),
      ),
    );
  }
}
