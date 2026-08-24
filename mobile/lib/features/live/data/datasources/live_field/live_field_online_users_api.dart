import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import 'live_field_api_util.dart';

/// Saha 7 — Çevrimiçi kullanıcılar (`GET /api/live/online-users`).
class LiveFieldOnlineUsersApi {
  LiveFieldOnlineUsersApi(this._dio);

  final Dio _dio;

  Future<LiveFieldOnlineUsersPage> fetchOnlineUsers({
    required String roomId,
    String roomType = 'voice',
    int limit = 100,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveOnlineUsers,
      query: {
        'roomId': roomId,
        'roomType': roomType,
        'limit': limit.clamp(1, 500),
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      return LiveFieldOnlineUsersPage(roomId: roomId, users: const []);
    }
    final users = LiveFieldApiUtil.listFromData(map, listKey: 'users')
        .map(LiveFieldOnlineUser.fromJson)
        .toList(growable: false);
    return LiveFieldOnlineUsersPage(
      roomId: map['roomId']?.toString() ?? roomId,
      roomType: map['roomType']?.toString() ?? roomType,
      users: users,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? users.length,
    );
  }
}

class LiveFieldOnlineUsersPage {
  const LiveFieldOnlineUsersPage({
    required this.roomId,
    required this.users,
    this.roomType,
    this.totalCount = 0,
  });

  final String roomId;
  final String? roomType;
  final List<LiveFieldOnlineUser> users;
  final int totalCount;
}

class LiveFieldOnlineUser {
  const LiveFieldOnlineUser({
    required this.userId,
    this.userName,
    this.userImage,
    this.nickname,
    this.seatIndex,
    this.isMicOn = false,
    this.joinedAt,
  });

  final String userId;
  final String? userName;
  final String? userImage;
  final String? nickname;
  final int? seatIndex;
  final bool isMicOn;
  final DateTime? joinedAt;

  factory LiveFieldOnlineUser.fromJson(Map<String, dynamic> json) {
    final rawTime = json['joinedAt']?.toString();
    return LiveFieldOnlineUser(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      nickname: json['nickname']?.toString(),
      seatIndex: (json['seatIndex'] as num?)?.toInt(),
      isMicOn: json['isMicOn'] == true,
      joinedAt: rawTime != null ? DateTime.tryParse(rawTime) : null,
    );
  }
}
