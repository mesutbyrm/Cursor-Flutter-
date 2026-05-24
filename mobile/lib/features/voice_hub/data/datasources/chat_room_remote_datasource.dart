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

  static String backgroundsPath() => '/api/chat/rooms/backgrounds';

  static String speakRequestPath(String roomId) =>
      '/api/chat/rooms/$roomId/speak-request';

  static String roomBackgroundPath(String roomId) =>
      '/api/chat/rooms/$roomId/background';

  Map<String, dynamic>? _unwrapMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  List<Map<String, dynamic>> _messageList(dynamic body) {
    final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    if (map != null) {
      final list = map['messages'] ?? map['items'];
      return asJsonList(list);
    }
    if (body is List) return asJsonList(body);
    return const [];
  }

  Future<List<ChatRoomMessage>> fetchMessages(String roomId) async {
    final res = await _dio.safeGet<dynamic>(messagesPath(roomId));
    return _messageList(res.data)
        .map(ChatRoomMessage.fromJson)
        .where((m) => m.id.isNotEmpty || m.content.isNotEmpty)
        .toList();
  }

  Future<List<ChatRoomPresence>> fetchPresence(String roomId) async {
    final res = await _dio.safeGet<dynamic>(presencePath(roomId));
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    final users = map['users'];
    if (users is! List) return const [];
    return users
        .map((e) => ChatRoomPresence.fromJson(asJsonMap(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  Future<void> joinPresence(String roomId) async {
    await _dio.safePost<dynamic>(presencePath(roomId));
  }

  Future<void> leavePresence(String roomId) async {
    await _dio.safeDelete<dynamic>(presencePath(roomId));
  }

  Future<ChatRoomDjState> fetchDj(String roomId) async {
    final res = await _dio.safeGet<dynamic>(djPath(roomId));
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    if (map.isEmpty) return const ChatRoomDjState();
    return ChatRoomDjState.fromJson(map);
  }

  Future<ChatRoomDjState> updateDj({
    required String roomId,
    String? musicUrl,
    required bool playing,
  }) async {
    final res = await _dio.safePost<dynamic>(
      djPath(roomId),
      data: jsonEncode({
        if (musicUrl != null) 'musicUrl': musicUrl,
        'playing': playing,
      }),
      options: Options(contentType: 'application/json'),
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    return ChatRoomDjState.fromJson(map);
  }

  Future<List<String>> fetchBackgrounds() async {
    final res = await _dio.safeGet<dynamic>(backgroundsPath());
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    final raw = map['backgrounds'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> setRoomBackground({
    required String roomId,
    required String backgroundImage,
  }) async {
    await _dio.safePatch<dynamic>(
      roomBackgroundPath(roomId),
      data: jsonEncode({'backgroundImage': backgroundImage}),
    );
  }

  Future<void> requestSpeak(String roomId) async {
    await _dio.safePost<dynamic>(speakRequestPath(roomId));
  }

  Future<void> cancelSpeakRequest(String roomId) async {
    await _dio.safeDelete<dynamic>(speakRequestPath(roomId));
  }

  static String banPath(String roomId, String userId) =>
      '/api/chat/rooms/$roomId/bans/$userId';

  Future<void> banUser({
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      banPath(roomId, userId),
      data: jsonEncode({if (reason != null) 'reason': reason}),
      options: Options(contentType: 'application/json'),
    );
  }

  Future<void> unbanUser({
    required String roomId,
    required String userId,
  }) async {
    await _dio.safeDelete<dynamic>(banPath(roomId, userId));
  }

  Future<ChatRoomMessage?> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final res = await _dio.safePost<dynamic>(
      messagesPath(roomId),
      data: jsonEncode({
        'content': content,
        'body': content,
        'message': content,
        'text': content,
      }),
      options: Options(contentType: 'application/json'),
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    final msg = map['message'] ?? map;
    if (msg is Map) {
      return ChatRoomMessage.fromJson(Map<String, dynamic>.from(msg));
    }
    return null;
  }
}
