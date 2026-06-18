/// Üretim `GET /api/room/{sessionId}/stream` SSE olay türleri.
enum LiveFortuneRoomSseKind {
  connected,
  message,
  messages,
  timerStarted,
  roomUpdate,
  sessionUpdate,
  sessionEnded,
  unknown,
}

LiveFortuneRoomSseKind liveFortuneRoomSseKindFrom(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'connected':
      return LiveFortuneRoomSseKind.connected;
    case 'message':
    case 'chatmessage':
    case 'roommessage':
      return LiveFortuneRoomSseKind.message;
    case 'messages':
      return LiveFortuneRoomSseKind.messages;
    case 'timer_started':
    case 'timerstarted':
    case 'timer':
    case 'start_timer':
      return LiveFortuneRoomSseKind.timerStarted;
    case 'room':
    case 'room_update':
    case 'roomupdate':
    case 'ping':
    case 'extend':
    case 'teller_add_time':
      return LiveFortuneRoomSseKind.roomUpdate;
    case 'session_update':
    case 'sessionupdate':
    case 'status':
    case 'session_status':
    case 'accepted':
    case 'rejected':
    case 'cancelled':
    case 'active':
      return LiveFortuneRoomSseKind.sessionUpdate;
    case 'ended':
    case 'end':
    case 'session_end':
    case 'sessionended':
    case 'completed':
      return LiveFortuneRoomSseKind.sessionEnded;
    default:
      return LiveFortuneRoomSseKind.unknown;
  }
}
