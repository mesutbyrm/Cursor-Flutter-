import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_startup_log.dart';
import '../core/bootstrap/auth_route_paths.dart';
import '../core/bootstrap/auth_redirect.dart';
import '../core/l10n/app_localizations_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/push/push_lifecycle_listener.dart';
import '../core/scroll/modern_social_scroll_behavior.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_flow_app.dart';
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
  @override
  void initState() {
    super.initState();
    AppStartupLog.appStart();

    ref.listenManual<bool>(guestModeProvider, (prev, next) {
      if (prev == next || next != true) return;
      final authed = ref.read(authControllerProvider).valueOrNull != null;
      if (authed) return;
      ref.read(shellSessionProvider.notifier).state++;
    });

    ref.listenManual(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.valueOrNull != null;
      final nowAuthed = next.valueOrNull != null;
      if (!wasAuthed && nowAuthed) {
        ref.read(guestModeProvider.notifier).state = false;
      }
      if (wasAuthed && !nowAuthed) {
        ref.read(shellSessionProvider.notifier).state++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final guest = ref.watch(guestModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);

    final bootstrapDone = !auth.isLoading || auth.hasValue;
    final authed = auth.valueOrNull != null;
    final showBootstrap = !bootstrapDone;
    final showAuthOverlay = bootstrapDone && !authed && !guest;

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

                var body = child ?? const ColoredBox(color: Color(0xFF05050D));

                if (!isAuthRoute && !showAuthOverlay) {
                  body = FortuneIncomingInviteHost(child: body);
                  body = AppBottomNavHost(child: body);
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    body,
                    if (showGlobalMusic && !showAuthOverlay)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: VoiceRoomGlobalMusicBar(),
                      ),
                    if (showBootstrap) const AuthBootstrapOverlay(),
                    if (showAuthOverlay) const AuthFlowOverlay(),
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
