import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/message_entities.dart';
import '../models/conversation_dto.dart';
import '../models/message_dto.dart';

class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ConversationEntity>> conversations() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.conversations);
      final parsed = _parseConversations(res.data);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Mesajlar için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  List<ConversationEntity>? _parseConversations(dynamic body) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }
    if (body is! Map && body is! List) return null;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) return null;

      if (map['success'] == true && map['data'] != null) {
        return _parseConversations(map['data']);
      }

      final list = pick(map, ['items', 'data', 'conversations', 'results']);
      if (list != null) {
        return asJsonList(list)
            .map(ConversationDto.fromApiMap)
            .map((d) => d.toEntity())
            .where((c) => c.id.isNotEmpty)
            .toList();
      }
    }

    if (body is List) {
      return asJsonList(body)
          .map(ConversationDto.fromApiMap)
          .map((d) => d.toEntity())
          .where((c) => c.id.isNotEmpty)
          .toList();
    }
    return null;
  }

  Future<List<MessageEntity>> messages(
    String id, {
    String? currentUserId,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.conversationMessages(id),
      );
      final parsed = _parseMessages(res.data, currentUserId: currentUserId);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Sohbet için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  List<MessageEntity>? _parseMessages(
    dynamic body, {
    String? currentUserId,
  }) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }
    if (body is! Map && body is! List) return null;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) return null;

      if (map['success'] == true && map['data'] != null) {
        return _parseMessages(map['data'], currentUserId: currentUserId);
      }

      final list = pick(map, ['items', 'data', 'messages', 'results']);
      if (list != null) {
        return asJsonList(list)
            .map((j) => MessageDto.fromApiMap(
                  j,
                  currentUserId: currentUserId,
                ))
            .map((d) => d.toEntity())
            .toList();
      }
    }

    if (body is List) {
      return asJsonList(body)
          .map((j) => MessageDto.fromApiMap(j, currentUserId: currentUserId))
          .map((d) => d.toEntity())
          .toList();
    }
    return null;
  }

  Future<void> send(String id, String text) async {
    await _dio.safePost(
      ApiEndpoints.conversationMessages(id),
      data: {'text': text, 'content': text},
    );
  }
}
