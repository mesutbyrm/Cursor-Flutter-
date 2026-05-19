import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class CanlifalApp extends ConsumerWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'Canlifal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          routerConfig: router,
        );
      },
    );
  }
}
