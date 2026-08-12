import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  /// Tüm sesli oda PK aksiyonları tek uca gider: `POST /api/chat/rooms/{roomId}/pk`.
  /// Yalnızca 404/405 durumunda alternatif oda anahtarı denenir; iş kuralı
  /// hataları (400/403) doğrudan yukarı fırlatılır.
  Future<PkBattleRemote?> _postPkAction({
    required String roomId,
    String? alternateRoomId,
    required Map<String, dynamic> body,
  }) async {
    ApiException? lastError;
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.chatRoomPk(key),
          data: body,
        );
        return _parseBattle(res.data);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }
    if (lastError != null) throw lastError;
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

  /// `POST /api/chat/rooms/{myRoomId}/pk`
  /// Production contract: `{ action: 'create', targetRoomId, duration }`
  /// (`duration` saniye cinsinden; sunucu varsayılanı 180).
  Future<PkBattleRemote?> inviteVoiceRoom({
    required String roomId,
    String? alternateRoomId,
    required String guestUserId,
    String? opponentRoomId,
    int durationSeconds = 180,
  }) async {
    final oppRoom = opponentRoomId?.trim() ?? '';
    if (oppRoom.isEmpty) {
      throw const ApiException('PK daveti için rakip oda seçilmeli');
    }
    final duration = durationSeconds.clamp(60, 3600);

    final guest = guestUserId.trim();
    try {
      return await _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {
          'action': 'create',
          'targetRoomId': oppRoom,
          'duration': duration,
          'durationSec': duration,
          if (guest.isNotEmpty) 'guestUserId': guest,
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode != 400 && e.statusCode != 422) rethrow;
      if (guest.isEmpty) rethrow;
      return _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {
          'guestUserId': guest,
          'durationSec': duration,
          'duration': duration,
        },
      );
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

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action:'accept', battleId }`.
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

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action:'reject', battleId }`.
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
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) {
          // Kılavuz path başarısız — unified body denenir.
        }
      }
    }
    final battle = await _postPkAction(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      body: {'action': action, 'battleId': inviteId},
    );
    if (battle != null) return battle;
    return PkBattleRemote.fromJson({
      'id': inviteId,
      'inviteId': inviteId,
      'status': synthesizedStatus,
      'battleType': 'voice_room',
      'voiceRoomId': roomId,
    });
  }

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action:'end', battleId }`.
  Future<PkBattleRemote?> endBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {'action': 'end', 'battleId': battleId},
      );

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action:'cancel', battleId }`.
  Future<PkBattleRemote?> cancelBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {'action': 'cancel', 'battleId': battleId},
      );

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

  /// Bekleyen PK davetleri — REST poll yedek.
  Future<List<PkBattleRemote>> fetchMyInvites() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.pkMeInvites,
        forceRefresh: true,
      );
      final map = _unwrap(res.data);
      final list = map?['items'] ??
          map?['invites'] ??
          map?['pending'] ??
          res.data;
      final out = <PkBattleRemote>[];
      for (final raw in asJsonList(list)) {
        final battle = _parseBattle(raw) ??
            PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
        if (battle.effectiveId.isNotEmpty) out.add(battle);
      }
      return out;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }
}
