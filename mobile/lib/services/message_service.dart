import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// DM API — kılavuz §9 (mesajlar).
class MessageService {
  MessageService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/messages`
  Future<List<Map<String, dynamic>>> getConversations() async {
    for (final path in [
      ApiEndpoints.messages,
      ApiEndpoints.messagesConversations,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final list = ServiceUtils.extractList(
          res.data,
          keys: const ['conversations', 'items', 'data'],
        );
        if (list.isNotEmpty) return list;
        final map = ServiceUtils.unwrapMap(res.data);
        if (map != null && map['conversations'] is List) {
          return asJsonList(map['conversations']);
        }
      } catch (_) {}
    }
    return const [];
  }

  /// `GET /api/messages/{userId}`
  Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.messagesWithUser(userId),
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['messages', 'items', 'data'],
    );
  }

  /// `POST /api/messages/{userId}`
  Future<Map<String, dynamic>> sendMessage(
    String userId, {
    required String content,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.messagesWithUser(userId),
      data: {'content': content.trim(), 'text': content.trim()},
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
