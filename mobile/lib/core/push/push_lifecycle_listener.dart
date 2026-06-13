import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/home/presentation/providers/fortune_incoming_invite_provider.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../onesignal/onesignal_bootstrap.dart';
import 'push_navigation_handler.dart';
import 'push_registrar.dart';

/// Oturum açıldığında FCM kaydı. Bildirim izni otomatik istenmez (gri barrier riski);
/// kullanıcı Bildirimler sayfasındaki banner ile açar.
class PushLifecycleListener extends ConsumerStatefulWidget {
  const PushLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleListener> createState() =>
      _PushLifecycleListenerState();
}

class _PushLifecycleListenerState extends ConsumerState<PushLifecycleListener> {
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
        if (prev?.valueOrNull != null) {
          unawaited(OneSignalBootstrap.logout());
        }
        return;
      }

      unawaited(OneSignalBootstrap.login(user.id));
      ref.read(pushRegistrarProvider).registerIfPossible();
    });
  }

  void _onPushReceived() {
    if (!mounted) return;
    ref.invalidate(notificationsListProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
