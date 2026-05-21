import 'package:go_router/go_router.dart';

import 'entities/app_notification_entity.dart';

/// Bildirime tıklanınca hedef route.
void navigateFromNotification(GoRouter router, AppNotificationEntity n) {
  final path = n.targetPath?.trim();
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('/user/') && n.targetId != null) {
      router.push('/user/${n.targetId}');
      return;
    }
    if (path.contains(':id') && n.targetId != null) {
      router.push(path.replaceFirst(':id', n.targetId!));
      return;
    }
    router.push(path);
    return;
  }

  switch (n.type?.toLowerCase()) {
    case 'cfc_payment_request':
    case 'cfc_payment_approved':
    case 'cfc_payment_rejected':
      router.push('/cfc-store');
      return;
    case 'jeton_payment_request':
    case 'jeton_payment_approved':
    case 'jeton_payment_rejected':
      router.push('/jeton-store');
      return;
    case 'payment':
    case 'jeton':
      router.push('/jeton-store');
      return;
    case 'gift':
    case 'live':
      router.go('/live');
      return;
    case 'message':
    case 'chat':
      router.go('/messages');
      return;
    case 'social':
      router.go('/social');
      return;
    case 'membership':
      router.push('/premium-membership');
      return;
    case 'admin_payment':
    case 'admin':
      router.push('/admin');
      return;
    default:
      break;
  }
}
