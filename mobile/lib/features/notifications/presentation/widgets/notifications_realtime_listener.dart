import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/notifications_sse_service.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../providers/notifications_list_notifier.dart';
import '../providers/notifications_providers.dart';

final notificationsSseServiceProvider = Provider<NotificationsSseService>((ref) {
  final service = NotificationsSseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Bildirim SSE — web ile aynı `GET /api/notifications/stream`.
class NotificationsRealtimeListener extends ConsumerStatefulWidget {
  const NotificationsRealtimeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsRealtimeListener> createState() =>
      _NotificationsRealtimeListenerState();
}

class _NotificationsRealtimeListenerState
    extends ConsumerState<NotificationsRealtimeListener> {
  StreamSubscription<AppNotificationEntity>? _sub;
  var _connected = false;

  @override
  void dispose() {
    unawaited(_disconnect());
    super.dispose();
  }

  Future<void> _connect() async {
    if (_connected) return;
    _connected = true;
    final service = ref.read(notificationsSseServiceProvider);
    final storage = ref.read(tokenStorageProvider);
    final dio = ref.read(dioProvider);
    await service.openConnection(
      accessToken: storage.readAccess,
      refreshTokens: () => tryRefreshAccessToken(dio, storage),
    );
    _sub = service.events.listen(_onNotification);
  }

  Future<void> _disconnect() async {
    _connected = false;
    await _sub?.cancel();
    _sub = null;
    await ref.read(notificationsSseServiceProvider).disconnect();
  }

  void _onNotification(AppNotificationEntity notification) {
    ref.read(notificationsListNotifierProvider.notifier).prepend(notification);
    ref.invalidate(notificationsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      final wasIn = prev?.valueOrNull != null;
      final isIn = next.valueOrNull != null;
      if (!wasIn && isIn) {
        unawaited(_connect());
      } else if (wasIn && !isIn) {
        unawaited(_disconnect());
      }
    });

    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user != null && !_connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_connect());
      });
    }

    return widget.child;
  }
}
