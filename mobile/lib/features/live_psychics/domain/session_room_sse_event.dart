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

  if (_ssePayloadLooksLikeTip(map)) {
    return 'tip_received';
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

bool _ssePayloadLooksLikeTip(Map<String, dynamic> map) {
  final nested = map['data'] is Map
      ? Map<String, dynamic>.from(map['data'] as Map)
      : map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : null;
  final sources = <Map<String, dynamic>>[map];
  if (nested != null) sources.add(nested);

  for (final src in sources) {
    final amount = src['amount'] ??
        src['jeton'] ??
        src['tipAmount'] ??
        src['giftValue'] ??
        src['coins'] ??
        src['coin'] ??
        src['price'] ??
        src['value'];
    if (amount is num && amount > 0) return true;
    final parsed = int.tryParse(amount?.toString() ?? '');
    if (parsed != null && parsed > 0) return true;
  }
  return false;
}

bool isSessionRoomSseCommentBlock(String block) {
  final trimmed = block.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.split('\n').every((line) {
    final t = line.trim();
    return t.isEmpty || t.startsWith(':');
  });
}
