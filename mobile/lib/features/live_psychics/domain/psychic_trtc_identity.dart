/// Psychic 1:1 TRTC oda kimliği — iş oda id / token trtcRoomId / sessionId
/// aynı kanalın takma adları olabilir. Ham string eşitliği rejoin tetiklemez.
abstract final class PsychicTrtcIdentity {
  static const prefixes = [
    'fortune_room_',
    'voice_room_',
    'room_',
    'live_',
  ];

  /// Prefiksleri soyarak karşılaştırılabilir çekirdek id.
  static String core(String? raw) {
    var id = raw?.trim() ?? '';
    if (id.isEmpty) return '';
    var changed = true;
    while (changed && id.isNotEmpty) {
      changed = false;
      for (final prefix in prefixes) {
        if (id.startsWith(prefix) && id.length > prefix.length) {
          id = id.substring(prefix.length);
          changed = true;
          break;
        }
      }
    }
    return id;
  }

  /// Aynı TRTC kanalı mı? `fortune_room_X`, `room_X`, `X`, sessionId eşleşir.
  static bool sameChannel(
    String? a,
    String? b, {
    String? sessionId,
  }) {
    final ta = a?.trim() ?? '';
    final tb = b?.trim() ?? '';
    if (ta.isNotEmpty && ta == tb) return true;

    final ca = core(ta);
    final cb = core(tb);
    if (ca.isNotEmpty && ca == cb) return true;

    final sid = core(sessionId);
    if (sid.isEmpty) return false;
    if (ca.isNotEmpty && ca == sid && (cb.isEmpty || cb == sid)) return true;
    if (cb.isNotEmpty && cb == sid && (ca.isEmpty || ca == sid)) return true;
    return false;
  }

  /// SSE / GET room `roomId` TRTC'ye yeniden girişi gerektirmez.
  static bool isAliasDrift({
    required String sessionId,
    required String? joinedTrtcRoom,
    required String? incomingRoomId,
  }) {
    if (joinedTrtcRoom == null || joinedTrtcRoom.trim().isEmpty) return false;
    if (incomingRoomId == null || incomingRoomId.trim().isEmpty) return false;
    return sameChannel(
      joinedTrtcRoom,
      incomingRoomId,
      sessionId: sessionId,
    );
  }
}
