import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_startup_log.dart';
import '../core/bootstrap/auth_redirect.dart';
import '../core/bootstrap/auth_route_paths.dart';
import '../core/bootstrap/navigator_modal_sanitizer.dart';
import '../core/bootstrap/stuck_overlay_guard.dart';
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
  Timer? _postAuthTimer;
  var _inStartupWindow = true;
  var _postAuthScrub = false;

  @override
  void initState() {
    super.initState();
    AppStartupLog.appStart();

    if (ref.read(authControllerProvider).valueOrNull != null) {
      _beginPostAuthScrub();
    }

    _startupTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _inStartupWindow = false);
    });

    ref.listenManual<bool>(guestModeProvider, (prev, next) {
      if (prev == next || next != true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final authed = ref.read(authControllerProvider).valueOrNull != null;
        if (authed) return;
        ref.read(goRouterProvider).go('/feed');
      });
    });

    ref.listenManual(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.valueOrNull != null;
      final nowAuthed = next.valueOrNull != null;
      final wasLoading = prev?.isLoading ?? true;
      final nowLoading = next.isLoading;

      if (!wasAuthed && nowAuthed) {
        ref.read(guestModeProvider.notifier).state = false;
        _beginPostAuthScrub();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          StuckOverlayGuard.dismissAll(reason: 'auth-login');
          ref.read(goRouterProvider).go('/feed');
        });
      } else if (wasAuthed && !nowAuthed && !ref.read(guestModeProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(goRouterProvider).go('/login');
        });
      } else if (wasLoading && !nowLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _applyAuthRedirect(next);
        });
      }
    });
  }

  void _applyAuthRedirect(AsyncValue<dynamic> auth) {
    final router = ref.read(goRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final target = AuthRedirect.targetFor(
      path: path,
      matchedLocation: path,
      user: auth.valueOrNull,
      guest: ref.read(guestModeProvider),
    );
    if (target != null && target != path) {
      AppStartupLog.route(path, target, reason: 'auth-settled');
      router.go(target);
    }
  }

  void _beginPostAuthScrub() {
    _postAuthTimer?.cancel();
    setState(() => _postAuthScrub = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StuckOverlayGuard.dismissAll(reason: 'post-auth-scrub');
    });
    _postAuthTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() => _postAuthScrub = false);
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _postAuthTimer?.cancel();
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
                final scrubOverlays =
                    isAuthRoute || _inStartupWindow || _postAuthScrub;
                final onFeed = routerLocation == '/feed' ||
                    routerLocation.startsWith('/feed/');

                var body = child ?? const ColoredBox(color: Color(0xFF05050D));

                if (!isAuthRoute) {
                  body = FortuneIncomingInviteHost(child: body);
                  body = AppBottomNavHost(child: body);
                }

                body = NavigatorModalSanitizer(
                  active: scrubOverlays,
                  postAuthFeed: _postAuthScrub && onFeed,
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
