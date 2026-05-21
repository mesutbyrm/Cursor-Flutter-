import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';
import '../models/conversation_dto.dart';
import '../models/message_dto.dart';

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
    return asJsonList(list)
        .map(ConversationDto.fromApiMap)
        .map((d) => d.toEntity())
        .toList();
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
    return asJsonList(list)
        .map(MessageDto.fromApiMap)
        .map((d) => d.toEntity())
        .toList();
  }

  Future<void> send(String id, String text) async {
    await _dio.safePost(
      ApiEndpoints.conversationMessages(id),
      data: {'text': text, 'content': text},
    );
  }
}
