/// SSE ile gelen temel oda olayları (aşama 2).
enum VoiceRoomRealtimeKind {
  join,
  leave,
  micOn,
  micOff,
  mute,
  unmute,
  moderation,
  roomUpdate,
  system,
}

class VoiceRoomRealtimeEvent {
  const VoiceRoomRealtimeEvent({
    required this.kind,
    required this.message,
    required this.at,
  });

  final VoiceRoomRealtimeKind kind;
  final String message;
  final DateTime at;

  static const maxFeedItems = 40;

  static List<VoiceRoomRealtimeEvent> append(
    List<VoiceRoomRealtimeEvent> current,
    VoiceRoomRealtimeEvent event,
  ) {
    final next = [event, ...current];
    if (next.length <= maxFeedItems) return next;
    return next.sublist(0, maxFeedItems);
  }
}
