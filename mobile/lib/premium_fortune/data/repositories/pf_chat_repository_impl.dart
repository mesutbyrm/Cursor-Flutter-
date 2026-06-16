import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_chat.dart';
import '../../domain/repositories/pf_chat_repository.dart';
import '../datasources/pf_chat_datasource.dart';

class PfChatRepositoryImpl implements PfChatRepository {
  PfChatRepositoryImpl(this._datasource);

  final PfChatDatasource _datasource;

  @override
  Future<PfResult<List<PfConversation>>> getConversations(String userId) =>
      _guard(() => _datasource.getConversations(userId));

  @override
  Stream<List<PfChatMessage>> watchMessages(String conversationId) =>
      _datasource.watchMessages(conversationId);

  @override
  Future<PfResult<PfChatMessage>> sendText({
    required String conversationId,
    required String senderId,
    required String text,
  }) =>
      _guard(
        () => _datasource.sendMessage(
          _datasource.createText(
            conversationId: conversationId,
            senderId: senderId,
            text: text,
          ),
        ),
      );

  @override
  Future<PfResult<PfChatMessage>> sendImage({
    required String conversationId,
    required String senderId,
    required String localImagePath,
  }) =>
      _guard(
        () => _datasource.sendMessage(
          PfChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            conversationId: conversationId,
            senderId: senderId,
            type: PfMessageType.image,
            content: 'Fotoğraf',
            mediaUrl: localImagePath,
            createdAt: DateTime.now(),
          ),
        ),
      );

  @override
  Future<PfResult<PfChatMessage>> sendAudio({
    required String conversationId,
    required String senderId,
    required String localAudioPath,
  }) =>
      _guard(
        () => _datasource.sendMessage(
          PfChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            conversationId: conversationId,
            senderId: senderId,
            type: PfMessageType.audio,
            content: 'Ses kaydı',
            mediaUrl: localAudioPath,
            createdAt: DateTime.now(),
          ),
        ),
      );

  @override
  Future<PfResult<void>> markAsRead(String conversationId, String userId) async {
    return const PfSuccess(null);
  }

  Future<PfResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return PfSuccess(await action());
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfNetworkFailure(e.toString()));
    }
  }
}
