import '../../domain/entities/live_fortune_session_entity.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';

/// Bildirim listesi / push → falcı davet modeli (§15 PATCH sessions).
FortuneIncomingSession? fortuneInviteFromNotification(AppNotificationEntity n) {
  final type = (n.type ?? '').toLowerCase();
  final path = (n.targetPath ?? '').toLowerCase();
  final isFortuneInvite = type.contains('session_request') ||
      type.contains('fortune_session') ||
      type.contains('live_fortune') ||
      type.contains('fortune_teller') ||
      type.contains('fortune') ||
      type.contains('falc') ||
      path.contains('fal') ||
      path.contains('session');
  if (!isFortuneInvite) return null;

  final sessionId = _sessionIdFromNotification(n);
  if (sessionId == null || sessionId.isEmpty) return null;

  return FortuneIncomingSession(
    sessionId: sessionId,
    clientId: '',
    clientName: _clientNameFromNotification(n),
    tellerId: '',
    durationMinutes: 10,
    totalJeton: 0,
    category: 'general',
  );
}

String? _sessionIdFromNotification(AppNotificationEntity n) {
  final target = n.targetId?.trim();
  if (target != null && target.isNotEmpty) return target;

  final path = n.targetPath?.trim() ?? '';
  if (path.isNotEmpty) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final last = segments.last;
      if (last.length >= 8 && last != 'dashboard' && last != 'session') {
        return last;
      }
    }
  }
  return null;
}

String _clientNameFromNotification(AppNotificationEntity n) {
  final title = n.title.trim();
  if (title.isEmpty) return 'Danışan';
  const prefixes = [
    'Canlı fal isteği:',
    'Canlı Fal İsteği:',
    'Yeni fal talebi:',
    'Yeni seans isteği:',
  ];
  for (final prefix in prefixes) {
    if (title.startsWith(prefix)) {
      final name = title.substring(prefix.length).trim();
      if (name.isNotEmpty) return name;
    }
  }
  return title;
}

bool isFortuneInviteNotification(AppNotificationEntity n) =>
    fortuneInviteFromNotification(n) != null;
