import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_startup_log.dart';
import '../core/bootstrap/auth_route_paths.dart';
import '../core/bootstrap/navigator_modal_sanitizer.dart';
import '../core/l10n/app_localizations_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/push/push_lifecycle_listener.dart';
import '../core/scroll/modern_social_scroll_behavior.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/home/presentation/widgets/fortune_incoming_invite_host.dart';
import '../features/shell/presentation/app_bottom_nav_host.dart';
import '../features/voice_hub/presentation/widgets/voice_room/voice_room_global_music_bar.dart';
import '../features/voice_hub/presentation/widgets/voice_room_music_lifecycle_host.dart';
import 'router/app_router.dart';

class CanlifalApp extends ConsumerStatefulWidget {
  const CanlifalApp({super.key});

  @override
  ConsumerState<CanlifalApp> createState() => _CanlifalAppState();
}

class _CanlifalAppState extends ConsumerState<CanlifalApp> {
  Timer? _startupTimer;
  var _inStartupWindow = true;
  var _authResolvedOnFeed = false;

  @override
  void initState() {
    super.initState();
    AppStartupLog.appStart();
    _startupTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _inStartupWindow = false);
    });
    ref.listenManual<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading && next.hasValue) {
        if (!mounted) return;
        setState(() => _authResolvedOnFeed = true);
      }
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return VoiceRoomMusicLifecycleHost(
      child: PushLifecycleListener(
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
                statusBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: brightness == Brightness.dark
                    ? Brightness.dark
                    : Brightness.light,
              ),
            );
            return ListenableBuilder(
              listenable: router.routerDelegate,
              builder: (context, _) {
                final routerLocation =
                    router.routerDelegate.currentConfiguration.uri.path;
                final isAuthRoute =
                    AuthRoutePaths.isPublicAuthPath(routerLocation);
                final showGlobalMusic =
                    VoiceRoomGlobalMusicBar.shouldShowForRoute(routerLocation);
                final onFeed = routerLocation == '/feed';
                final scrubOverlays = isAuthRoute ||
                    _inStartupWindow ||
                    (_authResolvedOnFeed && onFeed);

                var body = child ?? const ColoredBox(color: Color(0xFF05050D));

                if (!isAuthRoute) {
                  body = FortuneIncomingInviteHost(child: body);
                  body = AppBottomNavHost(child: body);
                }

                body = NavigatorModalSanitizer(
                  active: scrubOverlays,
                  postAuthFeed: _authResolvedOnFeed && onFeed,
                  child: body,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    body,
                    if (showGlobalMusic)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: VoiceRoomGlobalMusicBar(),
                      ),
                  ],
                );
              },
            );
          },
          routerConfig: router,
        ),
      ),
    );
  }
}
