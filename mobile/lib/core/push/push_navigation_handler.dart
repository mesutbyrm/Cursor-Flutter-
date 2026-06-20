import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../features/notifications/domain/entities/app_notification_entity.dart';
import '../../features/notifications/domain/notification_action.dart';

/// OneSignal `additionalData` → uygulama içi sayfa.
class PushNavigationHandler {
  PushNavigationHandler._();

  static GoRouter? _router;
  static void Function()? onPushReceived;
  static void Function(Map<String, dynamic> data)? onFortuneInvite;
  static void Function(PsychicSessionUpdatePayload update)? onSessionUpdate;
  static void Function(PsychicSessionUpdatePayload cancelled)? onSessionCancelled;
  static void Function(PsychicSessionEndedPayload ended)? onSessionEnded;
  static final List<Map<String, dynamic>> _bufferedFortunePayloads = [];

  static void install(
    GoRouter router, {
    void Function()? onReceived,
    void Function(Map<String, dynamic> data)? onFortuneInviteData,
    void Function(PsychicSessionUpdatePayload update)? onSessionUpdateData,
    void Function(PsychicSessionUpdatePayload cancelled)? onSessionCancelledData,
    void Function(PsychicSessionEndedPayload ended)? onSessionEndedData,
  }) {
    _router = router;
    onPushReceived = onReceived;
    onFortuneInvite = onFortuneInviteData;
    onSessionUpdate = onSessionUpdateData;
    onSessionCancelled = onSessionCancelledData;
    onSessionEnded = onSessionEndedData;
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

    final sessionEnded = parsePsychicSessionEndedPayload(data);
    if (sessionEnded != null) {
      onSessionEnded?.call(sessionEnded);
      return true;
    }

    final sessionCancelled = parsePsychicSessionCancelledPayload(data);
    if (sessionCancelled != null) {
      onSessionCancelled?.call(sessionCancelled);
      if (sessionCancelled.isRejected || sessionCancelled.isCancelled) {
        return true;
      }
    }

    final sessionUpdate = parsePsychicSessionUpdatePayload(data);
    if (sessionUpdate != null) {
      onSessionUpdate?.call(sessionUpdate);
      if (sessionUpdate.isRejected || sessionUpdate.isCancelled) {
        onSessionCancelled?.call(sessionUpdate);
      }
      if (sessionUpdate.isRejected) {
        _router?.go('/canli-falcilar');
      }
      return true;
    }

    final invite = parsePsychicIncomingLoose(data);
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
      final ended = parsePsychicSessionEndedPayload(data);
      if (ended != null) {
        onSessionEnded?.call(ended);
      } else {
        router.go('/canli-falcilar');
      }
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
