import '../../domain/entities/message_entities.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';
import '../deleted_messages_store.dart';
import '../messages_cache_codec.dart';
import '../../../../core/offline/api_cache_store.dart';
import '../../../../core/offline/cache_first_loader.dart';
import '../../../../core/performance/messages_load_perf.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);

  final MessagesRemoteDataSource _remote;

  @override
  Future<List<ConversationEntity>> conversations({
    bool forceRefresh = false,
    String? cacheUserId,
  }) {
    final key = MessagesLoadPerf.conversationsKey(cacheUserId ?? '');
    return CacheFirstLoader.load(
      cacheKey: key,
      maxAge: MessagesLoadPerf.conversationsMaxAge,
      forceRefresh: forceRefresh,
      refreshInBackground: false,
      fetch: () => _remote.conversations(forceRefresh: forceRefresh),
      encode: (list) => CacheFirstLoader.encodeList(
        [for (final c in list) encodeConversation(c)],
      ),
      decode: (json) {
        final items = CacheFirstLoader.decodeListItems(json);
        return items.map(decodeConversation).toList();
      },
    );
  }

  @override
  Future<List<MessageEntity>> messages(
    String conversationId, {
    String? currentUserId,
    bool forceRefresh = false,
  }) {
    final key = MessagesLoadPerf.threadKey(
      currentUserId ?? '',
      conversationId,
    );
    return CacheFirstLoader.load(
      cacheKey: key,
      maxAge: MessagesLoadPerf.threadMaxAge,
      forceRefresh: forceRefresh,
      refreshInBackground: true,
      fetch: () async {
        final remote = await _remote.messages(
          conversationId,
          currentUserId: currentUserId,
          forceRefresh: true,
        );
        final hidden = await DeletedMessagesStore.read(currentUserId ?? '');
        return remote.where((m) => !hidden.contains(m.id)).toList();
      },
      encode: (list) => CacheFirstLoader.encodeList(
        [for (final m in list) encodeMessage(m)],
      ),
      decode: (json) {
        final items = CacheFirstLoader.decodeListItems(json);
        return items.map(decodeMessage).toList();
      },
    );
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? currentUserId,
  }) async {
    await _remote.send(conversationId, text);
    final uid = currentUserId ?? '';
    await ApiCacheStore.clear(MessagesLoadPerf.threadKey(uid, conversationId));
    await ApiCacheStore.clear(MessagesLoadPerf.conversationsKey(uid));
  }

  @override
  Future<ConversationEntity> startConversation(String recipientId) =>
      _remote.startConversation(recipientId);

  @override
  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    String? currentUserId,
  }) async {
    await _remote.deleteMessage(conversationId, messageId);
    final uid = currentUserId ?? '';
    await DeletedMessagesStore.add(uid, messageId);
    await ApiCacheStore.clear(MessagesLoadPerf.threadKey(uid, conversationId));
    await ApiCacheStore.clear(MessagesLoadPerf.conversationsKey(uid));
  }
}
