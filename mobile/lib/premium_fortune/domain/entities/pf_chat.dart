import 'package:equatable/equatable.dart';

enum PfMessageType { text, image, audio }

class PfChatMessage extends Equatable {
  const PfChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.mediaUrl,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final PfMessageType type;
  final String content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        type,
        content,
        mediaUrl,
        isRead,
        createdAt,
      ];
}

class PfConversation extends Equatable {
  const PfConversation({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
    this.tellerName,
    this.tellerPhotoUrl,
  });

  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  final String? tellerName;
  final String? tellerPhotoUrl;

  @override
  List<Object?> get props => [
        id,
        participantIds,
        lastMessage,
        updatedAt,
        unreadCount,
        tellerName,
        tellerPhotoUrl,
      ];
}
