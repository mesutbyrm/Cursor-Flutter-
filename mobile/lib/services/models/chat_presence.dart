import 'chat_service_message.dart';

/// `GET/POST /api/chat/rooms/{roomId}/presence` kullanıcısı.
class ChatPresence extends ChatServiceUser {
  const ChatPresence({
    required super.id,
    required super.name,
    super.nickname,
    super.image,
    this.seatIndex,
    this.isSpeaking = false,
    this.isMuted = false,
  });

  factory ChatPresence.fromJson(Map<String, dynamic> json) {
    final base = ChatServiceUser.fromJson(json);
    return ChatPresence(
      id: base.id,
      name: base.name,
      nickname: base.nickname,
      image: base.image,
      seatIndex: json['seatIndex'] as int?,
      isSpeaking: json['isSpeaking'] == true,
      isMuted: json['isMuted'] == true,
    );
  }

  final int? seatIndex;
  final bool isSpeaking;
  final bool isMuted;
}
