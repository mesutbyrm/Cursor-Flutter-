import '../../domain/entities/message_entities.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);

  final MessagesRemoteDataSource _remote;

  @override
  Future<List<ConversationEntity>> conversations() =>
      _remote.conversations();

  @override
  Future<List<MessageEntity>> messages(
    String conversationId, {
    String? currentUserId,
  }) =>
      _remote.messages(conversationId, currentUserId: currentUserId);

  @override
  Future<void> sendMessage(String conversationId, String text) =>
      _remote.send(conversationId, text);
}
