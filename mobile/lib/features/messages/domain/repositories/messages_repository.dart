import '../entities/message_entities.dart';

abstract class MessagesRepository {
  Future<List<ConversationEntity>> conversations();
  Future<List<MessageEntity>> messages(
    String conversationId, {
    String? currentUserId,
  });
  Future<void> sendMessage(String conversationId, String text);
  Future<ConversationEntity> startConversation(String recipientId);
}
