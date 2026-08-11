import '../../features/voice_hub/domain/entities/chat_room_sse_event.dart';

/// Voice/live SSE event adı normalizasyonu — tek parser kaynağı.
abstract final class RoomRealtimeEventParser {
  static ChatRoomSseEventType voiceSseType(String? raw) =>
      chatRoomSseEventTypeFrom(raw);

  static bool isPkInviteEvent(String? raw) {
    final n = raw?.toLowerCase().trim() ?? '';
    return n == 'pk_invite' ||
        n == 'pkinvite' ||
        n == 'pk_request' ||
        n == 'pkrequest';
  }

  static bool isGiftEvent(String? raw) {
    final t = voiceSseType(raw);
    return t == ChatRoomSseEventType.gift;
  }

  static bool isPresenceEvent(String? raw) {
    final t = voiceSseType(raw);
    return t == ChatRoomSseEventType.presence ||
        t == ChatRoomSseEventType.userJoin ||
        t == ChatRoomSseEventType.userLeave;
  }

  static bool payloadLooksLikePk(Map<String, dynamic> data) {
    if (data.isEmpty) return false;
    return data.containsKey('battle') ||
        data.containsKey('battleId') ||
        data.containsKey('inviteId') ||
        data.containsKey('pkBattle') ||
        data['status']?.toString() == 'pending' ||
        data['status']?.toString() == 'invited';
  }
}
