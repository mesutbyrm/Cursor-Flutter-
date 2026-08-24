import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../features/notifications/domain/entities/app_notification_entity.dart';
import '../../features/notifications/domain/notification_action.dart';
import '../../features/voice_hub/presentation/utils/voice_room_nav_paths.dart';
import '../navigation/post_login_navigation.dart';

/// OneSignal `additionalData` → uygulama içi sayfa.
class PushNavigationHandler {
  PushNavigationHandler._();

  static GoRouter? _router;
  static bool Function()? isAuthenticated;
  static bool Function()? staffCanManagePayments;
  static VoiceRoomSwitchPreparer? prepareVoiceRoomSwitch;
  static void Function()? onPushReceived;
  static void Function(Map<String, dynamic> data)? onFortuneInvite;
  static void Function(PsychicSessionUpdatePayload update)? onSessionUpdate;
  static void Function(PsychicSessionUpdatePayload cancelled)? onSessionCancelled;
  static void Function(PsychicSessionEndedPayload ended)? onSessionEnded;
  static final List<Map<String, dynamic>> _bufferedFortunePayloads = [];
  static final List<Map<String, dynamic>> _bufferedTapPayloads = [];

  static void install(
    GoRouter router, {
    void Function()? onReceived,
    void Function(Map<String, dynamic> data)? onFortuneInviteData,
    void Function(PsychicSessionUpdatePayload update)? onSessionUpdateData,
    void Function(PsychicSessionUpdatePayload cancelled)? onSessionCancelledData,
    void Function(PsychicSessionEndedPayload ended)? onSessionEndedData,
    VoiceRoomSwitchPreparer? onPrepareVoiceRoomSwitch,
    bool Function()? authenticated,
  }) {
    _router = router;
    isAuthenticated = authenticated;
    prepareVoiceRoomSwitch = onPrepareVoiceRoomSwitch;
    onPushReceived = onReceived;
    onFortuneInvite = onFortuneInviteData;
    onSessionUpdate = onSessionUpdateData;
    onSessionCancelled = onSessionCancelledData;
    onSessionEnded = onSessionEndedData;
    _drainBufferedFortunePayloads();
    _drainBufferedTapPayloads();
  }

  static void _drainBufferedFortunePayloads() {
    if (onFortuneInvite == null || _bufferedFortunePayloads.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_bufferedFortunePayloads);
    _bufferedFortunePayloads.clear();
    for (final data in copy) {
      handleFortuneInviteData(data, notifyReceived: false);
    }
  }

  static void _drainBufferedTapPayloads() {
    if (_bufferedTapPayloads.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_bufferedTapPayloads);
    _bufferedTapPayloads.clear();
    for (final data in copy) {
      unawaited(handleNotificationTap(data));
    }
  }

  static Future<void> navigateToPath(String path) async {
    final router = _router;
    if (router == null || path.isEmpty) return;
    final trimmed = path.trim();
    if (trimmed == '/' || trimmed == '/index' || trimmed == '/home') {
      router.go('/feed');
      return;
    }
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final voiceKey = voiceRoomLiveKeyFromPath(normalized);
    if (voiceKey != null && prepareVoiceRoomSwitch != null) {
      await prepareVoiceRoomSwitch!(voiceKey, source: 'push');
    }
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

  /// Bildirime tıklanınca — ağır liste yenilemesi yapmadan hedef sayfaya git.
  static Future<void> handleNotificationTap(Map<String, dynamic>? data) async {
    if (data == null || data.isEmpty) return;
    if (handleFortuneInviteData(data, notifyReceived: false)) return;

    final router = _router;
    if (router == null) {
      _bufferedTapPayloads.add(Map<String, dynamic>.from(data));
      return;
    }
    await _navigateFromData(router, data);
  }

  /// Geriye dönük — tıklama yolu.
  static void handleAdditionalData(Map<String, dynamic>? data) {
    handleNotificationTap(data);
  }

  static Future<void> _navigateFromData(
    GoRouter router,
    Map<String, dynamic> data,
  ) async {
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

    final targetPath = (data['targetPath'] ??
            data['actionUrl'] ??
            data['link'] ??
            data['href'] ??
            data['deepLink'] ??
            data['deeplink'])
        ?.toString();

    final authed = isAuthenticated?.call() ?? true;
    if (!authed) {
      if (targetPath != null && targetPath.trim().isNotEmpty) {
        PostLoginNavigation.remember(targetPath);
      } else {
        final entity = AppNotificationEntity(
          id: data['id']?.toString() ?? 'push',
          title: data['title']?.toString() ?? 'Canlifal',
          body: data['body']?.toString(),
          type: (data['type'] ?? data['event'] ?? data['notificationType'])
              ?.toString(),
          targetPath: targetPath,
          targetId: (data['targetId'] ??
                  data['conversationId'] ??
                  data['chatId'] ??
                  data['threadId'] ??
                  data['referenceId'] ??
                  data['senderId'])
              ?.toString(),
        );
        final route = _routePreviewForPending(entity);
        if (route != null) PostLoginNavigation.remember(route);
      }
      router.go('/auth/login');
      return;
    }

    final entity = AppNotificationEntity(
      id: data['id']?.toString() ?? 'push',
      title: data['title']?.toString() ?? 'Canlifal',
      body: data['body']?.toString(),
      type: (data['type'] ?? data['event'] ?? data['notificationType'])
          ?.toString(),
      targetPath: targetPath,
      targetId: (data['targetId'] ??
              data['conversationId'] ??
              data['chatId'] ??
              data['threadId'] ??
              data['referenceId'] ??
              data['senderId'])
          ?.toString(),
      senderId: data['senderId']?.toString(),
      imageUrl: (data['imageUrl'] ?? data['avatar'] ?? data['avatarUrl'])
          ?.toString(),
    );

    try {
      await navigateFromNotificationAsync(
        router,
        entity,
        staffCanManagePayments: staffCanManagePayments?.call() ?? false,
        prepareVoiceRoomSwitch: prepareVoiceRoomSwitch,
      );
    } catch (e, st) {
      debugPrint('Push navigation failed: $e\n$st');
      try {
        router.go('/feed');
      } catch (_) {}
    }
  }

  static String? _routePreviewForPending(AppNotificationEntity n) {
    final path = n.targetPath?.trim();
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return Uri.tryParse(path)?.path;
      }
      return path.startsWith('/') ? path : '/$path';
    }
    if (n.targetId != null && n.targetId!.isNotEmpty) {
      final type = (n.type ?? '').toLowerCase();
      if (type.contains('message') || type.contains('chat')) {
        return '/chat/${n.targetId}';
      }
      if (type.contains('follow')) return '/user/${n.targetId}';
    }
    return null;
  }
}
