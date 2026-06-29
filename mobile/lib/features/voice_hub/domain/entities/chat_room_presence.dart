import 'chat_room_message.dart';

class ChatRoomPresence extends ChatRoomUserRef {
  const ChatRoomPresence({
    required super.id,
    required super.name,
    super.nickname,
    super.image,
    super.chatRole,
    super.roleSymbol,
    super.membership,
    this.seatIndex,
    this.isSpeaking = false,
    this.isMuted = false,
  });

  factory ChatRoomPresence.fromJson(Map<String, dynamic> json) {
    final base = ChatRoomUserRef.fromJson(json);
    return ChatRoomPresence(
      id: base.id,
      name: base.name,
      nickname: base.nickname,
      image: base.image,
      chatRole: base.chatRole,
      roleSymbol: base.roleSymbol,
      membership: base.membership,
      seatIndex: json['seatIndex'] as int?,
      isSpeaking: json['isSpeaking'] == true,
      isMuted: json['isMuted'] == true,
    );
  }

  final int? seatIndex;
  final bool isSpeaking;
  final bool isMuted;

  /// Mikrofon açık — koltukta ve susturulmamış.
  bool get micOpen => seatIndex != null && !isMuted;
}
