import '../../core/util/json_util.dart';

class ChatServiceUser {
  const ChatServiceUser({
    required this.id,
    required this.name,
    this.nickname,
    this.image,
  });

  final String id;
  final String name;
  final String? nickname;
  final String? image;

  factory ChatServiceUser.fromJson(Map<String, dynamic> json) {
    return ChatServiceUser(
      id: pick(json, ['id', 'userId', '_id'])?.toString() ?? '',
      name: pick(json, ['name', 'displayName', 'username', 'nickname'])
              ?.toString() ??
          'Kullanıcı',
      nickname: json['nickname']?.toString(),
      image: pick(json, ['image', 'avatar', 'avatarUrl', 'profileImage'])
          ?.toString(),
    );
  }
}

/// `GET/POST /api/chat/rooms/{roomId}/messages` mesajı.
class ChatServiceMessage {
  const ChatServiceMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.type = 'text',
    this.user,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String type;
  final ChatServiceUser? user;

  factory ChatServiceMessage.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json['sender'];
    ChatServiceUser? user;
    if (userJson is Map) {
      user = ChatServiceUser.fromJson(Map<String, dynamic>.from(userJson));
    }
    final content = pick(json, ['content', 'body', 'text', 'message'])
            ?.toString() ??
        '';
    return ChatServiceMessage(
      id: pick(json, ['id', '_id'])?.toString() ??
          '${json['createdAt']}_$content'.hashCode.toString(),
      content: content,
      createdAt: DateTime.tryParse(
            pick(json, ['createdAt', 'sentAt', 'timestamp'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      type: pick(json, ['type', 'messageType'])?.toString() ?? 'text',
      user: user,
    );
  }
}
