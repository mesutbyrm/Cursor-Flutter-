import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/push/push_lifecycle_listener.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class CanlifalApp extends ConsumerWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PushLifecycleListener(
      child: MaterialApp.router(
        title: 'Canlifal',
        debugShowCheckedModeBanner: false,
        locale: AppLocalizationsConfig.locale,
        supportedLocales: AppLocalizationsConfig.supportedLocales,
        localizationsDelegates: AppLocalizationsConfig.delegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
