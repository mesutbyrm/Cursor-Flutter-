import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/live_fortune/live_fortune_flow.dart';
import '../../features/home/presentation/providers/fortune_incoming_invite_provider.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/presentation/providers/notifications_list_notifier.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../onesignal/onesignal_bootstrap.dart';
import 'push_notification_service.dart';
import 'push_navigation_handler.dart';
import 'push_registrar.dart';

/// Oturum açıldığında push eşlemesi ve token kaydı.
/// İzin diyaloğu shell ilk frame'inden sonra gecikmeli açılır.
class PushLifecycleListener extends ConsumerStatefulWidget {
  const PushLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleListener> createState() =>
      _PushLifecycleListenerState();
}

class _PushLifecycleListenerState extends ConsumerState<PushLifecycleListener> {
  Timer? _pushSyncTimer;
  bool _pushSyncing = false;

  @override
  void initState() {
    super.initState();
    bindPushRegistrarTokenRefresh(() {
      if (!mounted) return;
      ref.read(pushRegistrarProvider).registerIfPossible(allowTokenRetry: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PushNavigationHandler.install(
        ref.read(goRouterProvider),
        onReceived: _onPushReceived,
        onFortuneInviteData: (data) {
          final invite = parseFortuneIncomingPayload(data);
          if (invite != null) {
            ref.read(fortuneIncomingInviteProvider.notifier).enqueue(invite);
          }
        },
        onSessionUpdateData: (update) {
          if (!update.isAccepted) return;
          unawaited(
            LiveFortuneFlow.resumeSessionFromPush(
              router: ref.read(goRouterProvider),
              sessionId: update.sessionId,
              tellerId: update.tellerId,
              repo: ref.read(liveFortuneRepositoryProvider),
            ),
          );
        },
      );
      _queuePushSync(null, ref.read(authControllerProvider));
    });

    ref.listenManual<AsyncValue<UserEntity?>>(
      authControllerProvider,
      _queuePushSync,
    );
  }

  void _queuePushSync(
    AsyncValue<UserEntity?>? previous,
    AsyncValue<UserEntity?> next,
  ) {
    _pushSyncTimer?.cancel();
    // Sistem izin diyaloğunu shell ilk frame'inden sonra açarak geçiş
    // bariyerleriyle çakışmasını önler.
    _pushSyncTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      unawaited(_syncPushForAuth(previous, next));
    });
  }

  Future<void> _syncPushForAuth(
    AsyncValue<UserEntity?>? previous,
    AsyncValue<UserEntity?> next,
  ) async {
    if (_pushSyncing) return;
    _pushSyncing = true;
    try {
      final user = next.valueOrNull;
      if (user == null) {
        if (previous?.valueOrNull != null) {
          ref.read(pushRegistrarProvider).forgetLastRegistration();
          await OneSignalBootstrap.logout();
        }
        return;
      }

      await OneSignalBootstrap.login(user.id);
      if (OneSignalBootstrap.isReady) {
        if (!OneSignalBootstrap.permissionGranted) {
          await OneSignalBootstrap.requestPermission();
        }
      } else if (!PushNotificationService.instance.permissionGranted) {
        await PushNotificationService.instance.requestSystemPermission();
      }

      await ref
          .read(pushRegistrarProvider)
          .registerIfPossible(allowTokenRetry: true);
    } finally {
      _pushSyncing = false;
    }
  }

  void _onPushReceived() {
    if (!mounted) return;
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsListNotifierProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
  }

  @override
  void dispose() {
    _pushSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
