import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/pk_battle_remote_models.dart';

class PkBattleRemoteDataSource {
  PkBattleRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic>? _unwrap(dynamic body) {
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

  PkBattleRemote? _parseBattle(dynamic body) {
    final map = _unwrap(body);
    if (map == null) return null;
    final raw = map['battle'] ?? map['pk'] ?? map['full'] ?? map;
    if (raw is! Map) return null;
    return PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<PkBattleRemote?> fetchRoomBattle(
    String roomId, {
    String? alternateRoomId,
  }) async {
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomPk(key));
        final battle = _parseBattle(res.data);
        if (battle != null && !battle.isEnded) return battle;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    return null;
  }

  Future<PkBattleRemote?> fetchStreamBattle(String streamId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.videoStreamPkBattle(streamId));
    return _parseBattle(res.data);
  }

  Future<PkBattleRemote?> fetchBattle(String battleId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkBattle(battleId));
    return _parseBattle(res.data);
  }

  Future<List<PkBattleRemote>> fetchHistory({
    String? battleType,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.pkHistory,
      query: {
        'battleType': ?battleType,
        'limit': '$limit',
      },
    );
    final map = _unwrap(res.data);
    final list = map?['items'] ?? map?['history'] ?? res.data;
    return asJsonList(list)
        .map((e) => PkBattleRemote.fromJson(e))
        .where((b) => b.id.isNotEmpty)
        .toList();
  }

  /// `POST /api/chat/rooms/{myRoomId}/pk` — `{ action: "create", targetRoomId, duration }`
  Future<PkBattleRemote?> inviteVoiceRoom({
    required String roomId,
    String? alternateRoomId,
    required String opponentRoomId,
    String? alternateOpponentRoomId,
    int durationSeconds = 180,
  }) async {
    ApiException? lastError;
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      for (final oppKey in _roomKeyCandidates(
        opponentRoomId,
        alternateOpponentRoomId,
      )) {
        try {
          final res = await _dio.safePost<dynamic>(
            ApiEndpoints.chatRoomPk(key),
            data: {
              'action': 'create',
              'targetRoomId': oppKey,
              'duration': durationSeconds,
            },
          );
          final battle = _parseBattle(res.data);
          if (battle != null) return battle;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  List<String> _roomKeyCandidates(String primary, String? alternate) {
    final keys = <String>[];
    void add(String? value) {
      final v = value?.trim() ?? '';
      if (v.isNotEmpty && !keys.contains(v)) keys.add(v);
    }

    add(primary);
    add(alternate);
    return keys;
  }

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action: "accept", battleId }`
  Future<PkBattleRemote?> acceptBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      roomPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: 'accept',
        battleId: battleId,
      );

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action: "reject", battleId }`
  Future<PkBattleRemote?> rejectBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      roomPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: 'reject',
        battleId: battleId,
      );

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action: "end", battleId }`
  Future<PkBattleRemote?> endBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      roomPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: 'end',
        battleId: battleId,
      );

  Future<PkBattleRemote?> roomPkAction({
    required String roomId,
    String? alternateRoomId,
    required String action,
    String? battleId,
    String? targetRoomId,
    int? duration,
  }) async {
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.chatRoomPk(key),
          data: {
            'action': action,
            'battleId': ?battleId,
            'targetRoomId': ?targetRoomId,
            'duration': ?duration,
          },
        );
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    return null;
  }

  Future<PkBattleRemote?> streamPkAction({
    required String streamId,
    required String action,
    String? battleId,
    String? opponentStreamId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamPkBattle(streamId),
      data: {
        'action': action,
        'battleId': ?battleId,
        'opponentStreamId': ?opponentStreamId,
      },
    );
    return _parseBattle(res.data);
  }
}
