import '../entities/message_entities.dart';

abstract class MessagesRepository {
  Future<List<ConversationEntity>> conversations({
    bool forceRefresh = false,
    String? cacheUserId,
  });

  Future<List<MessageEntity>> messages(
    String conversationId, {
    String? currentUserId,
    bool forceRefresh = false,
  });

  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? currentUserId,
  });

  Future<ConversationEntity> startConversation(String recipientId);
}
