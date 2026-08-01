import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/util/json_util.dart';
import 'live_field_api_util.dart';

/// Saha 6 — PK Battle (`GET/POST /api/live/pk`, `POST /api/live/pk/score`).
class LiveFieldPkApi {
  LiveFieldPkApi(this._dio);

  final Dio _dio;

  Future<LiveFieldPkBattle?> fetchPk(String roomId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.livePk,
      query: {'roomId': roomId},
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) return null;
    final battle = asJsonMap(map['battle']);
    if (battle == null) return null;
    return LiveFieldPkBattle.fromJson(battle);
  }

  Future<LiveFieldPkBattle?> pkAction({
    required String action,
    required String roomId,
    String? targetRoomId,
    String? battleId,
    String? guestUserId,
    int? durationSeconds,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.livePk,
      data: {
        'action': action,
        'roomId': roomId,
        if (targetRoomId != null && targetRoomId.isNotEmpty)
          'targetRoomId': targetRoomId,
        if (guestUserId != null && guestUserId.isNotEmpty)
          'guestUserId': guestUserId,
        if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
        if (durationSeconds != null) ...{
          'durationSeconds': durationSeconds,
          'duration': '$durationSeconds',
        },
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) return null;
    final battle = asJsonMap(map['battle'] ?? map);
    if (battle == null) return null;
    return LiveFieldPkBattle.fromJson(battle);
  }

  Future<LiveFieldPkScore?> updateScore({
    required int amount,
    String? battleId,
    String? roomId,
    String? side,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.livePkScore,
      data: {
        'amount': amount,
        if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (side != null && side.isNotEmpty) 'side': side,
      },
    );
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null) return null;
    return LiveFieldPkScore.fromJson(map);
  }
}

class LiveFieldPkBattle {
  const LiveFieldPkBattle({
    required this.id,
    this.status,
    this.durationSeconds,
    this.room1Score = 0,
    this.room2Score = 0,
  });

  final String id;
  final String? status;
  final int? durationSeconds;
  final int room1Score;
  final int room2Score;

  factory LiveFieldPkBattle.fromJson(Map<String, dynamic> json) {
    final r1 = asJsonMap(json['room1']);
    final r2 = asJsonMap(json['room2']);
    return LiveFieldPkBattle(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      room1Score: (r1?['score'] as num?)?.toInt() ??
          (json['room1Score'] as num?)?.toInt() ??
          0,
      room2Score: (r2?['score'] as num?)?.toInt() ??
          (json['room2Score'] as num?)?.toInt() ??
          0,
    );
  }
}

class LiveFieldPkScore {
  const LiveFieldPkScore({
    this.battleId,
    this.room1Score = 0,
    this.room2Score = 0,
  });

  final String? battleId;
  final int room1Score;
  final int room2Score;

  factory LiveFieldPkScore.fromJson(Map<String, dynamic> json) {
    return LiveFieldPkScore(
      battleId: json['battleId']?.toString(),
      room1Score: (json['room1Score'] as num?)?.toInt() ?? 0,
      room2Score: (json['room2Score'] as num?)?.toInt() ?? 0,
    );
  }
}
