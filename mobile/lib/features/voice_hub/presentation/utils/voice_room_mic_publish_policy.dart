/// TRTC yerel ses yayını — koltuk zorunluluğu (UI mic state ayrı tutulabilir).
abstract final class VoiceRoomMicPublishPolicy {
  static bool mayPublishTrtcMic(int? selfSeatIndex) =>
      selfSeatIndex != null && selfSeatIndex >= 1;
}
