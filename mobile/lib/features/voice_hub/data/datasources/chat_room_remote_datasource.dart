import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';

class ChatRoomRemoteDataSource {
  ChatRoomRemoteDataSource(this._dio);

  final Dio _dio;

  static String messagesPath(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  static String presencePath(String roomId) =>
      '/api/chat/rooms/$roomId/presence';

  static String djPath(String roomId) => '/api/chat/rooms/$roomId/dj';

  Future<List<ChatRoomMessage>> fetchMessages(String roomId) async {
    final res = await _dio.safeGet<dynamic>(messagesPath(roomId));
    final body = res.data;
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) return const [];
    final list = map['messages'] ?? map['items'];
    if (list is! List) return const [];
    return list
        .map((e) => ChatRoomMessage.fromJson(asJsonMap(e)))
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  Future<List<ChatRoomPresence>> fetchPresence(String roomId) async {
    final res = await _dio.safeGet<dynamic>(presencePath(roomId));
    final body = res.data;
    if (body is! Map) return const [];
    final map = Map<String, dynamic>.from(body);
    final users = map['users'];
    if (users is! List) return const [];
    return users
        .map((e) => ChatRoomPresence.fromJson(asJsonMap(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  Future<ChatRoomDjState> fetchDj(String roomId) async {
    final res = await _dio.safeGet<dynamic>(djPath(roomId));
    final body = res.data;
    if (body is! Map) return const ChatRoomDjState();
    return ChatRoomDjState.fromJson(Map<String, dynamic>.from(body));
  }

  Future<ChatRoomMessage?> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final res = await _dio.safePost<dynamic>(
      messagesPath(roomId),
      data: jsonEncode({'content': content}),
      options: Options(contentType: 'application/json'),
    );
    final body = res.data;
    if (body is Map) {
      final msg = body['message'] ?? body;
      if (msg is Map) {
        return ChatRoomMessage.fromJson(Map<String, dynamic>.from(msg));
      }
    }
    return null;
  }
}
