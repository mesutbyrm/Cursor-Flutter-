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
        n == 'pkrequest' ||
        n == 'pk_requested' ||
        n == 'pkrequested';
  }

  static bool isPkScoreEvent(String? raw) {
    final n = raw?.toLowerCase().trim() ?? '';
    return n == 'pk_score' ||
        n == 'pkscore' ||
        n == 'pk_score_updated' ||
        n == 'pkscoreupdated' ||
        n == 'pk_battle_updated' ||
        n == 'pkbattleupdated';
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
