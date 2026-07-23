/// Canlı fal seans SSE — `GET /api/room/{sessionId}/stream`.
///
/// Bu kanal olayları **ham** gönderir; `type` alanı yoktur (doküman §17.1).
/// Alanlara bakarak olay türü çıkarılır.
String? inferSessionRoomSseEventType(
  Map<String, dynamic> map, {
  String? eventName,
}) {
  final explicit = (map['type'] ?? eventName ?? '').toString().trim().toLowerCase();
  if (explicit.isNotEmpty) return explicit;

  if (map.containsKey('actualMinutesUsed') || map.containsKey('endedBy')) {
    return 'session_ended';
  }
  if (map.containsKey('addedMinutes') && map.containsKey('newMaxMinutes')) {
    return 'time_extended';
  }
  if (map.containsKey('timerStartedAt')) {
    return 'timer_started';
  }

  final message = map['message']?.toString().trim() ?? '';
  if (message.isNotEmpty &&
      (map.containsKey('senderId') ||
          map.containsKey('id') ||
          map.containsKey('createdAt'))) {
    return 'message';
  }

  if (map.containsKey('sessionId') &&
      (map.containsKey('isUser') ||
          map.containsKey('isTeller') ||
          map.containsKey('status'))) {
    return 'connected';
  }

  return null;
}

bool isSessionRoomSseCommentBlock(String block) {
  final trimmed = block.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.split('\n').every((line) {
    final t = line.trim();
    return t.isEmpty || t.startsWith(':');
  });
}
