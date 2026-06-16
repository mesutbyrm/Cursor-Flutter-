import '../../core/result/pf_result.dart';
import '../entities/pf_chat.dart';

abstract interface class PfChatRepository {
  Future<PfResult<List<PfConversation>>> getConversations(String userId);
  Stream<List<PfChatMessage>> watchMessages(String conversationId);
  Future<PfResult<PfChatMessage>> sendText({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Future<PfResult<PfChatMessage>> sendImage({
    required String conversationId,
    required String senderId,
    required String localImagePath,
  });
  Future<PfResult<PfChatMessage>> sendAudio({
    required String conversationId,
    required String senderId,
    required String localAudioPath,
  });
  Future<PfResult<void>> markAsRead(String conversationId, String userId);
}
