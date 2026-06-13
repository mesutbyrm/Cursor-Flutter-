import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bootstrap/app_startup_log.dart';
import '../core/bootstrap/root_overlay_purge.dart';
import '../core/l10n/app_localizations_config.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/push/push_lifecycle_listener.dart';
import '../core/scroll/modern_social_scroll_behavior.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_flow_app.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/voice_hub/presentation/widgets/voice_room_music_lifecycle_host.dart';
import 'router/app_router.dart';
import 'widgets/main_app_shell.dart';

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
      resetRootNavigatorKey(ref.read(shellSessionProvider.notifier).state + 1);
      ref.read(shellSessionProvider.notifier).state++;
    });

    ref.listenManual(authControllerProvider, (prev, next) {
      final wasAuthed = prev?.valueOrNull != null;
      final nowAuthed = next.valueOrNull != null;
      if (!wasAuthed && nowAuthed) {
        final session = ref.read(shellSessionProvider) + 1;
        resetRootNavigatorKey(session);
        ref.read(shellSessionProvider.notifier).state = session;
      }
      if (wasAuthed && !nowAuthed) {
        BarrierRouteJournal.clear();
        final session = ref.read(shellSessionProvider) + 1;
        resetRootNavigatorKey(session);
        ref.read(shellSessionProvider.notifier).state = session;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final guest = ref.watch(guestModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final bootstrapDone = !auth.isLoading || auth.hasValue;
    final authed = auth.valueOrNull != null;
    final showMainShell = bootstrapDone && (authed || guest);

    if (!bootstrapDone) {
      return MaterialApp(
        title: 'Canlifal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const AuthBootstrapOverlay(),
      );
    }

    // Oturumsuz: go_router YOK — arka planda /feed shell yüklenmez, barrier oluşmaz.
    if (!showMainShell) {
      return MaterialApp(
        key: const ValueKey('auth-only'),
        title: 'Canlifal',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const ModernSocialScrollBehavior(),
        locale: AppLocalizationsConfig.locale,
        supportedLocales: AppLocalizationsConfig.supportedLocales,
        localizationsDelegates: AppLocalizationsConfig.delegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const AuthGatewayHost(),
      );
    }

    final shellSession = ref.watch(shellSessionProvider);
    final router = ref.watch(goRouterProvider);

    return VoiceRoomMusicLifecycleHost(
      child: PushLifecycleListener(
        child: MaterialApp.router(
          key: ValueKey('main-$shellSession'),
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

            return MainAppShell(
              child: child ?? const ColoredBox(color: Color(0xFF05050D)),
            );
          },
          routerConfig: router,
        ),
      ),
    );
  }
}
