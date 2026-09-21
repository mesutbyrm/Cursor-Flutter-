import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/direct_message.dart';

class DirectMessagesService {
  Future<String> getOrCreateConversation(String currentUserId, String targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'conv_${currentUserId}_${targetUserId}';
  }

  Future<DirectMessage> sendMessage(String conversationId, String senderId, String content, {String? mediaUrl, String? mediaType}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return DirectMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      read: false,
      createdAt: DateTime.now(),
    );
  }

  Future<List<DirectMessage>> getConversationMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<dynamic> getConversations(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> markAsRead(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> deleteMessage(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 0;
  }
}

final directMessagesServiceProvider = Provider((ref) => DirectMessagesService());

final conversationMessagesProvider = FutureProvider.family<List<DirectMessage>, (String, int, int)>((ref, params) async {
  final service = ref.watch(directMessagesServiceProvider);
  return service.getConversationMessages(params.$1, limit: params.$2, offset: params.$3);
});

final userConversationsProvider = FutureProvider.family<dynamic, String>((ref, userId) async {
  final service = ref.watch(directMessagesServiceProvider);
  return service.getConversations(userId);
});

final unreadCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(directMessagesServiceProvider);
  return service.getUnreadCount(userId);
});

class SendMessageNotifier extends StateNotifier<AsyncValue<DirectMessage?>> {
  SendMessageNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> sendMessage(String conversationId, String senderId, String content, {String? mediaUrl, String? mediaType}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(directMessagesServiceProvider);
      final message = await service.sendMessage(conversationId, senderId, content, mediaUrl: mediaUrl, mediaType: mediaType);
      state = AsyncValue.data(message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final sendMessageNotifierProvider = StateNotifierProvider<SendMessageNotifier, AsyncValue<DirectMessage?>>((ref) {
  return SendMessageNotifier(ref);
});
