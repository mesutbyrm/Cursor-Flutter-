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
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.chatRoomPkBattle(key),
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
        if (battleType != null) 'battleType': battleType,
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

  Future<PkBattleRemote?> inviteVoiceRoom({
    required String roomId,
    String? alternateRoomId,
    required String opponentRoomId,
    String? alternateOpponentRoomId,
    int durationSeconds = 300,
    int targetScore = 150000,
  }) async {
    final body = {
      'action': 'create',
      'opponentRoomId': opponentRoomId,
      'opponentVoiceRoomId': opponentRoomId,
      'durationSeconds': durationSeconds,
      'targetScore': targetScore,
    };
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      for (final oppKey in _roomKeyCandidates(
        opponentRoomId,
        alternateOpponentRoomId,
      )) {
        try {
          final res = await _dio.safePost<dynamic>(
            ApiEndpoints.chatRoomPkBattle(key),
            data: {
              ...body,
              'opponentRoomId': oppKey,
              'opponentVoiceRoomId': oppKey,
            },
          );
          final battle = _parseBattle(res.data);
          if (battle != null) return battle;
        } on ApiException catch (e) {
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
    }
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.pkBattles,
        data: {
          'battleType': 'voice_room',
          'voiceRoomId': roomId,
          'opponentVoiceRoomId': opponentRoomId,
          'opponentRoomId': opponentRoomId,
          'durationSeconds': durationSeconds,
          'targetScore': targetScore,
        },
      );
      return _parseBattle(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    }
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

  Future<PkBattleRemote?> acceptBattle(String battleId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkBattleAccept(battleId),
    );
    return _parseBattle(res.data);
  }

  Future<PkBattleRemote?> rejectBattle(String battleId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkBattleReject(battleId),
    );
    return _parseBattle(res.data);
  }

  Future<PkBattleRemote?> endBattle(String battleId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkBattleEnd(battleId),
    );
    return _parseBattle(res.data);
  }

  Future<PkBattleRemote?> roomPkAction({
    required String roomId,
    required String action,
    String? battleId,
    String? opponentRoomId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomPkBattle(roomId),
      data: {
        'action': action,
        if (battleId != null) 'battleId': battleId,
        if (opponentRoomId != null) 'opponentRoomId': opponentRoomId,
      },
    );
    return _parseBattle(res.data);
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
        if (battleId != null) 'battleId': battleId,
        if (opponentStreamId != null) 'opponentStreamId': opponentStreamId,
      },
    );
    return _parseBattle(res.data);
  }
}
