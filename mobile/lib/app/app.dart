import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/scroll/modern_social_scroll_behavior.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class CanlifalApp extends ConsumerWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Canlifal',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ModernSocialScrollBehavior(),
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
