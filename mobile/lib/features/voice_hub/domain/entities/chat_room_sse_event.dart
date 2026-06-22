/// Üretim `GET /api/chat/rooms/{roomId}/stream` SSE olayları.
enum ChatRoomSseEventType {
  connected,
  heartbeat,
  message,
  dj,
  song,
  music,
  userJoin,
  userLeave,
  roomUpdate,
  moderation,
  announcement,
  gift,
  presence,
  fortuneRequest,
  pk,
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
      return ChatRoomSseEventType.dj;
    case 'song':
    case 'songrequest':
    case 'song_request':
      return ChatRoomSseEventType.song;
    case 'music':
      return ChatRoomSseEventType.music;
    case 'user_join':
    case 'userjoined':
    case 'join':
      return ChatRoomSseEventType.userJoin;
    case 'user_leave':
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
    case 'fal_request':
    case 'live_fal_request':
    case 'fortune_request':
      return ChatRoomSseEventType.fortuneRequest;
    // PK Battle — backend resmi sözleşmesi: SSE "type": "pk".
    // Eski Socket.IO event isimleri de uyumluluk için eşlenir
    // (sunucu geçiş döneminde her ikisini de gönderebilir).
    case 'pk':
    case 'pkbattle':
    case 'pkbattleupdated':
    case 'pk_updated':
    case 'pk:invite':
    case 'pk:accept':
    case 'pk:reject':
    case 'pk:start':
    case 'pk:score-update':
    case 'pk:gift':
    case 'pk:end':
    case 'pk:winner':
      return ChatRoomSseEventType.pk;
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
