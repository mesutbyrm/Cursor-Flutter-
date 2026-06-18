import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/providers/fortune_incoming_invite_provider.dart';
import '../../features/notifications/domain/entities/app_notification_entity.dart';
import '../../features/notifications/domain/notification_action.dart';

/// OneSignal `additionalData` → uygulama içi sayfa.
class PushNavigationHandler {
  PushNavigationHandler._();

  static GoRouter? _router;
  static void Function()? onPushReceived;
  static void Function(Map<String, dynamic> data)? onFortuneInvite;
  static void Function(FortuneSessionUpdatePayload update)? onSessionUpdate;

  static void install(
    GoRouter router, {
    void Function()? onReceived,
    void Function(Map<String, dynamic> data)? onFortuneInviteData,
    void Function(FortuneSessionUpdatePayload update)? onSessionUpdateData,
  }) {
    _router = router;
    onPushReceived = onReceived;
    onFortuneInvite = onFortuneInviteData;
    onSessionUpdate = onSessionUpdateData;
  }

  static void navigateToPath(String path) {
    final router = _router;
    if (router == null || path.isEmpty) return;
    final normalized = path.startsWith('/') ? path : '/$path';
    try {
      router.go(normalized);
    } catch (e, st) {
      debugPrint('Push path navigation failed: $e\n$st');
    }
  }

  static bool handleFortuneInviteData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return false;

    final sessionUpdate = parseSessionUpdatePayload(data);
    if (sessionUpdate != null) {
      onSessionUpdate?.call(sessionUpdate);
      if (sessionUpdate.isRejected) {
        _router?.go('/canli-falcilar');
      }
      return true;
    }

    final invite = parseFortuneIncomingPayload(data);
    if (invite == null) return false;
    onFortuneInvite?.call(data);
    return true;
  }

  static void handleAdditionalData(Map<String, dynamic>? data) {
    onPushReceived?.call();
    if (handleFortuneInviteData(data)) return;

    final router = _router;
    if (router == null || data == null || data.isEmpty) return;

    final type = [
      data['type'],
      data['event'],
      data['notificationType'],
    ].whereType<String>().map((s) => s.toLowerCase()).join(' ');

    if (type.contains('session_ended')) {
      router.go('/canli-falcilar');
      return;
    }

    final entity = AppNotificationEntity(
      id: data['id']?.toString() ?? 'push',
      title: data['title']?.toString() ?? 'Canlifal',
      body: data['body']?.toString(),
      type: data['type']?.toString(),
      targetPath: data['targetPath']?.toString(),
      targetId: data['targetId']?.toString(),
    );

    try {
      navigateFromNotification(router, entity);
    } catch (e, st) {
      debugPrint('Push navigation failed: $e\n$st');
    }
  }
}
