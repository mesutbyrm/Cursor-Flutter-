import '../../data/services/voice_room_debug_log.dart';

/// Oda oturumu / callback / koltuk isteği tanılama (release'te de yazılır).
abstract final class VoiceRoomLifecycleTrace {
  static void lifecycle({
    required String roomId,
    required int generation,
    required bool active,
    String? step,
  }) {
    VoiceRoomDebugLog.log('ROOM_LIFECYCLE', {
      'roomId': roomId,
      'generation': generation,
      'ACTIVE': active,
      if (step != null) 'step': step,
    });
  }

  static void callback({
    required String type,
    required String callbackRoomId,
    String? activeRoomId,
    required bool accepted,
    int? generation,
    int? boundGeneration,
    bool disposed = false,
  }) {
    VoiceRoomDebugLog.log('ROOM_CALLBACK', {
      'type': type,
      'callbackRoomId': callbackRoomId,
      'activeRoomId': activeRoomId ?? '',
      'disposed': disposed,
      'accepted': accepted,
      if (generation != null) 'generation': generation,
      if (boundGeneration != null) 'boundGeneration': boundGeneration,
    });
  }

  static void seatRequest({
    required String action,
    required String roomId,
    int? seatId,
    int? generation,
    int? httpStatus,
    String? detail,
  }) {
    VoiceRoomDebugLog.log('SEAT_REQUEST', {
      'action': action,
      'roomId': roomId,
      if (seatId != null) 'seatId': seatId,
      if (generation != null) 'generation': generation,
      if (httpStatus != null) 'httpStatus': httpStatus,
      if (detail != null) 'detail': detail,
    });
  }
}
