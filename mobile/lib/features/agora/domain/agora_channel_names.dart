/// Agora kanal adı — üretim sözleşmesi: `room_{id}`.
class AgoraChannelNames {
  AgoraChannelNames._();

  /// Ham oda/kanal kimliğini Agora `joinChannel` formatına çevirir.
  static String forRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) return '';
    if (id.startsWith('room_') ||
        id.startsWith('voice_room_') ||
        id.startsWith('live-')) {
      return id;
    }
    return 'room_$id';
  }

  /// Sesli sohbet odası — web ile aynı: `voice_room_{prismaId}`.
  static String forVoiceRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) return '';
    if (id.startsWith('voice_room_') ||
        id.startsWith('room_') ||
        id.startsWith('live-')) {
      return id;
    }
    return 'voice_room_$id';
  }
}
