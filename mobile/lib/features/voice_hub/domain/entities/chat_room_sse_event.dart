/// Üretim `GET /api/chat/rooms/{roomId}/stream` SSE olayları.
enum ChatRoomSseEventType {
  connected,
  heartbeat,
  message,
  dj,
  song,
  music,
  musicStarted,
  musicStopped,
  userJoin,
  userLeave,
  roomUpdate,
  moderation,
  system,
  announcement,
  gift,
  presence,
  fortuneRequest,
  pk,
  typing,
  roomEvent,
  unknown,
}

ChatRoomSseEventType chatRoomSseEventTypeFrom(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'connected':
      return ChatRoomSseEventType.connected;
    case 'heartbeat':
    case 'ping':
      return ChatRoomSseEventType.heartbeat;
    case 'message':
    case 'chatmessage':
    case 'roommessage':
      return ChatRoomSseEventType.message;
    case 'messages':
      return ChatRoomSseEventType.message;
    case 'dj':
    case 'djevent':
    case 'dj_update':
    case 'djupdate':
      return ChatRoomSseEventType.dj;
    case 'song':
    case 'songrequest':
    case 'song_request':
      return ChatRoomSseEventType.song;
    case 'music':
      return ChatRoomSseEventType.music;
    case 'music_started':
    case 'musicstarted':
    case 'music_start':
      return ChatRoomSseEventType.musicStarted;
    case 'music_stopped':
    case 'musicstopped':
    case 'music_stop':
      return ChatRoomSseEventType.musicStopped;
    case 'user_join':
    case 'user_joined':
    case 'userjoined':
    case 'join':
      return ChatRoomSseEventType.userJoin;
    case 'user_leave':
    case 'user_left':
    case 'userleft':
    case 'leave':
      return ChatRoomSseEventType.userLeave;
    case 'room_update':
    case 'roomupdate':
      return ChatRoomSseEventType.roomUpdate;
    case 'moderation':
    case 'ban':
    case 'mute':
      return ChatRoomSseEventType.moderation;
    case 'system':
      return ChatRoomSseEventType.system;
    case 'announcement':
    case 'duyuru':
      return ChatRoomSseEventType.announcement;
    case 'gift':
    case 'giftsent':
      return ChatRoomSseEventType.gift;
    case 'presence':
    case 'roomusers':
    case 'presenceupdated':
    case 'users':
      return ChatRoomSseEventType.presence;
    case 'typing':
      return ChatRoomSseEventType.typing;
    case 'fal_request':
    case 'live_fal_request':
    case 'fortune_request':
      return ChatRoomSseEventType.fortuneRequest;
    case 'pk':
    case 'pk_battle':
    case 'pkbattle':
    case 'pkbattleupdated':
    case 'pk_battle_updated':
      return ChatRoomSseEventType.pk;
    case 'room_event':
    case 'roomevent':
      return ChatRoomSseEventType.roomEvent;
    default:
      return ChatRoomSseEventType.unknown;
  }
}

class ChatRoomSseEvent {
  const ChatRoomSseEvent({
    required this.type,
    required this.data,
    this.eventName,
  });

  final ChatRoomSseEventType type;
  final Map<String, dynamic> data;
  final String? eventName;
}
