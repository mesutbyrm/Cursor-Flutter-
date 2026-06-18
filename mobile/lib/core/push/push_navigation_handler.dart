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
  static final List<Map<String, dynamic>> _bufferedFortunePayloads = [];

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
    _drainBufferedFortunePayloads();
  }

  static void _drainBufferedFortunePayloads() {
    if (onFortuneInvite == null || _bufferedFortunePayloads.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_bufferedFortunePayloads);
    _bufferedFortunePayloads.clear();
    for (final data in copy) {
      handleFortuneInviteData(data, notifyReceived: false);
    }
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

  static bool handleFortuneInviteData(
    Map<String, dynamic>? data, {
    bool notifyReceived = true,
  }) {
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
    if (onFortuneInvite == null) {
      _bufferedFortunePayloads.add(Map<String, dynamic>.from(data));
      return true;
    }
    onFortuneInvite!.call(data);
    if (notifyReceived) {
      onPushReceived?.call();
    }
    return true;
  }

  static void handleAdditionalData(Map<String, dynamic>? data) {
    if (handleFortuneInviteData(data, notifyReceived: false)) return;
    onPushReceived?.call();

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
