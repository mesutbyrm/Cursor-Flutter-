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
    );
  }

  final int? seatIndex;
  final bool isSpeaking;
}
