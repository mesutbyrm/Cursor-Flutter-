import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/util/json_util.dart';
import 'live_field_api_util.dart';

/// Saha 3 — Koltuk yönetimi (`POST/GET /api/live/seats`).
class LiveFieldSeatsApi {
  LiveFieldSeatsApi(this._dio);

  final Dio _dio;

  Future<void> seatAction({
    required String roomId,
    required String action,
    int? seatIndex,
    String? targetUserId,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.liveSeats,
      data: {
        'roomId': roomId,
        'action': action,
        if (seatIndex != null) 'seatIndex': seatIndex,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': targetUserId,
      },
    );
  }

  Future<LiveFieldSeatsSnapshot> fetchSeats(String roomId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveSeats,
      query: {'roomId': roomId},
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) {
      return LiveFieldSeatsSnapshot(roomId: roomId, seats: const []);
    }
    final raw = map['seats'];
    final seats = raw is List
        ? asJsonList(raw)
            .map(LiveFieldSeat.fromJson)
            .toList(growable: false)
        : const <LiveFieldSeat>[];
    return LiveFieldSeatsSnapshot(
      roomId: map['roomId']?.toString() ?? roomId,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 15,
      seats: seats,
    );
  }
}

class LiveFieldSeatsSnapshot {
  const LiveFieldSeatsSnapshot({
    required this.roomId,
    required this.seats,
    this.totalSeats = 15,
  });

  final String roomId;
  final int totalSeats;
  final List<LiveFieldSeat> seats;
}

class LiveFieldSeat {
  const LiveFieldSeat({
    required this.seatIndex,
    this.userId,
    this.userName,
    this.userImage,
    this.isMicOn = false,
  });

  final int seatIndex;
  final String? userId;
  final String? userName;
  final String? userImage;
  final bool isMicOn;

  factory LiveFieldSeat.fromJson(Map<String, dynamic> json) {
    return LiveFieldSeat(
      seatIndex: (json['seatIndex'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      userImage: json['userImage']?.toString(),
      isMicOn: json['isMicOn'] == true,
    );
  }
}
