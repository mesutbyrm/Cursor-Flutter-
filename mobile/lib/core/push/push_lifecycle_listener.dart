import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/providers/fortune_incoming_invite_provider.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../bootstrap/stuck_overlay_guard.dart';
import '../onesignal/onesignal_bootstrap.dart';
import 'push_navigation_handler.dart';
import 'push_notification_service.dart';
import 'push_registrar.dart';

/// Oturum açıldığında FCM kaydı; bildirim izni gecikmeli (giriş geçişi + sistem dialog).
class PushLifecycleListener extends ConsumerStatefulWidget {
  const PushLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleListener> createState() =>
      _PushLifecycleListenerState();
}

class _PushLifecycleListenerState extends ConsumerState<PushLifecycleListener> {
  Timer? _permissionTimer;
  var _permissionScheduled = false;

  @override
  void initState() {
    super.initState();
    bindPushRegistrarTokenRefresh(() {
      if (!mounted) return;
      ref.read(pushRegistrarProvider).registerIfPossible();
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
      );
    });

    ref.listenManual<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null) {
        _permissionTimer?.cancel();
        _permissionScheduled = false;
        if (prev?.valueOrNull != null) {
          unawaited(OneSignalBootstrap.logout());
        }
        return;
      }

      unawaited(OneSignalBootstrap.login(user.id));
      ref.read(pushRegistrarProvider).registerIfPossible();

      final justLoggedIn = prev?.valueOrNull == null;
      if (justLoggedIn && !_permissionScheduled) {
        _scheduleNotificationPermission();
      }
    });
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    super.dispose();
  }

  void _onPushReceived() {
    if (!mounted) return;
    ref.invalidate(notificationsListProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
  }

  /// Giriş animasyonu + overlay kalktıktan sonra izin iste; bitince barrier temizle.
  void _scheduleNotificationPermission() {
    _permissionScheduled = true;
    _permissionTimer?.cancel();
    _permissionTimer = Timer(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      if (ref.read(authControllerProvider).valueOrNull == null) return;

      if (_alreadyGranted()) {
        await ref.read(pushRegistrarProvider).registerIfPossible();
        _clearStuckBarriers('already-granted');
        return;
      }

      await _requestNotificationPermission();
      if (!mounted) return;
      _clearStuckBarriers('after-permission');
    });
  }

  bool _alreadyGranted() {
    if (OneSignalBootstrap.isReady) {
      return OneSignalBootstrap.permissionGranted;
    }
    return PushNotificationService.instance.permissionGranted;
  }

  Future<void> _requestNotificationPermission() async {
    if (OneSignalBootstrap.isReady) {
      final granted = await OneSignalBootstrap.requestPermission();
      if (granted && mounted) {
        await ref.read(pushRegistrarProvider).registerIfPossible();
      }
      return;
    }
    await PushNotificationService.instance.requestSystemPermission();
  }

  void _clearStuckBarriers(String reason) {
    RootOverlayPurge.logRootOverlaySnapshot(reason: reason);
    for (var i = 0; i <= 2; i++) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        StuckOverlayGuard.purgeAfterLogin(reason: '$reason-$i');
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
