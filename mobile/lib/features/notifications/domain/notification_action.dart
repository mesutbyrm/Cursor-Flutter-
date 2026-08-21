import 'package:go_router/go_router.dart';

import '../../voice_hub/presentation/utils/voice_room_nav_paths.dart';
import 'entities/app_notification_entity.dart';

typedef VoiceRoomSwitchPreparer = Future<void> Function(
  String nextLiveKey, {
  String source,
});

/// Bildirime tıklanınca hedef route (senkron — unit testler).
void navigateFromNotification(
  GoRouter router,
  AppNotificationEntity n, {
  bool staffCanManagePayments = false,
}) {
  // ignore: discarded_futures
  _navigateFromNotificationImpl(
    router,
    n,
    staffCanManagePayments: staffCanManagePayments,
    pushPath: (router, path) async => _pushInAppPathSync(router, path),
  );
}

/// Push / bildirim — sesli oda geçişinde önce aktif oturumu kapatır.
Future<void> navigateFromNotificationAsync(
  GoRouter router,
  AppNotificationEntity n, {
  bool staffCanManagePayments = false,
  VoiceRoomSwitchPreparer? prepareVoiceRoomSwitch,
}) async {
  await _navigateFromNotificationImpl(
    router,
    n,
    staffCanManagePayments: staffCanManagePayments,
    pushPath: (router, path) => _pushInAppPathAsync(
      router,
      path,
      prepareVoiceRoomSwitch: prepareVoiceRoomSwitch,
    ),
  );
}

Future<void> _navigateFromNotificationImpl(
  GoRouter router,
  AppNotificationEntity n, {
  required bool staffCanManagePayments,
  required Future<void> Function(GoRouter router, String path) pushPath,
}) async {
  final path = n.targetPath?.trim();
  if (path != null && path.isNotEmpty) {
    if (path == '/' || path == '/index' || path == '/home') {
      final fallback = _routeFromTypeAndText(
        n,
        staffCanManagePayments: staffCanManagePayments,
      );
      await pushPath(router, fallback ?? '/feed');
      return;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final shortsId = _shortVideoIdFromUri(uri);
      if (shortsId != null) {
        router.push('/shorts?videoId=$shortsId');
        return;
      }
      await pushPath(router, uri.path);
      return;
    }
    final shortsId = _shortVideoIdFromPath(path);
    if (shortsId != null) {
      router.push('/shorts?videoId=$shortsId');
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
    await pushPath(router, path);
    return;
  }

  final route = _routeFromTypeAndText(n, staffCanManagePayments: staffCanManagePayments);
  if (route != null) {
    await pushPath(router, route);
    return;
  }
  await pushPath(router, '/feed');
}

void _pushInAppPathSync(GoRouter router, String path) {
  _applyInAppPath(router, path);
}

Future<void> _pushInAppPathAsync(
  GoRouter router,
  String path, {
  VoiceRoomSwitchPreparer? prepareVoiceRoomSwitch,
}) async {
  var p = path.startsWith('/') ? path : '/$path';
  final voiceKey = voiceRoomLiveKeyFromPath(p);
  if (voiceKey != null && prepareVoiceRoomSwitch != null) {
    await prepareVoiceRoomSwitch(voiceKey, source: 'notification');
  }
  _applyInAppPath(router, p);
}

void _applyInAppPath(GoRouter router, String path) {
  var p = path.startsWith('/') ? path : '/$path';
  if (p == '/' || p == '/index' || p == '/home') {
    router.go('/feed');
    return;
  }
  const tabRoots = {'/feed', '/live', '/social', '/messages', '/profile'};
  if (tabRoots.contains(p) || p == '/canli-falcilar' || p == '/voice-rooms') {
    router.go(p);
    return;
  }
  if (p.startsWith('/voice-room/') ||
      p.startsWith('/live/') ||
      p.startsWith('/chat/')) {
    router.go(p);
    return;
  }
  router.push(p);
}

String? _shortVideoIdFromPath(String path) {
  final uri = Uri.tryParse(path.startsWith('/') ? path : '/$path');
  if (uri == null) return null;
  return _shortVideoIdFromUri(uri);
}

String? _shortVideoIdFromUri(Uri uri) {
  if (uri.pathSegments.contains('shorts') ||
      uri.path.contains('/short-videos/')) {
    final fromQuery = uri.queryParameters['videoId'] ??
        uri.queryParameters['video_id'] ??
        uri.queryParameters['id'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    final segments = uri.pathSegments;
    final idx = segments.indexWhere(
      (s) => s == 'shorts' || s == 'short-videos',
    );
    if (idx >= 0 && idx + 1 < segments.length) {
      final id = segments[idx + 1];
      if (id.isNotEmpty && id != 'explore' && id != 'upload') return id;
    }
  }
  return null;
}

String? _routeFromTypeAndText(
  AppNotificationEntity n, {
  required bool staffCanManagePayments,
}) {
  final type = (n.type ?? '').toLowerCase();
  final title = n.title.toLowerCase();
  final body = (n.body ?? '').toLowerCase();
  final text = '$title $body';

  if (_isShortVideoNotification(type, text, n)) {
    final videoId = n.targetId;
    if (videoId != null && videoId.isNotEmpty) {
      return '/shorts?videoId=$videoId';
    }
    final fromPath = n.targetPath != null
        ? _shortVideoIdFromPath(n.targetPath!)
        : null;
    if (fromPath != null) return '/shorts?videoId=$fromPath';
  }

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
    case 'pk':
    case 'pk_battle':
    case 'pk_invite':
    case 'pk_request':
    case 'pkbattle':
      if (n.targetPath != null && n.targetPath!.contains('voice-room')) {
        return n.targetPath!;
      }
      if (n.targetPath != null && n.targetPath!.contains('/live')) {
        return n.targetPath!;
      }
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/voice-room/${n.targetId}';
      }
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
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/user/${n.targetId}';
      }
      return '/social';
    case 'comment':
    case 'like':
      if (n.targetPath != null && n.targetPath!.trim().isNotEmpty) {
        return n.targetPath!.startsWith('/') ? n.targetPath! : '/${n.targetPath!}';
      }
      if (_isShortVideoNotification(type, text, n)) {
        if (n.targetId != null && n.targetId!.isNotEmpty) {
          return '/shorts?videoId=${n.targetId}';
        }
      }
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/user/${n.targetId}';
      }
      return '/social';
    case 'short_video_like':
    case 'short_video_comment':
    case 'short_video_follow':
    case 'shorts_like':
    case 'shorts_comment':
    case 'shorts_follow':
    case 'short_video':
    case 'shorts':
      if (n.targetId != null && n.targetId!.isNotEmpty) {
        return '/shorts?videoId=${n.targetId}';
      }
      return '/shorts';
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
  if (text.contains('pk') || text.contains('düello')) {
    if (n.targetPath != null && n.targetPath!.contains('voice-room')) {
      return n.targetPath!;
    }
    if (n.targetId != null && n.targetId!.isNotEmpty) {
      return '/voice-room/${n.targetId}';
    }
    return '/live';
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
  if (text.contains('kısa video') ||
      text.contains('short') ||
      text.contains('reels') ||
      text.contains('tiktok')) {
    if (n.targetId != null && n.targetId!.isNotEmpty) {
      return '/shorts?videoId=${n.targetId}';
    }
    return '/shorts';
  }

  return null;
}

bool _isShortVideoNotification(
  String type,
  String text,
  AppNotificationEntity n,
) {
  if (type.contains('short') || type.contains('shorts')) return true;
  if (text.contains('kısa video') ||
      text.contains('short') ||
      text.contains('reels')) {
    return true;
  }
  final path = n.targetPath?.toLowerCase() ?? '';
  return path.contains('/shorts') || path.contains('short-videos');
}

bool _isPendingPayment(String text) {
  return text.contains('yeni') ||
      text.contains('bildirim') ||
      text.contains('talep') ||
      text.contains('bekle');
}
