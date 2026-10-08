import '../../data/services/voice_room_debug_log.dart';

/// Gerçek cihazda oda çıkışı tanılama — release'te de yazılır (`ROOM_LEAVE`).
abstract final class VoiceRoomLeaveTrace {
  static void log(String step, [Map<String, Object?>? fields]) {
    VoiceRoomDebugLog.log(
      'ROOM_LEAVE',
      {
        'step': step,
        if (fields != null) ...fields,
      },
    );
  }

  static void started({
    required String roomId,
    String? userId,
    int? seatId,
    String? source,
  }) {
    log('leaveRoom started', {
      'roomId': roomId,
      'userId': userId ?? '',
      'seatId': seatId ?? -1,
      if (source != null) 'source': source,
    });
  }
}
