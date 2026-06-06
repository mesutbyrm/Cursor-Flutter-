/// Üretim SSE `data:` JSON — `type` alanı zorunlu.
enum VoiceRoomSseKind {
  connected,
  typing,
  presence,
  userJoined,
  userLeft,
  message,
  gift,
  dj,
  unknown,
}

VoiceRoomSseKind voiceRoomSseKindFrom(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'connected':
      return VoiceRoomSseKind.connected;
    case 'typing':
      return VoiceRoomSseKind.typing;
    case 'presence':
    case 'roomusers':
    case 'presenceupdated':
    case 'users':
      return VoiceRoomSseKind.presence;
    case 'userjoined':
    case 'join':
      return VoiceRoomSseKind.userJoined;
    case 'userleft':
    case 'leave':
      return VoiceRoomSseKind.userLeft;
    case 'message':
    case 'chatmessage':
    case 'roommessage':
      return VoiceRoomSseKind.message;
    case 'gift':
    case 'giftsent':
      return VoiceRoomSseKind.gift;
    case 'dj':
    case 'music':
      return VoiceRoomSseKind.dj;
    default:
      return VoiceRoomSseKind.unknown;
  }
}
