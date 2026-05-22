import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'push_notification_service.dart';
import 'push_registrar.dart';

/// Oturum açıldığında FCM kaydı ve bildirim izni isteği.
class PushLifecycleListener extends ConsumerStatefulWidget {
  const PushLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleListener> createState() =>
      _PushLifecycleListenerState();
}

class _PushLifecycleListenerState extends ConsumerState<PushLifecycleListener> {
  var _askedPermission = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null) return;
      ref.read(pushRegistrarProvider).registerIfPossible();
      if (!_askedPermission) {
        _askedPermission = true;
        PushNotificationService.instance.requestSystemPermission();
      }
    });

    return widget.child;
  }
}
