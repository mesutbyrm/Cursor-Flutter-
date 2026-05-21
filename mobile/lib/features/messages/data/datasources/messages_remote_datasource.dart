import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';

class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ConversationEntity>> conversations() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.conversations);
    final body = res.data;
    dynamic list;
    if (body is Map<String, dynamic>) {
      list = pick(body, ['items', 'data', 'conversations', 'results']);
    } else {
      list = body;
    }
    return asJsonList(list).map(_conv).toList();
  }

  ConversationEntity _conv(Map<String, dynamic> json) {
    final peer = pick(json, ['peer', 'user', 'participant']);
    final peerMap = peer is Map ? asJsonMap(peer) : <String, dynamic>{};
    return ConversationEntity(
      id: pick(json, ['id', '_id', 'conversationId'])?.toString() ?? '',
      title: pick(json, ['title', 'name'])?.toString() ??
          pick(peerMap, ['displayName', 'username'])?.toString() ??
          'Sohbet',
      subtitle: pick(json, ['lastMessage', 'preview', 'subtitle'])?.toString(),
      avatarUrl: pick(peerMap, ['avatarUrl', 'avatar_url', 'photoUrl'])
          as String?,
      unreadCount: asInt(pick(json, ['unreadCount', 'unread', 'badge'])),
    );
  }

  Future<List<MessageEntity>> messages(String id) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.conversationMessages(id),
    );
    final body = res.data;
    dynamic list;
    if (body is Map<String, dynamic>) {
      list = pick(body, ['items', 'data', 'messages', 'results']);
    } else {
      list = body;
    }
    return asJsonList(list).map(_msg).toList();
  }

  MessageEntity _msg(Map<String, dynamic> json) {
    final readAt = pick(json, ['readAt', 'read_at', 'seenAt']);
    final deliveredAt = pick(json, ['deliveredAt', 'delivered_at']);
    final statusRaw = pick(json, ['status', 'deliveryStatus'])?.toString();

    var delivery = MessageDeliveryStatus.sent;
    if (readAt != null || statusRaw == 'read') {
      delivery = MessageDeliveryStatus.read;
    } else if (deliveredAt != null || statusRaw == 'delivered') {
      delivery = MessageDeliveryStatus.delivered;
    }

    return MessageEntity(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      text: pick(json, ['text', 'body', 'content'])?.toString() ?? '',
      isMine: asBool(pick(json, ['isMine', 'mine', 'fromMe'])),
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ??
            '',
      ),
      deliveryStatus: delivery,
    );
  }

  Future<void> send(String id, String text) async {
    await _dio.safePost(
      ApiEndpoints.conversationMessages(id),
      data: {'text': text, 'content': text},
    );
  }
}
