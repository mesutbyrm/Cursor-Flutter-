import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../../core/util/json_util.dart';
import '../../../live/data/datasources/live_field/live_field_pk_api.dart';
import '../../domain/pk/pk_battle_remote_models.dart';

int pkDurationMinutesFromSeconds(int durationSeconds) {
  final sec = durationSeconds.clamp(60, 3600);
  return (sec / 60).ceil().clamp(1, 60);
}

/// Sesli oda PK daveti — `POST /api/chat/rooms/{roomId}/pk` action:create.
List<Map<String, dynamic>> voicePkInviteRequestBodies({
  required String opponentRoomId,
  String guestUserId = '',
  required int durationSeconds,
}) {
  final opp = opponentRoomId.trim();
  final duration = durationSeconds.clamp(60, 600);
  final guest = guestUserId.trim();

  final primary = <String, dynamic>{
    'action': 'create',
    'targetRoomId': opp,
    'duration': duration,
  };

  if (guest.isNotEmpty) {
    return [
      primary,
      {
        'action': 'create',
        'guestUserId': guest,
        'durationSec': duration,
      },
    ];
  }

  return [primary];
}

/// Canlı PK create gövdeleri — kılavuz §9.4 önce, sonra action tabanlı yedekler.
List<Map<String, dynamic>> livePkCreateRequestBodies({
  required String hostStreamId,
  required String targetStreamId,
  required int durationSeconds,
}) {
  final host = hostStreamId.trim();
  final target = targetStreamId.trim();
  final duration = durationSeconds.clamp(60, 3600);
  final minutes = pkDurationMinutesFromSeconds(duration);

  return [
    {
      'opponentStreamId': target,
      'durationMinutes': minutes,
    },
    {
      'streamId': host,
      'opponentStreamId': target,
      'durationMinutes': minutes,
    },
    {
      'action': 'create',
      'streamId': host,
      'targetStreamId': target,
      'duration': '$duration',
      'durationSec': duration,
    },
    livePkCreateRequestBody(
      hostStreamId: host,
      targetStreamId: target,
      durationSeconds: duration,
    ),
  ];
}

/// Canlı PK davet gövdesi — üretim `POST /api/video-streams/pk` action fallback.
Map<String, dynamic> livePkCreateRequestBody({
  required String hostStreamId,
  required String targetStreamId,
  required int durationSeconds,
}) {
  final host = hostStreamId.trim();
  final target = targetStreamId.trim();
  final duration = durationSeconds.clamp(60, 3600);
  return {
    'action': 'create',
    'streamId': host,
    'hostStreamId': host,
    'targetStreamId': target,
    'opponentStreamId': target,
    'opponentLiveStreamId': target,
    'duration': duration,
    'durationSeconds': duration,
    'durationSec': duration,
    'durationMinutes': pkDurationMinutesFromSeconds(duration),
  };
}

Map<String, dynamic>? unwrapPkHttpBody(dynamic body) {
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

/// GET/POST PK yanıtı — `activeBattle`, `pendingInvite`, zarfsız battle.
PkBattleRemote? parsePkBattleHttpBody(dynamic body) {
  final map = unwrapPkHttpBody(body);
  if (map == null) return null;
  final hasWrapper =
      map.containsKey('activeBattle') || map.containsKey('pendingInvite');
  dynamic raw;
  if (hasWrapper) {
    final pendingRaw = map['pendingInvite'];
    final activeRaw = map['activeBattle'];
    if (pendingRaw is Map) {
      final pending = PkBattleRemote.fromJson(
        Map<String, dynamic>.from(pendingRaw),
      );
      if (pending.isPending && pending.effectiveId.isNotEmpty) {
        raw = pendingRaw;
      }
    }
    raw ??= activeRaw ??
        map['battle'] ??
        map['pk'] ??
        map['match'] ??
        map['full'];
  } else {
    raw = map['battle'] ??
        map['pk'] ??
        map['match'] ??
        map['full'] ??
        map;
  }
  if (raw != null && raw is Map) {
    final battle =
        PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
    if (battle.effectiveId.isNotEmpty) return battle;
  }
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

class PkBattleRemoteDataSource {
  PkBattleRemoteDataSource(this._dio);

  final Dio _dio;

  LiveFieldPkApi get _liveFieldPk => LiveFieldPkApi(_dio);

  Map<String, dynamic>? _unwrap(dynamic body) => unwrapPkHttpBody(body);

  @visibleForTesting
  PkBattleRemote? parseBattleForTest(dynamic body) => _parseBattle(body);

  PkBattleRemote? _parseBattle(dynamic body) => parsePkBattleHttpBody(body);

  /// Oda içi takım PK — `create_user` (davet yok, geri sayım ile başlar).
  Future<PkBattleRemote?> createUserInRoomPk({
    required String roomId,
    String? alternateRoomId,
    required List<String> side1UserIds,
    required List<String> side2UserIds,
    int durationSeconds = 180,
    int countdownSec = 5,
  }) async {
    final s1 =
        side1UserIds.where((id) => id.trim().isNotEmpty).take(4).toList();
    final s2 =
        side2UserIds.where((id) => id.trim().isNotEmpty).take(4).toList();
    if (s1.isEmpty || s2.isEmpty) {
      throw const ApiException('PK için her iki tarafta en az bir kullanıcı gerekli');
    }
    return _postPkAction(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      body: {
        'action': 'create_user',
        'side1UserIds': s1,
        'side2UserIds': s2,
        'duration': durationSeconds.clamp(60, 600),
        'countdownSec': countdownSec.clamp(0, 30),
      },
    );
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
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
        return _synthesizePendingBattle(res.data, roomId: key);
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

  PkBattleRemote? _synthesizePendingBattle(
    dynamic body, {
    required String roomId,
  }) {
    final map = _unwrap(body);
    if (map == null) return null;
    if (map['success'] == false) return null;
    final id = (map['inviteId'] ??
            map['id'] ??
            map['pkBattleId'] ??
            map['battleId'])
        ?.toString()
        .trim();
    if (id == null || id.isEmpty) return null;
    return PkBattleRemote.fromJson({
      ...map,
      'id': id,
      'inviteId': id,
      'status': map['status']?.toString() ?? 'pending',
      'voiceRoomId': map['voiceRoomId']?.toString() ?? roomId,
      'battleType': map['battleType']?.toString() ?? 'voice_room',
    });
  }

  Future<PkBattleRemote?> fetchRoomBattle(
    String roomId, {
    String? alternateRoomId,
  }) async {
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomPk(key));
        if (res.data == null) return null;
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
    final id = streamId.trim();
    if (id.isEmpty) return null;
    try {
      final field = await _liveFieldPk.fetchPk(id);
      if (field != null && field.id.isNotEmpty) {
        final battle = _parseBattle({
          'id': field.id,
          'status': field.status,
          'duration': field.durationSeconds,
          'score1': field.room1Score,
          'score2': field.room2Score,
          'liveStreamId': id,
        });
        if (battle != null) return battle;
      }
    } catch (_) {}
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.videoStreamPkBattle(id));
    return _parseBattle(res.data);
  }

  Future<List<PkBattleRemote>> fetchHistory({
    String? battleType,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.chatRoomPkList,
        query: {
          'status': 'ended,finished',
          if (battleType != null && battleType.isNotEmpty)
            'battleType': battleType,
          'limit': '$limit',
        },
      );
      final map = _unwrap(res.data);
      final list = map?['items'] ??
          map?['battles'] ??
          map?['matches'] ??
          (res.data is List ? res.data : null);
      return asJsonList(list)
          .map((e) => PkBattleRemote.fromJson(e))
          .where((b) => b.id.isNotEmpty)
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// `POST /api/chat/rooms/{myRoomId}/pk` — oda↔oda PK daveti.
  Future<PkBattleRemote?> inviteVoiceRoom({
    required String roomId,
    String? alternateRoomId,
    String guestUserId = '',
    String? opponentRoomId,
    int durationSeconds = 180,
  }) async {
    final oppRoom = opponentRoomId?.trim() ?? '';
    if (oppRoom.isEmpty) {
      throw const ApiException('PK daveti için rakip oda seçilmeli');
    }
    final bodies = voicePkInviteRequestBodies(
      opponentRoomId: oppRoom,
      guestUserId: guestUserId,
      durationSeconds: durationSeconds,
    );

    ApiException? lastError;
    for (final body in bodies) {
      try {
        final battle = await _postPkAction(
          roomId: roomId,
          alternateRoomId: alternateRoomId,
          body: body,
        );
        if (battle != null) return battle;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 400 || e.statusCode == 422) continue;
        if (e.statusCode == 429) {
          throw ApiException(
            'Çok hızlı denediniz, biraz bekleyin.',
            statusCode: 429,
          );
        }
        rethrow;
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
    try {
      final battle = await _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {'action': action, 'battleId': inviteId, 'matchId': inviteId},
      );
      if (battle != null) return battle;
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        throw ApiException(
          'Çok hızlı denediniz, biraz bekleyin.',
          statusCode: 429,
        );
      }
      rethrow;
    }
    throw ApiException('PK daveti yanıtlanamadı ($action)');
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
        body: {'action': 'end', 'battleId': battleId, 'matchId': battleId},
      );

  /// `POST /api/chat/rooms/{roomId}/pk` — `{ action:'pause'|'resume', battleId }`.
  Future<PkBattleRemote?> pauseBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {'action': 'pause', 'battleId': battleId},
      );

  Future<PkBattleRemote?> resumeBattle(
    String battleId, {
    required String roomId,
    String? alternateRoomId,
  }) =>
      _postPkAction(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        body: {'action': 'resume', 'battleId': battleId},
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
    // Üretim kontratı: POST /api/video-streams/pk — action + streamId + targetStreamId + duration (sn)
    if (normalized == 'create' && opponentStreamId != null) {
      final target = opponentStreamId.trim();
      final host = streamId.trim();
      if (target.isEmpty) {
        throw const ApiException('targetStreamId gerekli');
      }
      final durationSec =
          duration != null ? duration.clamp(60, 3600) : 180;
      try {
        final fieldBattle = await _liveFieldPk.pkAction(
          action: 'create',
          roomId: host,
          targetRoomId: target,
          durationSeconds: durationSec,
        );
        if (fieldBattle != null && fieldBattle.id.isNotEmpty) {
          final battle = _parseBattle({
            'id': fieldBattle.id,
            'status': fieldBattle.status ?? 'pending',
            'duration': fieldBattle.durationSeconds ?? durationSec,
            'score1': fieldBattle.room1Score,
            'score2': fieldBattle.room2Score,
            'liveStreamId': host,
            'opponentLiveStreamId': target,
          });
          if (battle != null) return battle;
        }
      } on ApiException catch (e) {
        PkEventLog.apiFailure(
          method: 'POST',
          url: ApiEndpoints.livePk,
          statusCode: e.statusCode,
          roomId: host,
          targetUserId: target,
          responseBody: e.message,
        );
        if (e.statusCode != 404 && e.statusCode != 405 && e.statusCode != 409) {
          rethrow;
        }
      }
      final bodies = livePkCreateRequestBodies(
        hostStreamId: host,
        targetStreamId: target,
        durationSeconds: durationSec,
      );
      ApiException? lastCreateError;
      for (final body in bodies) {
        try {
          final res = await _dio.safePost<dynamic>(
            ApiEndpoints.videoStreamPk,
            data: body,
          );
          final battle = _parseBattle(res.data);
          if (battle != null) return battle;
          final synthesized = _synthesizePendingBattle(res.data, roomId: host);
          if (synthesized != null) return synthesized;
        } on ApiException catch (e) {
          lastCreateError = e;
          PkEventLog.apiFailure(
            method: 'POST',
            url: ApiEndpoints.videoStreamPk,
            statusCode: e.statusCode,
            roomId: host,
            targetUserId: target,
            responseBody: e.message,
          );
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        }
      }
      for (final body in bodies) {
        try {
          final res = await _dio.safePost<dynamic>(
            ApiEndpoints.videoStreamPkBattle(host),
            data: body,
          );
          final battle = _parseBattle(res.data);
          if (battle != null) return battle;
        } on ApiException catch (e) {
          lastCreateError = e;
          PkEventLog.apiFailure(
            method: 'POST',
            url: ApiEndpoints.videoStreamPkBattle(host),
            statusCode: e.statusCode,
            roomId: host,
            targetUserId: target,
            responseBody: e.message,
          );
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        }
      }
      if (lastCreateError != null) throw lastCreateError;
      return null;
    }

    if (normalized != 'create') {
      final id = battleId?.trim() ?? '';
      final actionBody = <String, dynamic>{
        'action': action,
        if (id.isNotEmpty) ...{
          'battleId': id,
          'pkBattleId': id,
          'inviteId': id,
        },
      };
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.videoStreamPk,
          data: actionBody,
        );
        final battle = _parseBattle(res.data);
        if (battle != null) return battle;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamPkBattle(streamId),
        data: actionBody,
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
        query: {'direction': 'incoming'},
      );
      final map = _unwrap(res.data);
      final list = map?['items'] ??
          map?['invites'] ??
          map?['pending'] ??
          map?['data'] ??
          (res.data is List ? res.data : null) ??
          res.data;
      final out = <PkBattleRemote>[];
      for (final raw in asJsonList(list)) {
        if (raw is! Map) continue;
        final envelope = Map<String, dynamic>.from(raw);
        if (envelope['incoming'] == false) continue;
        final nested = envelope['battle'];
        final merged = PkBattleRemote.normalizeWireMap({
          if (nested is Map) ...Map<String, dynamic>.from(nested),
          ...envelope,
          'id': envelope['battleId'] ??
              (nested is Map ? asJsonMap(nested)['id'] : null) ??
              envelope['id'],
          'status': (nested is Map
                  ? asJsonMap(nested)['status']
                  : null) ??
              envelope['status'] ??
              'pending',
        });
        final battle =
            _parseBattle(merged) ?? PkBattleRemote.fromJson(merged);
        if (battle.effectiveId.isNotEmpty && battle.isPending) {
          out.add(battle);
        }
      }
      return out;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Canlı PK — çift tık beğeni / bonus puan (`POST /api/live/pk/score`).
  Future<void> postLivePkScore({
    required int amount,
    String? battleId,
    String? roomId,
    String? side,
  }) async {
    if (amount <= 0) return;
    await _liveFieldPk.updateScore(
      amount: amount,
      battleId: battleId,
      roomId: roomId,
      side: side,
    );
  }
}
