import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/push/push_lifecycle_listener.dart';
import '../core/scroll/modern_social_scroll_behavior.dart';
import '../core/theme/app_theme.dart';
import '../features/home/presentation/widgets/fortune_incoming_invite_host.dart';
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
        scrollBehavior: const ModernSocialScrollBehavior(),
        locale: AppLocalizationsConfig.locale,
        supportedLocales: AppLocalizationsConfig.supportedLocales,
        localizationsDelegates: AppLocalizationsConfig.delegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarIconBrightness:
                  brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              statusBarBrightness:
                  brightness == Brightness.dark ? Brightness.dark : Brightness.light,
            ),
          );
          return FortuneIncomingInviteHost(
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: router,
      ),
    );
  }
}
