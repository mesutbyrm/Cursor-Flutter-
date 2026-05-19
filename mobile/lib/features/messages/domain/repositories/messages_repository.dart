import '../entities/message_entities.dart';

abstract class MessagesRepository {
  Future<List<ConversationEntity>> conversations();
  Future<List<MessageEntity>> messages(String conversationId);
  Future<void> sendMessage(String conversationId, String text);
}
