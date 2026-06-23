import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/psychic_award_entity.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_gift_entity.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_review_entity.dart';
import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import '../../domain/repositories/live_psychics_repository.dart';
import '../models/psychic_model.dart';

/// Canlı falcı API — üretim uçları (JWT Bearer), backend değiştirilmez.
class LivePsychicsRemoteDataSource {
  LivePsychicsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PsychicEntity>> fetchPsychics({
    int page = 1,
    int limit = 20,
    bool? onlineOnly,
    String? specialty,
    String? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (onlineOnly == true) params['online'] = 'true';
    if (specialty != null && specialty.trim().isNotEmpty) {
      params['specialty'] = specialty.trim();
    }
    if (sort != null && sort.trim().isNotEmpty) {
      params['sort'] = sort.trim();
    }
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellers,
        query: params,
      );
      final items = PsychicModel.itemsFromBody(
        res.data,
        keys: const ['tellers', 'items', 'data', 'results'],
      );
      if (items.isNotEmpty) {
        return items
            .map(PsychicModel.psychicFromJson)
            .where((p) => p.id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.socialFortuneTellers);
      final items = PsychicModel.itemsFromBody(res.data);
      return items
          .map(PsychicModel.psychicFromJson)
          .where((p) => p.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// `userId` (auth) ile eşleşen falcı — liste sayfalama; **authUser.id ile GET by id yapılmaz**.
  Future<PsychicEntity?> findTellerByAuthUserId(String authUserId) async {
    final uid = authUserId.trim();
    if (uid.isEmpty) return null;
    for (var page = 1; page <= 10; page++) {
      final batch = await fetchPsychics(page: page, limit: 50);
      if (batch.isEmpty) break;
      for (final t in batch) {
        if (t.userId?.trim() == uid && t.isUsable) return t;
      }
      if (batch.length < 50) break;
    }
    return null;
  }

  Future<PsychicEntity?> fetchPsychic(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTeller(key));
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final teller = data['teller'] ?? data['fortuneTeller'] ?? data;
        return PsychicModel.psychicFromJson(teller);
      }
    } catch (_) {}
    final list = await fetchPsychics();
    for (final p in list) {
      if (p.id == key) return p;
    }
    return null;
  }

  Future<PsychicEntity?> fetchMyProfile() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerMyProfile);
      return PsychicModel.psychicFromMyProfileBody(res.data);
    } catch (_) {
      return null;
    }
  }

  /// Teşhis — ham `my-profile` JSON (log için).
  Future<dynamic> fetchMyProfileRaw() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerMyProfile);
      return res.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<bool> setOnline({required bool online}) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerToggleOnline,
        data: {'isOnline': online},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchOnlineStatus() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerToggleOnline);
      if (res.data is Map) return asJsonMap(res.data);
    } catch (_) {}
    return null;
  }

  Future<PsychicEntity?> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerApply,
        data: {
          'displayName': displayName.trim(),
          'specialties': specialties,
          if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
          if (applicationNote != null && applicationNote.trim().isNotEmpty)
            'applicationNote': applicationNote.trim(),
        },
      );
      if (res.data is! Map) {
        throw ApiException('Başvuru yanıtı geçersiz');
      }
      final map = asJsonMap(res.data);
      if (map['success'] == false) {
        throw ApiException(
          map['error']?.toString() ??
              map['message']?.toString() ??
              'Başvuru gönderilemedi',
        );
      }
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final teller = data['teller'] ?? data;
      return PsychicModel.psychicFromJson(teller);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiException.userMessage(e));
    }
  }

  Future<List<PsychicReviewEntity>> fetchReviews(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerReviews(key));
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final items = PsychicModel.itemsFromBody(
          map,
          keys: const ['reviews', 'items', 'data'],
        );
        return items
            .map(PsychicModel.reviewFromJson)
            .where((r) => r.id.isNotEmpty)
            .toList(growable: false);
      }
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) => PsychicModel.reviewFromJson(e))
            .where((r) => r.id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  Future<List<PsychicAwardEntity>> fetchAwards(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerAwards(key));
      final items = PsychicModel.itemsFromBody(res.data);
      return items
          .map((m) => PsychicAwardEntity(
                id: m['id']?.toString() ?? '',
                tellerId: key,
                awardType: m['awardType']?.toString() ?? '',
                title: m['title']?.toString() ?? '',
                startDate: PsychicModel.parseDate(m['startDate']),
                endDate: PsychicModel.parseDate(m['endDate']),
                createdAt: PsychicModel.parseDate(m['createdAt']),
              ))
          .where((a) => a.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PsychicGiftEntity>> fetchGifts(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTellerGifts(key));
      final items = PsychicModel.itemsFromBody(res.data);
      return items
          .map((m) => PsychicGiftEntity(
                senderId: m['senderId']?.toString() ??
                    m['userId']?.toString() ??
                    '',
                senderName: m['senderName']?.toString() ??
                    m['name']?.toString() ??
                    'Kullanıcı',
                giftCount: asInt(m['giftCount'] ?? m['count']),
                senderImage:
                    m['senderImage']?.toString() ?? m['image']?.toString(),
                totalJeton: asInt(m['totalJeton'] ?? m['jeton'] ?? m['amount']),
              ))
          .where((g) => g.senderId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> submitReview({
    required String sessionId,
    required String tellerId,
    required int rating,
    String? comment,
  }) async {
    final payload = {
      'sessionId': sessionId.trim(),
      'tellerId': tellerId.trim(),
      'rating': rating.clamp(1, 5),
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.tellerReviews, data: payload);
      return true;
    } catch (_) {}
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerReviews(tellerId.trim()),
        data: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<PsychicEntity>> fetchFavoritePsychics() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.favoriteTellers);
      final items = PsychicModel.itemsFromBody(
        res.data,
        keys: const [
          'favorites',
          'tellers',
          'items',
          'data',
          'results',
        ],
      );
      if (items.isNotEmpty) {
        return items
            .map(PsychicModel.psychicFromJson)
            .where((p) => p.id.isNotEmpty)
            .toList(growable: false);
      }
      final body = res.data;
      if (body is List) {
        return body
            .whereType<Map>()
            .map((e) {
              final map = Map<String, dynamic>.from(e);
              final nested = map['teller'] ?? map['fortuneTeller'];
              if (nested is Map) {
                return PsychicModel.psychicFromJson(nested);
              }
              return PsychicModel.psychicFromJson(map);
            })
            .where((p) => p.id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> toggleFavoritePsychic(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return false;
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.favoriteTellers,
        data: {'tellerId': key},
      );
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final favored = pick(map, [
          'favorited',
          'isFavorite',
          'isFavourite',
          'favorite',
          'added',
        ]);
        if (favored is bool) return favored;
        if (favored != null) {
          final s = favored.toString().toLowerCase();
          if (s == 'true' || s == '1') return true;
          if (s == 'false' || s == '0') return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PsychicSessionCreateResult?> createSession({
    required String tellerId,
    String? tellerUserId,
    required int durationMinutes,
    required String fortuneType,
    bool staffExempt = false,
    String? clientName,
  }) async {
    final id = tellerId.trim();
    if (id.isEmpty) return null;
    final tellerUid = tellerUserId?.trim() ?? '';
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerSession,
        data: {
          'tellerId': id,
          if (tellerUid.isNotEmpty) 'tellerUserId': tellerUid,
          if (tellerUid.isNotEmpty) 'anchorUserId': tellerUid,
          'fortuneType': fortuneType.trim().isNotEmpty ? fortuneType.trim() : 'general',
          'duration': durationMinutes,
          'durationMinutes': durationMinutes,
          if (staffExempt) 'staffExempt': true,
          if (clientName != null && clientName.trim().isNotEmpty)
            'clientName': clientName.trim(),
        },
      );
      return PsychicModel.sessionCreateFromJson(res.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiException.userMessage(e));
    }
  }

  Future<PsychicSessionStatusResult?> fetchSessionStatus(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return null;
    for (final path in [
      ApiEndpoints.fortuneTellerSessionQuery(key),
      ApiEndpoints.fortuneTellerSessionStatus(key),
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final body = res.data;
        if (body is! Map) continue;
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final sessionMap =
            data['session'] is Map ? asJsonMap(data['session']) : data;
        final status = PsychicModel.sessionStatusFromJson(data, sessionMap);
        if (status != null) return status;
      } catch (_) {}
    }
    final room = await fetchRoom(key);
    if (room == null) return null;
    return PsychicSessionStatusResult(
      sessionId: room.sessionId,
      status: room.status,
      isClient: room.isClient,
      trtcRoomId: room.roomId,
      durationMinutes: room.maxMinutes,
    );
  }

  Future<List<PsychicSessionStatusResult>> fetchActiveSessions() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userActiveSessions);
      final list = PsychicModel.itemsFromBody(
        res.data,
        keys: const ['sessions', 'items', 'data'],
      );
      return list
          .map((m) => PsychicModel.sessionStatusFromJson(m, m))
          .whereType<PsychicSessionStatusResult>()
          .where((s) => s.status.isActive)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PsychicRequestEntity>> fetchIncomingRequests({
    String? currentUserId,
    String? tellerProfileId,
  }) async {
    final merged = <PsychicRequestEntity>[];
    final seen = <String>{};
    for (final path in [
      ApiEndpoints.fortuneTellerIncomingSessions,
      ApiEndpoints.fortuneTellerSessionsWithStatus('pending'),
      ApiEndpoints.liveFalPending,
      ApiEndpoints.fortuneTellerSessions,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = PsychicModel.itemsFromBody(
          res.data,
          keys: const ['sessions', 'pending', 'requests', 'items', 'data'],
        );
        for (final raw in items) {
          final req = PsychicModel.requestFromJson(raw);
          if (req.sessionId.isEmpty || !req.isPending) continue;
          if (seen.add(req.sessionId)) merged.add(req);
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
      } catch (_) {}
    }
    final uid = currentUserId?.trim() ?? '';
    final profileId = tellerProfileId?.trim() ?? '';
    return merged.where((r) {
      if (uid.isEmpty) return true;
      if (r.clientId == uid) return false;
      if (r.tellerUserId == uid || r.tellerId == uid) return true;
      if (profileId.isNotEmpty && r.tellerId == profileId) return true;
      // Gelen istek uçlarında teller alanı boş gelebilir; falcıya yönlendirilmiş kayıtları düşürme.
      if (profileId.isNotEmpty || _isFortuneTellerContext(uid, profileId)) {
        return r.clientId.isEmpty || r.clientId != uid;
      }
      return r.clientId.isNotEmpty && r.clientId != uid;
    }).toList(growable: false);
  }

  bool _isFortuneTellerContext(String uid, String profileId) =>
      uid.isNotEmpty || profileId.isNotEmpty;

  Future<PsychicRespondResult> respondSession(
    String sessionId, {
    required String action,
  }) async {
    final key = sessionId.trim();
    final act = action.trim().toLowerCase();
    if (key.isEmpty) return const PsychicRespondResult(success: false);
    Map<String, dynamic>? body;
    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.fortuneTellerSessionPatch(key),
        data: {'action': act},
      );
      if (res.data is Map) body = asJsonMap(res.data);
    } catch (_) {}
    body ??= await _respondLegacy(key, act);
    if (body == null) return const PsychicRespondResult(success: false);
    final roomId = PsychicModel.str(body, ['roomId', 'trtcRoomId', 'room_id']) ??
        PsychicModel.str(asJsonMap(body['session'] ?? {}), ['roomId', 'id']);
    return PsychicRespondResult(
      success: body['success'] == true || roomId != null || body.isNotEmpty,
      sessionId: PsychicModel.str(body, ['sessionId', 'id']) ?? key,
      roomId: roomId,
    );
  }

  Future<Map<String, dynamic>?> _respondLegacy(String sessionId, String action) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerSessionRespond(sessionId),
        data: {'action': action},
      );
      if (res.data is Map) return asJsonMap(res.data);
    } catch (_) {}
    return null;
  }

  Future<bool> endSession(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return false;
    for (final action in const ['cancel', 'end', 'leave']) {
      final result = await roomAction(key, action);
      if (result != null) return true;
    }
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.fortuneTellerSessionPatch(key),
        data: const {'action': 'cancel'},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// WebRTC sinyal temizliği — TRTC birincil; `/api/room/signal` yedek kanal.
  Future<void> clearRoomSignals(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return;
    try {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.liveFortuneRoomSignalQuery(key),
      );
    } catch (_) {}
  }

  Future<PsychicRoomEntity?> fetchRoom(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.liveFortuneRoom(key));
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      return PsychicModel.roomFromJson(data, fallbackId: key);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) async {
    final key = sessionId.trim();
    final act = action.trim().toLowerCase();
    if (key.isEmpty || act.isEmpty) return null;
    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.liveFortuneRoom(key),
        data: {
          'action': act,
          if (extra != null) ...extra,
        },
      );
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        return map['data'] is Map ? asJsonMap(map['data']) : map;
      }
      return <String, dynamic>{};
    } catch (_) {
      return null;
    }
  }

  Future<List<PsychicChatMessage>> fetchMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty) return const [];
    try {
      final path = afterIso != null && afterIso.isNotEmpty
          ? '${ApiEndpoints.liveFortuneRoomMessages(key)}?after=${Uri.encodeComponent(afterIso)}'
          : ApiEndpoints.liveFortuneRoomMessages(key);
      final res = await _dio.safeGet<dynamic>(path);
      final items = PsychicModel.itemsFromBody(
        res.data,
        keys: const ['messages', 'items', 'data'],
      );
      return items
          .map((m) => PsychicModel.chatFromJson(m, myUserId: myUserId))
          .where((m) => m.text.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> sendMessage(String sessionId, String text) async {
    final key = sessionId.trim();
    final message = text.trim();
    if (key.isEmpty || message.isEmpty) return false;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.liveFortuneRoomMessages(key),
        data: {'message': message},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> extendSession({
    required String sessionId,
    required int minutes,
    required int totalJeton,
  }) async {
    final result = await roomAction(
      sessionId,
      'extend',
      extra: {'minutes': minutes},
    );
    return result != null;
  }

  Future<bool> tellerAddTime({
    required String sessionId,
    required int minutes,
  }) async {
    final result = await roomAction(
      sessionId,
      'teller_add_time',
      extra: {'minutes': minutes},
    );
    return result != null;
  }

  Future<bool> sendTip({
    required String sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.tellerGifts,
        data: {
          'sessionId': sessionId.trim(),
          'amount': amount,
          if (tellerId != null) 'tellerId': tellerId,
          if (tellerUserId != null) 'tellerUserId': tellerUserId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
