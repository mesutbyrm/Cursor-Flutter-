import 'package:go_router/go_router.dart';

import 'entities/app_notification_entity.dart';

/// Bildirime tıklanınca hedef route.
void navigateFromNotification(
  GoRouter router,
  AppNotificationEntity n, {
  bool staffCanManagePayments = false,
}) {
  final path = n.targetPath?.trim();
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      _pushInAppPath(router, Uri.parse(path).path);
      return;
    }
    if (path.startsWith('/user/') && n.targetId != null) {
      router.push('/user/${n.targetId}');
      return;
    }
    if (path.contains(':id') && n.targetId != null) {
      router.push(path.replaceFirst(':id', n.targetId!));
      return;
    }
    _pushInAppPath(router, path);
    return;
  }

  final route = _routeFromTypeAndText(n, staffCanManagePayments: staffCanManagePayments);
  if (route != null) {
    _pushInAppPath(router, route);
  }
}

void _pushInAppPath(GoRouter router, String path) {
  final p = path.startsWith('/') ? path : '/$path';
  const tabRoots = {'/feed', '/live', '/social', '/messages', '/profile'};
  if (tabRoots.contains(p) || p == '/canli-falcilar' || p == '/voice-rooms') {
    router.go(p);
    return;
  }
  router.push(p);
}

String? _routeFromTypeAndText(
  AppNotificationEntity n, {
  required bool staffCanManagePayments,
}) {
  final type = (n.type ?? '').toLowerCase();
  final title = n.title.toLowerCase();
  final body = (n.body ?? '').toLowerCase();
  final text = '$title $body';

  switch (type) {
    case 'cfc_payment':
    case 'cfc_payment_request':
      if (staffCanManagePayments) return '/admin';
      return '/cfc-store';
    case 'cfc_payment_approved':
    case 'cfc_payment_rejected':
      return '/cfc-store';
    case 'jeton_payment_request':
    case 'payment_request':
    case 'payment_notification':
      if (staffCanManagePayments) return '/admin';
      return '/jeton-store';
    case 'jeton_payment':
    case 'jeton_payment_approved':
    case 'jeton_payment_rejected':
      return '/jeton-store';
    case 'payment':
    case 'jeton':
      if (staffCanManagePayments && _isPendingPayment(text)) {
        return '/admin';
      }
      return '/jeton-store';
    case 'gift':
    case 'gift_sent':
    case 'gift_received':
    case 'live':
      return '/live';
    case 'fortune_session_invite':
    case 'fortune_session_request':
    case 'session_request':
    case 'psychic_request_created':
    case 'psychic_request':
    case 'request_created':
    case 'live_fortune':
    case 'live_fortune_request':
    case 'fortune_teller':
    case 'appointment_accepted':
    case 'appointment':
    case 'randevu':
    case 'session_update':
    case 'session_ended':
    case 'session_end':
      return '/canli-falcilar';
    case 'message':
    case 'chat':
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/chat/${n.targetId}';
      }
      return '/messages';
    case 'voice_room':
    case 'voice':
    case 'chat_room':
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/voice-room/${n.targetId}';
      }
      return '/voice-rooms';
    case 'follow':
    case 'comment':
    case 'like':
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/user/${n.targetId}';
      }
      return '/social';
    case 'mention':
      if (n.targetPath != null && n.targetPath!.contains('voice-room')) {
        return n.targetPath!;
      }
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/voice-room/${n.targetId}';
      }
      return '/social';
    case 'social':
      return '/social';
    case 'membership':
      return '/premium-membership';
    case 'admin_payment':
    case 'admin':
      return '/admin';
  }

  if (text.contains('ödeme bildirim') ||
      text.contains('yeni ödeme') ||
      text.contains('payment request')) {
    return staffCanManagePayments ? '/admin' : '/jeton-store';
  }
  if (text.contains('ödeme onay') ||
      (text.contains('jeton') && text.contains('eklendi')) ||
      text.contains('cfc')) {
    return '/jeton-store';
  }
  if (text.contains('seans') ||
      text.contains('randevu') ||
      text.contains('fal') ||
      text.contains('falcı')) {
    return '/canli-falcilar';
  }
  if (text.contains('hediye')) {
    return '/live';
  }
  if (text.contains('sesli') || text.contains('sohbet odası')) {
    if (n.targetId != null && n.targetId!.isNotEmpty) {
      return '/voice-room/${n.targetId}';
    }
    return '/voice-rooms';
  }
  if (text.contains('mesaj') || text.contains('sohbet')) {
    if (n.targetId != null && n.targetId!.isNotEmpty) {
      return '/chat/${n.targetId}';
    }
    return '/messages';
  }

  return null;
}

bool _isPendingPayment(String text) {
  return text.contains('yeni') ||
      text.contains('bildirim') ||
      text.contains('talep') ||
      text.contains('bekle');
}
