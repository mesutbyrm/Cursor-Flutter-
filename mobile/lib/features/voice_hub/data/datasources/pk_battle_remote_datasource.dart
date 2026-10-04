import 'package:dio/dio.dart';
import '../../../live/domain/pk/live_pk_server_clock.dart';
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
      // Ana site: `targetRoomId` + isteğe bağlı `guestUserId` (parity route.ts).
      // 400/422 ise yalnızca `targetRoomId` gövdesi denenir.
      {
        'action': 'create',
        'targetRoomId': opp,
        'guestUserId': guest,
        'duration': duration,
        'durationSec': duration,
      },
      primary,
    ];
  }

  return [primary];
}

/// Canlı PK create — `POST /api/video-streams/pk` (üretim: action + streamId + targetStreamId).
List<Map<String, dynamic>> livePkCreateRequestBodies({
  required String hostStreamId,
  required String targetStreamId,
  required int durationSeconds,
}) {
  final host = hostStreamId.trim();
  final target = targetStreamId.trim();
  final duration = durationSeconds.clamp(60, 3600);

  return [
    {
      'action': 'create',
      'streamId': host,
      'targetStreamId': target,
      'duration': duration,
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
    'targetStreamId': target,
    'opponentStreamId': target,
    'duration': duration,
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

Map<String, dynamic> _pkBattleJsonWithEnvelope(
  Map<String, dynamic> envelope,
  Map<String, dynamic> battleJson,
) {
  final merged = Map<String, dynamic>.from(battleJson);
  final sn = envelope['serverNow']?.toString();
  if (sn != null && sn.isNotEmpty && (merged['serverNow']?.toString().isEmpty ?? true)) {
    merged['serverNow'] = sn;
  }
  for (final key in ['participants', 'pkParticipants', 'user1', 'user2']) {
    if (!merged.containsKey(key) && envelope.containsKey(key)) {
      merged[key] = envelope[key];
    }
  }
  return merged;
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
    final battle = PkBattleRemote.fromJson(
      _pkBattleJsonWithEnvelope(map, Map<String, dynamic>.from(raw)),
    );
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
    return PkBattleRemote.fromJson(
      _pkBattleJsonWithEnvelope(map, {
        ...map,
        'id': id,
        'status': status ?? map['status'] ?? 'pending',
      }),
    );
  }
  return null;
}

class PkBattleRemoteDataSource {
  PkBattleRemoteDataSource(this._dio);

  final Dio _dio;

  List<PkBattleRemote>? _myInvitesCache;
  DateTime? _myInvitesCachedAt;
  static const _myInvitesCacheTtl = Duration(seconds: 8);

  final Map<String, _PkBattlePollCacheEntry> _roomBattleCache = {};
  final Map<String, _PkBattlePollCacheEntry> _streamBattleLiteCache = {};
  static const _roomBattleCacheTtl = Duration(seconds: 6);
  static const _streamBattleLiteCacheTtl = Duration(seconds: 6);

  /// Davet kabul/red/create sonrası — paylaşımlı poll önbelleğini sıfırla.
  void invalidateMyInvitesCache() {
    _myInvitesCache = null;
    _myInvitesCachedAt = null;
  }

  /// PK poll yedek REST (oda/yayın battle + davet listesi).
  void invalidatePkPollCaches() {
    invalidateMyInvitesCache();
    _roomBattleCache.clear();
    _streamBattleLiteCache.clear();
  }

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
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${roomId.trim()}|${alternateRoomId?.trim() ?? ''}';
    if (!forceRefresh) {
      final hit = _roomBattleCache[cacheKey];
      if (hit != null &&
          DateTime.now().difference(hit.at) < _roomBattleCacheTtl) {
        return hit.battle;
      }
    }
    for (final key in _roomKeyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomPk(key));
        if (res.data == null) {
          _roomBattleCache[cacheKey] =
              _PkBattlePollCacheEntry(null, DateTime.now());
          return null;
        }
        final battle = _parseBattle(res.data);
        if (battle != null && !battle.isEnded) {
          _roomBattleCache[cacheKey] =
              _PkBattlePollCacheEntry(battle, DateTime.now());
          return battle;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    _roomBattleCache[cacheKey] = _PkBattlePollCacheEntry(null, DateTime.now());
    return null;
  }

  /// [finalizeExpired]: davet poll için `false` — 3 istek yerine hafif okuma.
  /// `/api/live/pk` alanları + kanonik `/api/video-streams/pk` yanıtı birleşimi.
  Map<String, dynamic> _streamBattleInput({
    required String id,
    required String fieldId,
    required String fieldStatus,
    required int fieldDuration,
    required int fieldScore1,
    required int fieldScore2,
    Map<String, dynamic>? canon,
  }) {
    final input = <String, dynamic>{
      'id': fieldId,
      'status': fieldStatus,
      'duration': fieldDuration,
      'score1': fieldScore1,
      'score2': fieldScore2,
      'liveStreamId': id,
    };
    final c = canon;
    if (c == null || c['id']?.toString() != fieldId) return input;
    input['battleType'] = 'live_stream';
    for (final k in const [
      'status',
      'score1',
      'score2',
      'endsAt',
      'endTime',
      'startedAt',
      'endedAt',
      'serverNow',
      'winnerId',
      'user1',
      'user2',
      'duration',
    ]) {
      final v = c[k];
      if (v != null && '$v'.trim().isNotEmpty) input[k] = v;
    }
    // Taraf kimliği: stream1 = meydan okuyan (sol), stream2 = rakip (sağ).
    final s1 = c['stream1Id']?.toString().trim() ?? '';
    final s2 = c['stream2Id']?.toString().trim() ?? '';
    if (s1.isNotEmpty) input['liveStreamId'] = s1;
    if (s2.isNotEmpty) input['opponentLiveStreamId'] = s2;
    return input;
  }

  Future<PkBattleRemote?> fetchStreamBattle(
    String streamId, {
    bool finalizeExpired = true,
    bool forceRefresh = false,
  }) async {
    final id = streamId.trim();
    if (id.isEmpty) return null;
    if (!finalizeExpired && !forceRefresh) {
      final hit = _streamBattleLiteCache[id];
      if (hit != null &&
          DateTime.now().difference(hit.at) < _streamBattleLiteCacheTtl) {
        return hit.battle;
      }
    }
    // `GET /api/live/pk` ve `/pk-battle` süresi dolan aktif PK'yı kapatmaz;
    // yalnızca `GET /api/video-streams/pk` `finalizeExpiredActivePKs` çalıştırır.
    // Bu uç aynı zamanda KANONİK durumdur: `endsAt`, `serverNow`, `winnerId`,
    // `stream1Id/stream2Id`, `user1/user2` — eskiden yanıtı atılıyor, sayaç/kazanan/
    // taraf bilgisi eksik kalıyordu.
    Map<String, dynamic>? canon;
    if (finalizeExpired) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.videoStreamPk,
          query: {'streamId': id},
          forceRefresh: true,
        );
        final d = res.data;
        if (d is Map) {
          final m = asJsonMap(d);
          if ((m['id']?.toString() ?? '').isNotEmpty) canon = m;
        }
      } catch (_) {}
      livePkServerClock.observeIso(canon?['serverNow']?.toString());
    }
    try {
      final field = await _liveFieldPk.fetchPk(id);
      if (field != null && field.id.isNotEmpty) {
        final battle = _parseBattle(
          _streamBattleInput(
            id: id,
            fieldId: field.id,
            fieldStatus: field.status ?? '',
            fieldDuration: field.durationSeconds ?? 180,
            fieldScore1: field.room1Score ?? 0,
            fieldScore2: field.room2Score ?? 0,
            canon: canon,
          ),
        );
        if (battle != null) {
          if (!finalizeExpired) {
            _streamBattleLiteCache[id] =
                _PkBattlePollCacheEntry(battle, DateTime.now());
          }
          return battle;
        }
      }
    } catch (_) {}
    if (canon != null) {
      final battle = _parseBattle(
        _streamBattleInput(
          id: id,
          fieldId: canon['id'].toString(),
          fieldStatus: canon['status']?.toString() ?? '',
          fieldDuration: 180,
          fieldScore1: 0,
          fieldScore2: 0,
          canon: canon,
        ),
      );
      if (battle != null) return battle;
    }
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.videoStreamPkBattle(id));
    final parsed = _parseBattle(res.data);
    if (!finalizeExpired) {
      _streamBattleLiteCache[id] =
          _PkBattlePollCacheEntry(parsed, DateTime.now());
    }
    return parsed;
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
    // Üretim (parity 2026-09): yalnız POST /api/chat/rooms/{roomId}/pk + action body.
    // …/pk/{id}/respond üretimde yok — 404 gecikmesi kaldırıldı.
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
      final fallback = await _respondInviteViaLivePk(
        inviteId: inviteId,
        action: action,
        primaryError: e,
      );
      if (fallback != null) return fallback;
      rethrow;
    }
    throw ApiException('PK daveti yanıtlanamadı ($action)');
  }

  /// BÖLÜM 22 / PK_ENTEGRASYON — birleşik `POST /api/live/pk` accept/reject yedeği.
  Future<PkBattleRemote?> _respondInviteViaLivePk({
    required String inviteId,
    required String action,
    required ApiException primaryError,
  }) async {
    final code = primaryError.statusCode ?? 0;
    if (code != 404 && code != 405) return null;
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.livePk,
        data: {
          'action': action,
          'battleId': inviteId,
          'pkBattleId': inviteId,
          'matchId': inviteId,
        },
      );
      return _parseBattle(res.data);
    } on ApiException {
      return null;
    }
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
      final bodies = livePkCreateRequestBodies(
        hostStreamId: host,
        targetStreamId: target,
        durationSeconds: durationSec,
      );
      ApiException? lastCreateError;
      for (final body in bodies) {
        for (final path in [
          ApiEndpoints.videoStreamPk,
          ApiEndpoints.videoStreamPkBattle(host),
        ]) {
          try {
            final res = await _dio.safePost<dynamic>(path, data: body);
            final battle = _parseBattle(res.data);
            if (battle != null) return battle;
            final synthesized = _synthesizePendingBattle(res.data, roomId: host);
            if (synthesized != null) return synthesized;
          } on ApiException catch (e) {
            lastCreateError = e;
            PkEventLog.apiFailure(
              method: 'POST',
              url: path,
              statusCode: e.statusCode,
              roomId: host,
              targetUserId: target,
              responseBody: e.message,
            );
            if (e.statusCode == 400 || e.statusCode == 422) break;
            if (e.statusCode == 404 || e.statusCode == 405) continue;
            rethrow;
          }
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
  Future<List<PkBattleRemote>> fetchMyInvites({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _myInvitesCache != null &&
        _myInvitesCachedAt != null &&
        DateTime.now().difference(_myInvitesCachedAt!) < _myInvitesCacheTtl) {
      return List<PkBattleRemote>.from(_myInvitesCache!);
    }
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.pkMeInvites,
        forceRefresh: true,
        query: {'direction': 'incoming'},
      );
      final map = _unwrap(res.data);
      final top = res.data is Map ? asJsonMap(res.data) : null;
      final list = map?['items'] ??
          map?['invites'] ??
          map?['pending'] ??
          (top?['data'] is List ? top!['data'] : null) ??
          map?['data'] ??
          (res.data is List ? res.data : null) ??
          res.data;
      final out = <PkBattleRemote>[];
      for (final raw in asJsonList(list)) {
        final envelope = asJsonMap(raw);
        if (envelope.isEmpty) continue;
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
      _myInvitesCache = out;
      _myInvitesCachedAt = DateTime.now();
      return out;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

}

class _PkBattlePollCacheEntry {
  const _PkBattlePollCacheEntry(this.battle, this.at);

  final PkBattleRemote? battle;
  final DateTime at;
}
