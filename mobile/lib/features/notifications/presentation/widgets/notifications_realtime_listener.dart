import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/presentation/global/global_gift_event_bridge.dart';
import '../../data/services/notifications_sse_service.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../../live/presentation/providers/live_pk_invite_signal_provider.dart';
import '../../../live/presentation/providers/live_pk_streams_provider.dart';
import '../../../live/presentation/providers/pk_room_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../messages/presentation/providers/conversations_list_notifier.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../messages/presentation/widgets/dm_realtime_listener.dart';
import '../../../social/presentation/services/social_fortune_feed_sync.dart';
import '../providers/notification_event_gate_provider.dart';
import '../providers/notifications_list_notifier.dart';
import '../providers/notifications_providers.dart';
import '../../../inbox/presentation/providers/in_app_banner_provider.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../profile/presentation/widgets/jeton_payment_realtime_notifications.dart';

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
    final gate = ref.read(notificationEventGateProvider);
    if (!gate.shouldProcessRealtime(notification.id)) return;

    ref.read(notificationsListNotifierProvider.notifier).prepend(notification);
    ref.invalidate(notificationsUnreadApiProvider);
    handleNotificationGiftForGlobalOverlay(ref, notification);
    final type = notification.type?.toLowerCase() ?? '';

    // Uygulama içi banner — mesaj veya sistem bildirimi hangi ekranda olursa
    // olsun ekranın üstünden düşer. Açık olan DM için mesaj banner'ı bastırılır.
    final isMessageType = type.contains('message') ||
        type.contains('chat') ||
        type.contains('dm');
    final sender = notification.senderId?.trim() ?? '';
    final openDm = ref.read(openDmConversationIdProvider);
    final suppress = isMessageType && sender.isNotEmpty && sender == openDm;
    if (!suppress) {
      final target = notification.targetPath?.trim() ?? '';
      final route = isMessageType
          ? (sender.isNotEmpty ? '/chat/$sender' : '/messages')
          : (target.isNotEmpty ? target : '/notifications');
      final canManagePayments =
          ref.read(staffAccessProvider).canManagePayments;
      ref.read(inAppBannerProvider.notifier).show(
            InAppBannerEvent(
              key: notification.id,
              title: notification.title,
              body: notification.body ?? '',
              kind: isMessageType
                  ? InAppBannerKind.message
                  : InAppBannerKind.system,
              route: route,
              avatarUrl: notification.imageUrl,
              // Sistem bildirimleri (ödeme talebi vb.) kanonik yönlendirmeyle
              // admin onay alanına gitsin; mesajlar sohbete.
              notification: isMessageType ? null : notification,
              staffCanManagePayments: canManagePayments,
            ),
          );
    }
    if (isJetonPaymentResultNotificationType(type)) {
      unawaited(handleJetonPaymentResultNotification(ref, notification));
    }
    if (type.contains('pk')) {
      ref.invalidate(pkPendingInvitesProvider);
      ref.invalidate(livePkStreamsProvider);
      ref.read(livePkInviteSignalProvider.notifier).bump();
    }
    if (type == 'fortune_share' || type.contains('fortune_share')) {
      unawaited(
        ref.read(socialFortuneFeedSyncProvider).onFortuneShareNotification(
              postId: notification.targetId,
            ),
      );
    }
    if (type.contains('message') ||
        type.contains('chat') ||
        type.contains('dm')) {
      unawaited(
        ref.read(conversationsListNotifierProvider.notifier).refresh(
              silent: true,
              forceRefresh: true,
            ),
      );
      ref.invalidate(conversationsProvider);
      refreshOpenDmChat(ref, ref.read(openDmConversationIdProvider));
    }
    if (type.contains('live') ||
        type.contains('stream') ||
        type.contains('gift') ||
        type.contains('voice')) {
      invalidateHomeKeepAliveProviders(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      final wasIn = prevUser != null;
      final isIn = nextUser != null;
      if (!wasIn && isIn) {
        unawaited(_connect());
      } else if (wasIn && !isIn) {
        unawaited(_disconnect());
      } else if (wasIn &&
          isIn &&
          prevUser!.id != nextUser!.id) {
        unawaited(_disconnect());
        unawaited(_connect());
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
