import 'voice_room_mic_publish_policy.dart';

/// TRTC yerel ses yayını — tek karar noktası (UI mic ikonu ayrı kalabilir).
class VoiceRoomLocalAudioPublishDecision {
  const VoiceRoomLocalAudioPublishDecision({
    required this.allowed,
    this.blockReason,
  });

  final bool allowed;
  final String? blockReason;

  static const notOnSeat = VoiceRoomLocalAudioPublishDecision(
    allowed: false,
    blockReason: 'not_on_seat',
  );

  static const noSession = VoiceRoomLocalAudioPublishDecision(
    allowed: false,
    blockReason: 'no_session',
  );

  static const micOff = VoiceRoomLocalAudioPublishDecision(
    allowed: false,
    blockReason: 'mic_off',
  );
}

abstract final class VoiceRoomLocalAudioPublish {
  /// [seatIndexFromSlots] — yalnızca koltuk haritası (presence.seatIndex güvenilmez).
  static VoiceRoomLocalAudioPublishDecision evaluate({
    required bool sessionActive,
    required String? userId,
    required int? seatIndexFromSlots,
    required bool micIntentOn,
  }) {
    if (!sessionActive) return VoiceRoomLocalAudioPublishDecision.noSession;
    final uid = userId?.trim() ?? '';
    if (uid.isEmpty) return VoiceRoomLocalAudioPublishDecision.noSession;
    if (!VoiceRoomMicPublishPolicy.mayPublishTrtcMic(seatIndexFromSlots)) {
      return VoiceRoomLocalAudioPublishDecision.notOnSeat;
    }
    if (!micIntentOn) {
      return VoiceRoomLocalAudioPublishDecision.micOff;
    }
    return const VoiceRoomLocalAudioPublishDecision(allowed: true);
  }
}
