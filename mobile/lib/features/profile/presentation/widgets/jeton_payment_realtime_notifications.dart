import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/push_notification_service.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../providers/profile_providers.dart';

bool isJetonPaymentResultNotificationType(String? type) {
  final t = type?.toLowerCase().trim() ?? '';
  return t == 'jeton_payment_approved' || t == 'jeton_payment_rejected';
}

/// SSE / push ile gelen jeton ödeme sonucu — anında sistem bildirimi + cüzdan yenileme.
Future<void> handleJetonPaymentResultNotification(
  WidgetRef ref,
  AppNotificationEntity notification,
) async {
  if (!isJetonPaymentResultNotificationType(notification.type)) return;

  ref.refreshWalletCache(force: true);

  final approved =
      notification.type?.toLowerCase() == 'jeton_payment_approved';
  final title = notification.title.trim().isNotEmpty
      ? notification.title.trim()
      : (approved ? 'Jeton yüklendi' : 'Ödeme reddedildi');
  final body = notification.body?.trim().isNotEmpty == true
      ? notification.body!.trim()
      : (approved
          ? 'Jeton bakiyeniz hesabınıza yüklendi.'
          : 'Ödeme talebiniz reddedildi.');

  await PushNotificationService.instance.showLocal(
    id: notification.id.hashCode,
    title: title,
    body: body,
    payload: notification.targetPath ?? '/jeton-store',
    urgent: true,
  );
}
