import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/util/json_util.dart';
import 'live_field_api_util.dart';

/// Saha 4 — Mesajlaşma (`POST/GET /api/live/message`).
class LiveFieldMessageApi {
  LiveFieldMessageApi(this._dio);

  final Dio _dio;

  Future<LiveFieldMessage> sendMessage({
    required String roomId,
    required String roomType,
    required String content,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveMessage,
      data: {
        'roomId': roomId,
        'roomType': roomType,
        'content': content,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      throw const FormatException('Mesaj yanıtı geçersiz');
    }
    return LiveFieldMessage.fromJson(map);
  }

  Future<List<LiveFieldMessage>> fetchMessages({
    required String roomId,
    String roomType = 'voice',
    String? after,
    int limit = 100,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveMessage,
      query: {
        'roomId': roomId,
        'roomType': roomType,
        'limit': limit.clamp(1, 200),
        if (after != null && after.isNotEmpty) 'after': after,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) return const [];
    return LiveFieldApiUtil.listFromData(map, listKey: 'messages')
        .map(LiveFieldMessage.fromJson)
        .toList(growable: false);
  }
}

class LiveFieldMessage {
  const LiveFieldMessage({
    required this.id,
    required this.roomId,
    required this.content,
    this.roomType,
    this.userId,
    this.userName,
    this.userImage,
    this.chatRole,
    this.roleSymbol,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String content;
  final String? roomType;
  final String? userId;
  final String? userName;
  final String? userImage;
  final String? chatRole;
  final String? roleSymbol;
  final DateTime? createdAt;

  factory LiveFieldMessage.fromJson(Map<String, dynamic> json) {
    final rawTime = json['createdAt']?.toString();
    return LiveFieldMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      roomType: json['roomType']?.toString(),
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      chatRole: json['chatRole']?.toString(),
      roleSymbol: json['roleSymbol']?.toString(),
      createdAt: rawTime != null ? DateTime.tryParse(rawTime) : null,
    );
  }
}
