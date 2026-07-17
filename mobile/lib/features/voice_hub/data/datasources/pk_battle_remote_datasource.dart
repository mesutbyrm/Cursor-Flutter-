import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../live/data/datasources/live_field/live_field_api_remote_datasource.dart';
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

  @visibleForTesting
  PkBattleRemote? parseBattleForTest(dynamic body) => _parseBattle(body);

  PkBattleRemote? _parseBattle(dynamic body) {
    final map = _unwrap(body);
    if (map == null) return null;
    // Yeni kontrat: GET → { activeBattle, pendingInvite }; accept → { battle };
    // invite POST → davetin kendisi (inviteId, status:pending).
    final hasWrapper =
        map.containsKey('activeBattle') || map.containsKey('pendingInvite');
    final raw = map['activeBattle'] ??
        map['battle'] ??
        map['pendingInvite'] ??
        map['pk'] ??
        map['match'] ??
        map['full'] ??
        (hasWrapper ? null : map);
    if (raw != null && raw is Map) {
      final battle =
          PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
      if (battle.effectiveId.isNotEmpty) return battle;
    }
    // Kısmi yanıt: { success, status, inviteId } veya üst düzey battle alanları.
    final status = map['status']?.toString();
    final id = (map['id'] ??
            map['pkBattleId'] ??
            map['inviteId'] ??
            map['battleId'] ??
            map['matchId'])
        ?.toString()
        .trim();
    if (id != null && id.isNotEmpty) {
      return PkBattleRemote.fromJson({
        ...map,
        'id': id,
        'status': status ?? map['status'] ?? 'pending',
      });
    }
    return null;
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
    for (final path in [ApiEndpoints.pkMeHistory, ApiEndpoints.pkHistory]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          query: {
            'battleType': ?battleType,
            'limit': '$limit',
          },
        );
        final map = _unwrap(res.data);
        final list = map?['items'] ??
            map?['history'] ??
            map?['matches'] ??
            res.data;
        final items = asJsonList(list)
            .map((e) => PkBattleRemote.fromJson(e))
            .where((b) => b.id.isNotEmpty)
            .toList();
        if (items.isNotEmpty || path == ApiEndpoints.pkMeHistory) {
          return items;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404 && path == ApiEndpoints.pkHistory) continue;
        if (path == ApiEndpoints.pkMeHistory) rethrow;
      }
    }
    return const [];
  }

  /// `POST /api/chat/rooms/{myRoomId}/pk` — kılavuz: `{ guestUserId, durationSec }`.
  Future<PkBattleRemote?> inviteVoiceRoom({
    required String roomId,
    String? alternateRoomId,
    required String guestUserId,
    String? opponentRoomId,
    int durationSeconds = 180,
  }) async {
    final guest = guestUserId.trim();
    if (guest.isEmpty) {
      throw const ApiException('PK daveti için rakip kullanıcı kimliği gerekli');
    }
    final oppRoom = opponentRoomId?.trim() ?? '';

    final bodies = <Map<String, dynamic>>[
      {
        'guestUserId': guest,
        'durationSec': durationSeconds,
      },
      if (oppRoom.isNotEmpty)
        {
          'guestUserId': guest,
          'durationSec': durationSeconds,
          'targetRoomId': oppRoom,
        },
      if (oppRoom.isNotEmpty)
        {
          'guestUserId': guest,
          'durationSec': durationSeconds,
          'opponentRoomId': oppRoom,
        },
    ];

    ApiException? lastError;
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      for (final body in bodies) {
        try {
          final res = await _dio.safePost<dynamic>(
            ApiEndpoints.chatRoomPk(key),
            data: body,
          );
          final battle = _parseBattle(res.data);
          if (battle != null) return battle;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) break;
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          rethrow;
        }
      }
    }

    if (oppRoom.isNotEmpty) {
      try {
        for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
          final liveBattle = await LiveFieldApiRemoteDataSource(_dio).pk.pkAction(
            action: 'create',
            roomId: key,
            targetRoomId: oppRoom,
            durationSeconds: durationSeconds,
          );
          if (liveBattle != null && liveBattle.id.isNotEmpty) {
            final parsed = _parseBattle({
              'battle': {
                'id': liveBattle.id,
                'status': liveBattle.status ?? 'pending',
                'challengerScore': liveBattle.room1Score,
                'opponentScore': liveBattle.room2Score,
                'durationSeconds':
                    liveBattle.durationSeconds ?? durationSeconds,
                'opponentVoiceRoomId': oppRoom,
                'opponentId': guest,
              },
            });
            if (parsed != null) return parsed;
          }
        }
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) {
          lastError = e;
        }
      } catch (_) {}
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

  /// `POST /api/chat/rooms/{roomId}/pk/{inviteId}/respond` — `{ action:"accept" }`.
  /// Kabulde `{ status:"accepted", battle:{...} }` döner.
  Future<PkBattleRemote?> acceptBattle(
    String inviteId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _respondInvite(
        inviteId: inviteId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: 'accept',
      );

  /// `POST /api/chat/rooms/{roomId}/pk/{inviteId}/respond` — `{ action:"reject" }`.
  Future<PkBattleRemote?> rejectBattle(
    String inviteId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _respondInvite(
        inviteId: inviteId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: 'reject',
      );

  Future<PkBattleRemote?> _respondInvite({
    required String inviteId,
    required String roomId,
    String? alternateRoomId,
    required String action,
  }) async {
    final synthesizedStatus = action == 'accept' ? 'active' : 'rejected';
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.chatRoomPkRespond(key, inviteId),
          data: {'action': action},
        );
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
        // Sunucu yalnızca { success: true } dönerse yerel durum üret.
        return PkBattleRemote.fromJson({
          'id': inviteId,
          'inviteId': inviteId,
          'status': synthesizedStatus,
          'battleType': 'voice_room',
          'voiceRoomId': key,
        });
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    return null;
  }

  /// `POST /api/chat/rooms/{roomId}/pk/{battleId}/end` — savaşı erken bitir.
  Future<PkBattleRemote?> endBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) async {
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.chatRoomPkEnd(key, battleId),
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
    int? duration,
  }) async {
    final normalized = action.toLowerCase();
    // API dokümanı §8: POST /api/video-streams/pk — { opponentStreamId, durationMinutes }
    if (normalized == 'create' && opponentStreamId != null) {
      final durationMinutes =
          duration != null ? (duration / 60).ceil().clamp(1, 60) : 3;
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.videoStreamPk,
          data: {
            'opponentStreamId': opponentStreamId,
            'hostStreamId': streamId,
            'streamId': streamId,
            'durationMinutes': durationMinutes,
          },
        );
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.videoStreamPkBattle(streamId),
          data: {
            'opponentStreamId': opponentStreamId,
            'durationMinutes': durationMinutes,
          },
        );
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      return null;
    }

    if (normalized != 'create') {
      // API dokümanı: { action, pkBattleId }
      final id = battleId?.trim() ?? '';
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamPkBattle(streamId),
        data: {
          'action': action,
          if (id.isNotEmpty) ...{
            'pkBattleId': id,
            'battleId': id,
            'inviteId': id,
          },
        },
      );
      return _parseBattle(res.data);
    }

    return null;
  }
}
