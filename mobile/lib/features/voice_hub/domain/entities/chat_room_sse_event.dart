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
  songStarted,
  songPaused,
  songResumed,
  songFinished,
  queueUpdated,
  songRemoved,
  songChanged,
  playerState,
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
    case 'song_started':
      return ChatRoomSseEventType.songStarted;
    case 'song_paused':
      return ChatRoomSseEventType.songPaused;
    case 'song_resumed':
      return ChatRoomSseEventType.songResumed;
    case 'song_finished':
      return ChatRoomSseEventType.songFinished;
    case 'queue_updated':
      return ChatRoomSseEventType.queueUpdated;
    case 'song_removed':
      return ChatRoomSseEventType.songRemoved;
    case 'song_changed':
      return ChatRoomSseEventType.songChanged;
    case 'player_state':
      return ChatRoomSseEventType.playerState;
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
    case 'gift_sent':
    case 'gift-sent':
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
    case 'pk_score':
    case 'pkscore':
    case 'pk_invite':
    case 'pkinvite':
    case 'pk_request':
    case 'pkrequest':
    case 'pk_ended':
    case 'pkended':
    case 'pk_accepted':
    case 'pkaccepted':
    case 'pk_rejected':
    case 'pkrejected':
    case 'pk_started':
    case 'pkstarted':
    case 'pk_score_updated':
    case 'pkscoreupdated':
    case 'gift_ranking_updated':
    case 'giftrankingupdated':
      return ChatRoomSseEventType.pk;
    case 'room_event':
    case 'roomevent':
    case 'seat_update':
    case 'seatupdate':
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
