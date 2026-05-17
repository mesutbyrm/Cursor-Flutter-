import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_service.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../features/admin/admin_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/main_shell.dart';

class CanlifalApp extends ConsumerWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final router = GoRouter(
      refreshListenable: session,
      initialLocation: '/auth',
      redirect: (context, state) {
        final isAuthRoute = state.matchedLocation == '/auth';
        if (!session.isAuthenticated && !isAuthRoute) return '/auth';
        if (session.isAuthenticated && isAuthRoute) return '/app';
        return null;
      },
      routes: <RouteBase>[
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/app', builder: (context, state) => const MainShell()),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
      ],
    );
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      routerConfig: router,
    );
  }
}
